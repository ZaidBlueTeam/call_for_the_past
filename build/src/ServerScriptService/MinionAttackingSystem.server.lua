-- Minion Attack Server Script (No Chase Music)
-- Place this in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Get or create RemoteEvents
local MinionAttackEvent = ReplicatedStorage:FindFirstChild("MinionAttackEvent")
if not MinionAttackEvent then
	MinionAttackEvent = Instance.new("RemoteEvent")
	MinionAttackEvent.Name = "MinionAttackEvent"
	MinionAttackEvent.Parent = ReplicatedStorage
end

local MinionResetEvent = ReplicatedStorage:FindFirstChild("MinionResetEvent")
if not MinionResetEvent then
	MinionResetEvent = Instance.new("RemoteEvent")
	MinionResetEvent.Name = "MinionResetEvent"
	MinionResetEvent.Parent = ReplicatedStorage
end

-- Configuration
local HITBOX_SIZE = Vector3.new(5, 5, 7)           -- Size of attack hitbox
local HITBOX_OFFSET = Vector3.new(0, 0, 3)         -- Forward offset for hitbox
local HITBOX_LIFETIME = 0.5                        -- How long hitbox stays active
local SURVIVOR_SPEED_BOOST = 15                    -- Speed boost after getting hit
local SURVIVOR_SPEED_THRESHOLD = 39                -- Speed must be above this for boost
local SURVIVOR_IFRAME_DURATION = 0.5               -- Invincibility duration
local MINION_SPEED_BOOST = 3                       -- Speed boost on hit
local MINION_SPEED_DURATION = 0.8                  -- Duration of speed boost
local DEFAULT_DAMAGE = 20                          -- Default damage if not specified
local DEBUG_MODE = true                            -- Enable debug output

-- Tables for tracking state
local activeHitboxes = {}          -- Track active attack hitboxes
local invinciblePlayers = {}       -- Track players with invincibility
local hasAttacked = {}             -- Track which players have attacked

-- Debug print function
local function debugPrint(message)
	if DEBUG_MODE then
		print("[MINION ATTACK] " .. message)
	end
end

-- Get minion damage value (from character or default)
local function getMinionDamage(char)
	local damageValue = char:FindFirstChild("Damage")
	if damageValue and damageValue:IsA("NumberValue") then
		return damageValue.Value
	end
	return DEFAULT_DAMAGE
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

	debugPrint("Cleared invincibility on " .. player.Name)
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
		MinionAttackEvent:FireClient(player, "AttackReset")
	end

	debugPrint("Cleaned up attack for " .. (player and player.Name or "unknown player"))
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
		MinionResetEvent:FireClient(player, "ResetAttack") -- Tell client to reset attack state
		return
	end

	-- Check if player is dead
	if humanoid.Health <= 0 then
		debugPrint(player.Name .. " is dead - can't attack")
		MinionResetEvent:FireClient(player, "ResetAttack") -- Tell client to reset attack state
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
		local damage = getMinionDamage(char)

		-- Create hitbox for the attack
		local hitbox = Instance.new("Part")
		hitbox.Name = "MinionAttackHitbox_" .. hitboxId
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

			-- Check for hits with all players
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

						-- Play hit sound for the attacker
						MinionAttackEvent:FireClient(player, "Hit")

						-- Trigger hit reaction for the survivor (similar to main attack system)
						-- Find the SurvivorHitEvent to notify survivor they got hit
						local SurvivorHitEvent = ReplicatedStorage:FindFirstChild("SurvivorHitEvent")
						if SurvivorHitEvent then
							-- We pass nil as the second parameter to indicate no chase music should play
							SurvivorHitEvent:FireClient(targetPlayer, player.UserId, nil)
							debugPrint("Triggered hit reaction for " .. targetPlayer.Name)
						end

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

						-- Apply Minion Speed Boost
						local originalSpeed = humanoid.WalkSpeed
						humanoid.WalkSpeed = originalSpeed + MINION_SPEED_BOOST

						task.delay(MINION_SPEED_DURATION, function()
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

			-- If nothing was hit, play swing sound
			if not hasHit then
				MinionAttackEvent:FireClient(player, "Swing")
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
		MinionAttackEvent:FireClient(player, "AttackReset")
	end
end

-- Listen for attack events from clients
MinionAttackEvent.OnServerEvent:Connect(performAttack)

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
end)

-- Force clear invincibility on ALL players periodically (safety check)
task.spawn(function()
	while true do
		task.wait(3) -- Check every 3 seconds

		for _, player in pairs(Players:GetPlayers()) do
			if player.Team and player.Team.Name == "Survivor" and player.Character then
				-- Force check for stuck invincibility
				if player.Character:GetAttribute("Invincible") and not invinciblePlayers[player.UserId] then
					debugPrint("Found stuck invincibility on " .. player.Name .. " - force clearing")
					clearInvincibility(player)
				end
			end
		end
	end
end)

print("[MINION ATTACK] Server script loaded! Minions can now attack without chase music functionality.")