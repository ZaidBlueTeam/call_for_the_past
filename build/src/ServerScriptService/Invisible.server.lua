-- Invisibility System - SERVER SCRIPT (FIXED)
-- Place this script in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvent for communication
local invisibilityEvent = ReplicatedStorage:FindFirstChild("InvisibilityEvent")
if not invisibilityEvent then
	invisibilityEvent = Instance.new("RemoteEvent")
	invisibilityEvent.Name = "InvisibilityEvent"
	invisibilityEvent.Parent = ReplicatedStorage
end

-- Track which players are currently invisible and their original transparency values
local invisiblePlayers = {}
local playerTransparencies = {}

-- Get path string for an instance
local function getInstancePath(instance)
	if not instance or not instance:IsDescendantOf(game) then return nil end

	local path = instance.Name
	local current = instance.Parent

	while current and current ~= game do
		path = current.Name .. "." .. path
		current = current.Parent
	end

	return path
end

-- Save original transparencies for a character
local function saveCharacterTransparencies(character)
	if not character then return {} end

	local transparencies = {}

	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") or 
			part:IsA("Decal") or part:IsA("Texture") or 
			part:IsA("Shirt") or part:IsA("Pants") or 
			part:IsA("ShirtGraphic") then

			local path = getInstancePath(part)
			if path then
				-- Store current transparency value
				transparencies[path] = part.Transparency

				-- Also store as an attribute on the part itself for redundancy
				part:SetAttribute("OriginalTransparency", part.Transparency)
			end
		end
	end

	return transparencies
end

-- Function to directly set character visibility on the server
local function setCharacterVisibility(character, isInvisible, transparencyData)
	if not character then return end

	local partsChanged = 0

	-- Apply visibility changes to all parts
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") or 
			part:IsA("Decal") or part:IsA("Texture") or 
			part:IsA("Shirt") or part:IsA("Pants") or 
			part:IsA("ShirtGraphic") then

			-- Get the part's path
			local path = getInstancePath(part)

			if isInvisible then
				-- Going invisible - make all parts transparent
				part.Transparency = 1
				partsChanged = partsChanged + 1
			else
				-- Becoming visible - restore original transparency
				if transparencyData and path and transparencyData[path] ~= nil then
					-- Use provided transparency data if available
					part.Transparency = transparencyData[path]
				elseif part:GetAttribute("OriginalTransparency") ~= nil then
					-- Fallback to stored attribute
					part.Transparency = part:GetAttribute("OriginalTransparency")
					part:SetAttribute("OriginalTransparency", nil)
				else
					-- Last resort default
					part.Transparency = 0
				end
				partsChanged = partsChanged + 1
			end
		end
	end

	print("Character visibility changed on server: " .. (isInvisible and "invisible" or "visible") .. " (" .. partsChanged .. " parts)")
end

-- Function to make a player invincible
local function setPlayerInvincibility(player, makeInvincible)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Set invincible state
	if makeInvincible then
		-- Store original properties
		humanoid:SetAttribute("OriginalMaxHealth", humanoid.MaxHealth)
		humanoid:SetAttribute("OriginalHealth", humanoid.Health)

		-- Make invincible
		humanoid.MaxHealth = math.huge
		humanoid.Health = math.huge

		-- Prevent damage
		character:SetAttribute("Invincible", true)
	else
		-- Restore original properties if available
		local originalMaxHealth = humanoid:GetAttribute("OriginalMaxHealth")
		local originalHealth = humanoid:GetAttribute("OriginalHealth")

		if originalMaxHealth then
			humanoid.MaxHealth = originalMaxHealth
			humanoid:SetAttribute("OriginalMaxHealth", nil)
		end

		if originalHealth then
			humanoid.Health = originalHealth
			humanoid:SetAttribute("OriginalHealth", nil)
		end

		-- Allow damage again
		character:SetAttribute("Invincible", nil)
	end

	-- Disable stun effects when invisible
	for _, child in pairs(character:GetChildren()) do
		if child.Name == "StunScript" or child.Name:find("Stun") then
			child.Disabled = makeInvincible
		end
	end

	-- Disable attack animations when invisible (usually in Tools)
	for _, tool in pairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Enabled = not makeInvincible
		end
	end

	print(player.Name .. " invincibility set to: " .. tostring(makeInvincible))
end

-- Function to toggle a player's invisibility
local function togglePlayerInvisibility(player, isInvisible, transparencyData)
	local character = player.Character
	if not character then return end

	-- Update tracking and store/restore transparency data
	if isInvisible then
		invisiblePlayers[player.UserId] = true

		-- If transparency data was provided by client, save it
		if transparencyData then
			playerTransparencies[player.UserId] = transparencyData
		else
			-- Otherwise generate our own by scanning the character
			playerTransparencies[player.UserId] = saveCharacterTransparencies(character)
		end

		-- Make character invisible directly on the server
		setCharacterVisibility(character, true)

		-- Set invincibility
		setPlayerInvincibility(player, true)
	else
		local savedTransparencies = playerTransparencies[player.UserId]

		-- Make character visible directly on the server using saved transparencies
		setCharacterVisibility(character, false, transparencyData or savedTransparencies)

		-- Remove invincibility
		setPlayerInvincibility(player, false)

		-- Clean up tracking data
		invisiblePlayers[player.UserId] = nil
		playerTransparencies[player.UserId] = nil
	end

	-- Tell humanoid about invisible state for other systems
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:SetAttribute("Invisible", isInvisible)
	end

	-- Broadcast to all other clients to ensure everyone sees the same thing
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			-- Send the transparency data along with the visibility state
			-- Determine what data to send
			local dataToSend = nil
			if not isInvisible then
				dataToSend = transparencyData or playerTransparencies[player.UserId]
			end

			invisibilityEvent:FireClient(
				otherPlayer, 
				player.UserId, 
				isInvisible, 
				dataToSend
			)
		end
	end
end

-- Handle client invisibility events
invisibilityEvent.OnServerEvent:Connect(function(player, isInvisible, transparencyData, playSound)
	togglePlayerInvisibility(player, isInvisible, transparencyData)

	-- Play appear sound for everyone if requested
	if playSound and player.Character then
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			-- Create a server-side sound that everyone can hear
			local sound = Instance.new("Sound", rootPart)
			sound.SoundId = "rbxassetid://4844057081" 
			sound.Volume = 1
			sound.MaxDistance = 50
			sound.RollOffMode = Enum.RollOffMode.Linear
			sound:Play()

			-- Clean up sound after playing
			sound.Ended:Connect(function()
				sound:Destroy()
			end)
		end
	end
end)

-- Handle player removal/leaving
Players.PlayerRemoving:Connect(function(player)
	-- Clean up if a player leaves while invisible
	if invisiblePlayers[player.UserId] then
		invisiblePlayers[player.UserId] = nil
		playerTransparencies[player.UserId] = nil
	end
end)

-- Handle character added (in case player respawns while invisible)
local function onCharacterAdded(player, character)
	task.wait(1) -- Short delay to allow client script to initialize

	-- If player was invisible before respawn, reapply it
	if invisiblePlayers[player.UserId] then
		-- Generate new transparency data for this character
		playerTransparencies[player.UserId] = saveCharacterTransparencies(character)

		setPlayerInvincibility(player, true)
		setCharacterVisibility(character, true)

		-- Set humanoid attribute for consistency
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:SetAttribute("Invisible", true)
		end

		-- Notify all clients that this player should remain invisible
		for _, otherPlayer in pairs(Players:GetPlayers()) do
			if otherPlayer ~= player then
				invisibilityEvent:FireClient(otherPlayer, player.UserId, true)
			end
		end

		-- Also notify the player themselves to reapply client-side invisibility
		task.delay(0.5, function() -- Small delay to ensure character is fully loaded
			invisibilityEvent:FireClient(player, player.UserId, true)
		end)
	end
end

-- Listen for character added events
for _, player in pairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)

-- Handle damage protection for invisible players
local function setupDamageProtection()
	-- Method 1: Monitor parts that might cause damage
	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") and 
			(descendant.Name:find("Hit") or descendant.Name:find("Damage") or descendant.Name:find("Attack")) then

			descendant.Touched:Connect(function(hit)
				local character = hit:FindFirstAncestorOfClass("Model")
				if character then
					local player = Players:GetPlayerFromCharacter(character)
					if player and invisiblePlayers[player.UserId] then
						-- Prevent damage to invisible players
						return
					end
				end
			end)
		end
	end)

	-- Method 2: Monitor damage events using a remote event (common in many games)
	for _, instance in pairs(ReplicatedStorage:GetDescendants()) do
		if instance:IsA("RemoteEvent") and
			(instance.Name:find("Damage") or instance.Name:find("Hit") or instance.Name:find("Attack")) then

			instance.OnServerEvent:Connect(function(player, target, ...)
				-- Check if target is a player and is invisible
				if typeof(target) == "Instance" then
					local targetPlayer = Players:GetPlayerFromCharacter(target)
					if targetPlayer and invisiblePlayers[targetPlayer.UserId] then
						-- Cancel damage event
						return
					end
				elseif typeof(target) == "number" then
					-- Some games use player UserIds
					if invisiblePlayers[target] then
						return
					end
				end

				-- If we get here, allow the original damage to proceed
			end)
		end
	end
end

-- Set up damage protection
setupDamageProtection()

print("Invisibility Server Script loaded! Now handling player invisibility with improved state tracking.")