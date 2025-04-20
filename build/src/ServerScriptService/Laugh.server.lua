local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create or get the remote events for laugh/taunt
local tauntEvent = ReplicatedStorage:FindFirstChild("TauntEvent")
if not tauntEvent then
	tauntEvent = Instance.new("RemoteEvent")
	tauntEvent.Name = "TauntEvent"
	tauntEvent.Parent = ReplicatedStorage
end

-- Create remote event for expression broadcasting
local expressionEvent = ReplicatedStorage:FindFirstChild("ExpressionEvent")
if not expressionEvent then
	expressionEvent = Instance.new("RemoteEvent")
	expressionEvent.Name = "ExpressionEvent"
	expressionEvent.Parent = ReplicatedStorage
end

-- Character expression durations (match exactly with local scripts)
local EXPRESSION_DURATIONS = {
	laugh = 1.8,
	tired = 3.3,
	exeEyes = 2.0
}

-- Find existing laugh sound on a character
local function findLaughSound(character)
	if not character then return nil end

	-- Check for laugh sound in entire character
	local laughSound = character:FindFirstChild("Laugh")

	-- If not in character directly, check in HumanoidRootPart (preferred location)
	if not laughSound then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			laughSound = rootPart:FindFirstChild("Laugh")
		end
	end

	return laughSound
end

-- Detect character expression type using character model name for better accuracy
local function detectExpressionType(character)
	-- First check character name to determine most accurate expression type
	local characterName = character.Name

	-- Specific character type detection (add more character names as needed)
	if characterName:find("Exe") or characterName:find("EXE") then
		-- Default to exeEyes for EXE characters
		return "exeEyes"
	end

	-- Fallback to structure detection
	local head = character:FindFirstChild("head") or character:FindFirstChild("Head")
	if not head then return nil end

	-- Check for laugh expression
	local expressionsFolder = head:FindFirstChild("expressions")
	if expressionsFolder then
		if expressionsFolder:FindFirstChild("laugh") then
			return "laugh"
		end

		if expressionsFolder:FindFirstChild("tired_eyes") then
			return "tired"
		end
	end

	-- Check for EXE eyes
	if head:FindFirstChild("eyes") and head:FindFirstChild("exeEye") then
		return "exeEyes"
	end

	return "laugh" -- Default to laugh type if can't detect
end

-- Active laugh records with timestamps and cleanup info
local activeLaughs = {}

-- Handle laugh events from clients
tauntEvent.OnServerEvent:Connect(function(player, expressionTypeFromClient)
	local character = player.Character
	if not character then return end

	local userId = player.UserId

	-- Find the laugh sound
	local laughSound = findLaughSound(character)
	if laughSound and not laughSound.IsPlaying then
		laughSound:Play()
	end

	-- Detect expression type - prioritize client info if provided
	local expressionType = expressionTypeFromClient or detectExpressionType(character)
	if not expressionType then
		expressionType = "laugh" -- Default if detection fails
	end

	-- Get animation duration for this expression type
	local animDuration = EXPRESSION_DURATIONS[expressionType] or 2.5

	-- Stop any existing laugh for this player
	if activeLaughs[userId] and activeLaughs[userId].cleanupConnection then
		activeLaughs[userId].cleanupConnection:Disconnect()
	end

	-- Store that this player is laughing
	activeLaughs[userId] = {
		startTime = tick(),
		duration = animDuration,
		expressionType = expressionType
	}

	-- Broadcast to all other players to show the expression IMMEDIATELY
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			expressionEvent:FireClient(otherPlayer, userId, expressionType, true)
		end
	end

	-- Schedule hiding the expression after animation completes
	activeLaughs[userId].cleanupConnection = task.delay(animDuration, function()
		-- Tell all clients to hide the expression
		for _, otherPlayer in pairs(Players:GetPlayers()) do
			if otherPlayer ~= player then
				expressionEvent:FireClient(otherPlayer, userId, expressionType, false)
			end
		end

		-- Clean up after broadcasting hide event
		if activeLaughs[userId] then
			activeLaughs[userId] = nil
		end
	end)
end)

-- Handle player leaving or character reset
local function cleanupPlayerExpression(player)
	local userId = player.UserId

	-- If this player was laughing, clean up
	if activeLaughs[userId] then
		-- Disconnect cleanup timer if it exists
		if activeLaughs[userId].cleanupConnection then
			activeLaughs[userId].cleanupConnection:Disconnect()
		end

		-- Tell all clients to hide expressions for this player
		for _, otherPlayer in pairs(Players:GetPlayers()) do
			if otherPlayer ~= player then
				expressionEvent:FireClient(otherPlayer, userId, "any", false)
			end
		end

		-- Remove from active laughs
		activeLaughs[userId] = nil
	end
end

-- Handle character changes
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- Clean up when character changes
		cleanupPlayerExpression(player)
	end)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(cleanupPlayerExpression)

print("Improved Laugh Server Script loaded with better synchronization!")