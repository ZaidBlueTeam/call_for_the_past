-- FIXED Attack Server Script
-- Resolves issue where attacks stop working after first hit

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- Get or create RemoteEvents
local AttackEvent = ReplicatedStorage:FindFirstChild("AttackEvent")
if not AttackEvent then
	AttackEvent = Instance.new("RemoteEvent")
	AttackEvent.Name = "AttackEvent"
	AttackEvent.Parent = ReplicatedStorage
end

local SurvivorHitEvent = ReplicatedStorage:FindFirstChild("SurvivorHitEvent")
if not SurvivorHitEvent then
	SurvivorHitEvent = Instance.new("RemoteEvent")
	SurvivorHitEvent.Name = "SurvivorHitEvent"
	SurvivorHitEvent.Parent = ReplicatedStorage
end

-- Create reset event for attack system
local AttackResetEvent = ReplicatedStorage:FindFirstChild("AttackResetEvent")
if not AttackResetEvent then
	AttackResetEvent = Instance.new("RemoteEvent")
	AttackResetEvent.Name = "AttackResetEvent"
	AttackResetEvent.Parent = ReplicatedStorage
end

-- Configuration
local HITBOX_SIZE = Vector3.new(5, 5, 7)           -- Size of attack hitbox
local HITBOX_OFFSET = Vector3.new(0, 0, 3)         -- Forward offset for hitbox
local HITBOX_LIFETIME = 0.5                        -- How long hitbox stays active
local SURVIVOR_SPEED_BOOST = 15                    -- Speed boost after getting hit
local SURVIVOR_SPEED_THRESHOLD = 39                -- Speed must be above this for boost
local SURVIVOR_IFRAME_DURATION = 0.5               -- Invincibility duration (shorter is better)
local EXE_SPEED_BOOST = 3                          -- EXE speed boost on hit
local EXE_SPEED_DURATION = 0.8                     -- Duration of EXE speed boost
local DEFAULT_DAMAGE = 25                          -- Default damage if not specified
local NEAR_MISS_DISTANCE = 10                      -- Distance for near-miss detection
local CHASE_DETECTION_DISTANCE = 40                -- Distance to maintain chase music
local CHASE_CHECK_INTERVAL = 0.5                   -- How often to check chase distance (seconds)
local CHASE_MAX_DURATION = 30                      -- Maximum time chase music plays without re-triggering (seconds)
local DEBUG_MODE = true                            -- Enable debug output

-- Tables for tracking state
local activeHitboxes = {}          -- Track active attack hitboxes
local survivorsInChase = {}        -- Track which survivors are in chase
local invinciblePlayers = {}       -- Track players with invincibility
local attackCooldowns = {}         -- Track attack cooldowns
local exePlayers = {}              -- Track EXE players for easy access
local hasAttacked = {}             -- Track which players have attacked

-- Debug print function
local function debugPrint(message)
	if DEBUG_MODE then
		print("[ATTACK SYSTEM] " .. message)
	end
end

-- Get EXE damage value (from character or default)
local function getEXEDamage(char)
	local damageValue = char:FindFirstChild("Damage")
	if damageValue and damageValue:IsA("NumberValue") then
		return damageValue.Value
	end
	return DEFAULT_DAMAGE
end

-- Find chase music in EXE character
local function findChaseMusic(exeCharacter)
	-- Look for a sound named "Chase" in the character
	local chaseSound = exeCharacter:FindFirstChild("Chase")

	-- If not found directly, search deeper
	if not chaseSound then
		chaseSound = exeCharacter:FindFirstChild("Chase", true)
	end

	-- Return the sound ID if found, otherwise nil
	if chaseSound and chaseSound:IsA("Sound") then
		return chaseSound.SoundId
	else
		-- Fallback to a default chase music if none exists in character
		return "rbxassetid://1841667761" -- Default chase music
	end
end

-- Check if a player should still be in chase
local function shouldMaintainChase(survivorPlayer, exePlayer)
	-- Basic checks
	if not survivorPlayer or not survivorPlayer.Character or not exePlayer or not exePlayer.Character then
		return false
	end

	-- Check if survivor is dead
	local survivorHumanoid = survivorPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not survivorHumanoid or survivorHumanoid.Health <= 0 then
		debugPrint("Chase ended - survivor " .. survivorPlayer.Name .. " is dead")
		return false
	end

	-- Check if EXE is invisible, dead or stunned
	local exeChar = exePlayer.Character
	local exeHumanoid = exeChar:FindFirstChildOfClass("Humanoid")

	if not exeHumanoid or 
		exeHumanoid.Health <= 0 or 
		exeChar:GetAttribute("Invisible") or 
		exeChar:GetAttribute("Stunned") then
		debugPrint("Chase ended - EXE " .. exePlayer.Name .. " is dead/invisible/stunned")
		return false
	end

	-- Check team changes
	if not exePlayer.Team or exePlayer.Team.Name ~= "EXE" then
		debugPrint("Chase ended - " .. exePlayer.Name .. " is no longer on EXE team")
		return false
	end

	if not survivorPlayer.Team or survivorPlayer.Team.Name ~= "Survivor" then
		debugPrint("Chase ended - " .. survivorPlayer.Name .. " is no longer on Survivor team")
		return false
	end

	-- Check distance between players
	local survivorRoot = survivorPlayer.Character:FindFirstChild("HumanoidRootPart")
	local exeRoot = exePlayer.Character:FindFirstChild("HumanoidRootPart")

	if survivorRoot and exeRoot then
		local distance = (survivorRoot.Position - exeRoot.Position).Magnitude

		if distance > CHASE_DETECTION_DISTANCE then
			debugPrint("Chase ended - " .. survivorPlayer.Name .. " is too far from " .. exePlayer.Name)
			return false
		end
	end

	-- If we passed all checks, maintain the chase
	return true
end

-- CRUCIAL: Function to fully clear invincibility on a player
local function clearInvincibility(player)
	if not player or not player.Character then return end

	local char = player.Character
	local userId = player.UserId

	-- Remove any invincibility objects
	if char:FindFirstChild("TempInvincibility") then
		char.TempInvincibility:Destroy()
	end

	-- Explicitly set invincibility attribute to false
	char:SetAttribute("Invincible", false)

	-- Clear from tracking
	invinciblePlayers[userId] = nil

	-- Trigger reset event to client to ensure client-side handling
	AttackResetEvent:FireClient(player, "ClearInvincibility")

	-- Consider the player vulnerable immediately
	debugPrint("Cleared invincibility on " .. player.Name)
end

-- Forward declaration for stopChaseMusic
local stopChaseMusic

-- Start chase music for a player
local function startChaseMusic(survivorPlayer, exePlayer)
	if not survivorPlayer or not exePlayer or not survivorPlayer.Character or not exePlayer.Character then 
		return 
	end

	local survivorId = survivorPlayer.UserId
	local exeCharacter = exePlayer.Character

	-- Check if EXE is invisible, stunned, or dead
	if exeCharacter:GetAttribute("Invisible") or 
		exeCharacter:GetAttribute("Stunned") or
		not exeCharacter:FindFirstChildOfClass("Humanoid") or
		exeCharacter:FindFirstChildOfClass("Humanoid").Health <= 0 then
		return
	end

	-- Find the chase music
	local chaseMusicId = findChaseMusic(exeCharacter)

	-- If survivor is already in chase, don't restart the music
	if survivorsInChase[survivorId] then
		return
	end

	-- Mark survivor as in chase
	survivorsInChase[survivorId] = {
		exePlayer = exePlayer,
		chaseMusicId = chaseMusicId
	}

	-- Start chase music for both the survivor and the EXE player
	AttackEvent:FireClient(survivorPlayer, "StartChase", chaseMusicId)
	AttackEvent:FireClient(exePlayer, "StartChase", chaseMusicId)

	debugPrint("Started chase music for: " .. survivorPlayer.Name .. " chased by: " .. exePlayer.Name)
end

-- Stop chase music for a survivor
stopChaseMusic = function(survivorPlayer)
	if not survivorPlayer then return end

	local survivorId = survivorPlayer.UserId

	if survivorsInChase[survivorId] then
		local exePlayer = survivorsInChase[survivorId].exePlayer

		-- Stop chase music for both players
		AttackEvent:FireClient(survivorPlayer, "StopChase")

		if exePlayer and exePlayer.Parent then
			AttackEvent:FireClient(exePlayer, "StopChase")
		end

		-- Remove from tracking
		survivorsInChase[survivorId] = nil

		debugPrint("Stopped chase music for: " .. survivorPlayer.Name)
	end
end

-- Stop chase music for all survivors chased by a specific EXE
local function stopChaseMusicForExe(exePlayer)
	for survivorId, chaseInfo in pairs(survivorsInChase) do
		if chaseInfo.exePlayer == exePlayer then
			local survivorPlayer = Players:GetPlayerByUserId(survivorId)
			if survivorPlayer then
				stopChaseMusic(survivorPlayer)
			else
				survivorsInChase[survivorId] = nil
			end
		end
	end
end

-- Stop ALL chase music (for round reset)
local function stopAllChaseMusic()
	for survivorId, _ in pairs(survivorsInChase) do
		local survivorPlayer = Players:GetPlayerByUserId(survivorId)
		if survivorPlayer then
			stopChaseMusic(survivorPlayer)
		end
	end

	-- Clear the chase tracking table
	survivorsInChase = {}

	-- Also explicitly tell all players to stop chase music
	for _, player in pairs(Players:GetPlayers()) do
		AttackEvent:FireClient(player, "StopChase")
	end

	debugPrint("Stopped ALL chase music (round reset)")
end

-- Function to check if a player is a valid target
local function isValidTarget(player, targetPlayer)
	-- Check if target exists and is on Survivor team
	if not targetPlayer or 
		targetPlayer == player or 
		not targetPlayer.Team or 
		targetPlayer.Team.Name ~= "Survivor" or 
		not targetPlayer.Character then
		return false
	end

	-- Check if character is valid and not invincible
	local targetChar = targetPlayer.Character
	if not targetChar then return false end

	-- Check for invincibility in multiple ways
	if targetChar:GetAttribute("Invincible") or targetChar:FindFirstChild("TempInvincibility") then
		debugPrint(targetPlayer.Name .. " is invincible - can't hit")
		return false
	end

	-- Check if target is alive
	local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return false
	end

	return true
end

-- Check chase proximity and manage chase music
local function updateChaseMusicProximity()
	-- For each survivor in chase, check if they're still within range of their chaser
	for survivorId, chaseData in pairs(survivorsInChase) do
		local survivorPlayer = Players:GetPlayerByUserId(survivorId)
		local exePlayer = chaseData.exePlayer

		-- If either player is gone, stop the chase music
		if not survivorPlayer or not survivorPlayer.Character or 
			not exePlayer or not exePlayer.Character then
			if survivorPlayer then
				stopChaseMusic(survivorPlayer)
			else
				survivorsInChase[survivorId] = nil
			end
			continue
		end

		-- Check if the EXE is invisible, stunned, or dead
		local exeHumanoid = exePlayer.Character:FindFirstChildOfClass("Humanoid")
		if exePlayer.Character:GetAttribute("Invisible") or 
			exePlayer.Character:GetAttribute("Stunned") or
			(exeHumanoid and exeHumanoid.Health <= 0) then
			stopChaseMusic(survivorPlayer)
			continue
		end

		-- Check if the survivor died
		local survivorHumanoid = survivorPlayer.Character:FindFirstChildOfClass("Humanoid")
		if survivorHumanoid and survivorHumanoid.Health <= 0 then
			stopChaseMusic(survivorPlayer)
			continue
		end

		-- Check distance between survivor and EXE
		local survivorRoot = survivorPlayer.Character:FindFirstChild("HumanoidRootPart")
		local exeRoot = exePlayer.Character:FindFirstChild("HumanoidRootPart")

		if survivorRoot and exeRoot then
			local distance = (survivorRoot.Position - exeRoot.Position).Magnitude

			-- If too far apart, stop the chase music
			if distance > CHASE_DETECTION_DISTANCE then
				stopChaseMusic(survivorPlayer)
			end
		end
	end
end

-- CRITICAL: Function to clean up after attack
local function cleanupAttack(player, hitboxId)
	-- Clean up the specific hitbox
	if activeHitboxes[hitboxId] then
		local hitboxData = activeHitboxes[hitboxId]

		-- Disconnect any connections
		if hitboxData.connection then
			hitboxData.connection:Disconnect()
			hitboxData.connection = nil
		end

		-- Destroy any parts
		if hitboxData.part and hitboxData.part.Parent then
			hitboxData.part:Destroy()
		end

		-- Remove from tracking
		activeHitboxes[hitboxId] = nil
	end

	-- Remove from attack tracking (allow attacking again)
	if player and player.UserId then
		hasAttacked[player.UserId] = nil
	end

	-- Notify client that attack has been fully reset
	if player and player.Parent then
		AttackEvent:FireClient(player, "AttackReset")
	end

	debugPrint("Cleaned up attack for " .. (player and player.Name or "unknown player"))
end

-- Main attack function - creates and manages hitbox
local function performAttack(player, actionType)
	local char = player.Character
	if not char then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end

	-- Check if player is invisible or stunned
	if char:GetAttribute("Invisible") or char:GetAttribute("Stunned") then
		debugPrint(player.Name .. " can't attack while invisible or stunned")
		AttackEvent:FireClient(player, "AttackReset") -- Tell client to reset attack state
		return
	end

	-- Verify player is on EXE team
	if not player.Team or player.Team.Name ~= "EXE" then
		debugPrint(player.Name .. " is not on EXE team - can't attack")
		AttackEvent:FireClient(player, "AttackReset") -- Tell client to reset attack state
		return
	end

	-- Check if player is dead
	if humanoid.Health <= 0 then
		debugPrint(player.Name .. " is dead - can't attack")
		AttackEvent:FireClient(player, "AttackReset") -- Tell client to reset attack state
		return
	end

	-- Handle different action types
	if actionType == "Start" then
		-- Just acknowledge the start of attack
		-- We don't need to do anything else here
		return
	elseif actionType == "Release" then
		-- Track that this player has attacked to prevent simultaneous attacks
		local userId = player.UserId

		-- Check for cooldown or if already attacking
		if hasAttacked[userId] then
			debugPrint(player.Name .. " is already attacking - ignoring")
			return
		end

		-- Mark as attacking
		hasAttacked[userId] = true

		-- Create unique hitbox ID
		local hitboxId = player.UserId .. "_" .. tick()
		local damage = getEXEDamage(char)

		-- Create hitbox for the attack
		local hitbox = Instance.new("Part")
		hitbox.Name = "AttackHitbox_" .. hitboxId
		hitbox.Size = HITBOX_SIZE
		hitbox.Transparency = 1
		hitbox.CanCollide = false
		hitbox.Anchored = true
		hitbox.Parent = workspace

		-- Tag the hitbox with owner info
		local ownerTag = Instance.new("ObjectValue")
		ownerTag.Name = "Owner"
		ownerTag.Value = player
		ownerTag.Parent = hitbox

		-- Find chase music in advance
		local chaseMusicId = findChaseMusic(char)

		-- Track this hitbox
		activeHitboxes[hitboxId] = {
			part = hitbox,
			owner = player,
			hasHit = false,
			targets = {}, -- Track which players have been hit
			connection = nil -- Will store the update connection
		}

		-- Hitbox update connection
		local updateConnection = nil
		updateConnection = RunService.Heartbeat:Connect(function()
			if not char or not char:FindFirstChild("HumanoidRootPart") or not activeHitboxes[hitboxId] then
				-- Clean up if character is gone
				if updateConnection then 
					updateConnection:Disconnect() 
					updateConnection = nil
				end

				cleanupAttack(player, hitboxId)
				return
			end

			-- Update hitbox position to follow player
			local forward = root.CFrame.LookVector
			local offset = forward * HITBOX_OFFSET.Z
			hitbox.CFrame = CFrame.new(root.Position + offset)

			-- Check for hits with all players (priority system for multiple hits)
			for _, targetPlayer in pairs(Players:GetPlayers()) do
				-- Skip if already hit this target or if target is invalid
				if activeHitboxes[hitboxId].targets[targetPlayer.UserId] or not isValidTarget(player, targetPlayer) then
					continue
				end

				local targetChar = targetPlayer.Character
				local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
				local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")

				if targetRoot and targetHumanoid then
					-- Check if in hitbox range (improved collision detection)
					local distance = (targetRoot.Position - hitbox.Position).Magnitude
					local hitboxRadius = hitbox.Size.X/2

					if distance <= hitboxRadius + 2 then
						-- Mark as hit to prevent multiple hits
						activeHitboxes[hitboxId].targets[targetPlayer.UserId] = true
						activeHitboxes[hitboxId].hasHit = true

						debugPrint("HIT DETECTED: " .. player.Name .. " hit " .. targetPlayer.Name)

						-- First force-clear any existing invincibility
						clearInvincibility(targetPlayer)

						-- Apply damage
						targetHumanoid:TakeDamage(damage)

						-- Now set NEW invincibility with BOTH object and attribute
						local invincibilityMarker = Instance.new("BoolValue")
						invincibilityMarker.Name = "TempInvincibility"
						invincibilityMarker.Value = true
						invincibilityMarker.Parent = targetChar

						targetChar:SetAttribute("Invincible", true)
						invinciblePlayers[targetPlayer.UserId] = true

						-- Notify the survivor they got hit AND pass the EXE ID for chase music
						SurvivorHitEvent:FireClient(targetPlayer, player.UserId, chaseMusicId)

						-- Play hit sound for the attacker
						AttackEvent:FireClient(player, "Hit", chaseMusicId)

						-- Start chase music for the hit survivor
						startChaseMusic(targetPlayer, player)

						-- Apply Survivor Speed Boost if above threshold
						if targetHumanoid.WalkSpeed >= SURVIVOR_SPEED_THRESHOLD then
							local originalSpeed = targetHumanoid.WalkSpeed
							targetHumanoid.WalkSpeed = originalSpeed + SURVIVOR_SPEED_BOOST

							task.delay(3, function()
								if targetHumanoid and targetHumanoid.Parent then
									targetHumanoid.WalkSpeed = originalSpeed
								end
							end)
						end

						-- Apply EXE Speed Boost
						local originalSpeed = humanoid.WalkSpeed
						humanoid.WalkSpeed = originalSpeed + EXE_SPEED_BOOST

						task.delay(EXE_SPEED_DURATION, function()
							if humanoid and humanoid.Parent then
								humanoid.WalkSpeed = originalSpeed
							end
						end)

						-- TRIPLE REDUNDANCY for removing invincibility
						-- 1. Normal timer
						task.delay(SURVIVOR_IFRAME_DURATION, function()
							clearInvincibility(targetPlayer)
						end)

						-- 2. Backup timer with slightly longer duration
						task.delay(SURVIVOR_IFRAME_DURATION + 0.1, function()
							clearInvincibility(targetPlayer)
						end)

						-- 3. Force cleanup after a fixed time regardless
						task.delay(1.5, function() 
							clearInvincibility(targetPlayer)
						end)
					end
				end
			end
		end)

		-- Store connection in the hitbox data for cleanup
		activeHitboxes[hitboxId].connection = updateConnection

		-- COMPLETE RESET: Clean up hitbox after lifetime
		task.delay(HITBOX_LIFETIME, function()
			local hasHit = activeHitboxes[hitboxId] and activeHitboxes[hitboxId].hasHit

			-- Clean up the attack
			cleanupAttack(player, hitboxId)

			-- Check for near-miss AFTER cleaning up the attack (only if nothing was hit)
			if not hasHit then
				for _, nearbyPlayer in pairs(Players:GetPlayers()) do
					if nearbyPlayer ~= player and 
						nearbyPlayer.Team and nearbyPlayer.Team.Name == "Survivor" and
						nearbyPlayer.Character and 
						nearbyPlayer.Character:FindFirstChild("HumanoidRootPart") then

						local distance = (nearbyPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
						if distance <= NEAR_MISS_DISTANCE then
							-- Near-miss, trigger chase music
							startChaseMusic(nearbyPlayer, player)
						end
					end
				end

				-- Play swing sound
				AttackEvent:FireClient(player, "Swing")
			end

			-- Explicitly allow the player to attack again after a very short delay
			task.delay(0.1, function()
				hasAttacked[player.UserId] = nil
			end)
		end)
	elseif actionType == "RequestReset" then
		-- Handle reset request from client
		for id, hitboxData in pairs(activeHitboxes) do
			if hitboxData.owner == player then
				cleanupAttack(player, id)
			end
		end

		-- Force reset attack state
		hasAttacked[player.UserId] = nil
		AttackEvent:FireClient(player, "AttackReset")
	end
end

-- Monitor for EXE deaths
local function monitorExeDeaths()
	local function setupDeathMonitoring(player, char)
		if not player or not char then return end

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		-- Monitor death events
		humanoid.Died:Connect(function()
			debugPrint(player.Name .. " (EXE) died - stopping chase music")
			stopChaseMusicForExe(player)

			-- Also ensure all attacks are cleaned up
			for id, hitboxData in pairs(activeHitboxes) do
				if hitboxData.owner == player then
					cleanupAttack(player, id)
				end
			end
		end)
	end

	-- Set up for all players when they become EXE
	local function handleTeamChange(player)
		if player.Team and player.Team.Name == "EXE" then
			if player.Character then
				setupDeathMonitoring(player, player.Character)
			end

			player.CharacterAdded:Connect(function(char)
				setupDeathMonitoring(player, char)
			end)
		end
	end

	-- Set up for existing players
	for _, player in pairs(Players:GetPlayers()) do
		handleTeamChange(player)

		player:GetPropertyChangedSignal("Team"):Connect(function()
			handleTeamChange(player)
		end)
	end

	-- Set up for future players
	Players.PlayerAdded:Connect(function(player)
		player:GetPropertyChangedSignal("Team"):Connect(function()
			handleTeamChange(player)
		end)
	end)
end

-- Force clear invincibility on ALL players periodically
local function globalInvincibilityClearCheck()
	task.wait(2) -- Wait initial time

	while true do
		for _, player in pairs(Players:GetPlayers()) do
			if player.Team and player.Team.Name == "Survivor" and player.Character then
				-- Force check for stuck invincibility
				if player.Character:GetAttribute("Invincible") and not invinciblePlayers[player.UserId] then
					debugPrint("Found stuck invincibility on " .. player.Name .. " - force clearing")
					clearInvincibility(player)
				end
			end
		end

		task.wait(3) -- Check every 3 seconds
	end
end

-- Handle round reset (check for RoundStats event)
local function setupRoundResetDetection()
	local roundStatsEvent = ReplicatedStorage:FindFirstChild("RoundStats")
	if not roundStatsEvent then
		roundStatsEvent = Instance.new("RemoteEvent")
		roundStatsEvent.Name = "RoundStats"
		roundStatsEvent.Parent = ReplicatedStorage
	end

	-- We'll monitor the RoundStats event for messages that indicate round reset
	local function isRoundResetMessage(message)
		if typeof(message) ~= "table" or not message.status then return false end

		local statusText = message.status
		return statusText:find("won the round") or 
			statusText:find("Round resetting") or
			statusText:find("Not enough players") or
			statusText:find("reset")
	end

	-- Hook into the existing RemoteEvent that fires round state
	roundStatsEvent.OnServerEvent:Connect(function(player, message)
		-- We're just observing, not modifying behavior
	end)

	-- Also set up a separate function that actively checks for round events
	local function hookRoundEvents()
		local mt = getmetatable(roundStatsEvent)
		if not mt then return end

		local originalFireAllClients = mt.FireAllClients
		if type(originalFireAllClients) ~= "function" then return end

		mt.FireAllClients = function(self, message, ...)
			if isRoundResetMessage(message) then
				debugPrint("Round reset detected! Stopping all chase music")
				stopAllChaseMusic()

				-- Also clean up all attacks and invincibilities
				for id, hitboxData in pairs(activeHitboxes) do
					cleanupAttack(hitboxData.owner, id)
				end

				for userId, _ in pairs(invinciblePlayers) do
					local player = Players:GetPlayerByUserId(userId)
					if player then
						clearInvincibility(player)
					end
				end
			end

			return originalFireAllClients(self, message, ...)
		end
	end

	task.spawn(hookRoundEvents)
end

-- Listen for attack events from clients
AttackEvent.OnServerEvent:Connect(performAttack)

-- Handle player removal
Players.PlayerRemoving:Connect(function(player)
	-- Clean up any active hitboxes belonging to this player
	for id, hitboxData in pairs(activeHitboxes) do
		if hitboxData.owner == player then
			cleanupAttack(player, id)
		end
	end

	-- Remove from attack tracking
	hasAttacked[player.UserId] = nil

	-- Remove from invincibility tracking
	invinciblePlayers[player.UserId] = nil

	-- Clean up any chase music involving this player
	if player.Team and player.Team.Name == "EXE" then
		stopChaseMusicForExe(player)
	end

	-- If player was a survivor in chase, clean up
	if survivorsInChase[player.UserId] then
		local exePlayer = survivorsInChase[player.UserId].exePlayer
		if exePlayer then
			AttackEvent:FireClient(exePlayer, "StopChase")
		end
		survivorsInChase[player.UserId] = nil
	end
end)

-- Start proximity check for chase music
task.spawn(function()
	while true do
		updateChaseMusicProximity()
		task.wait(1) -- Check every second
	end
end)

-- Start monitoring for EXE deaths
monitorExeDeaths()

-- Start global invincibility clear check
task.spawn(globalInvincibilityClearCheck)

-- Setup round reset detection
setupRoundResetDetection()

-- Clear invincibility on all players when script loads
for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		clearInvincibility(player)
	end
end

-- When round system script runs its round logic, hook into it
local roundSystemScript = nil
for _, script in pairs(game.ServerScriptService:GetDescendants()) do
	if script:IsA("Script") and script.Name:lower():find("round") then
		roundSystemScript = script
		break
	end
end

if roundSystemScript then
	debugPrint("Found round system script: " .. roundSystemScript:GetFullName())
	-- We'll add an ObjectValue to monitor this script
	local monitor = Instance.new("ObjectValue")
	monitor.Name = "AttackSystemMonitor"
	monitor.Parent = roundSystemScript
end

print("[ATTACK SYSTEM] Fixed Attack Server Script loaded!")