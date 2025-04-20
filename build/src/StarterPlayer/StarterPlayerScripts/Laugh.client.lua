local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Get the expression event
local expressionEvent = ReplicatedStorage:FindFirstChild("ExpressionEvent")
if not expressionEvent then
	expressionEvent = Instance.new("RemoteEvent")
	expressionEvent.Name = "ExpressionEvent"
	expressionEvent.Parent = ReplicatedStorage
end

-- Cache for character parts to improve performance
local characterCache = {}

-- Function to find different expression parts on a character
local function findExpressionParts(character, expressionType)
	-- Return cached results if available
	local characterId = character:GetFullName()
	if characterCache[characterId] and characterCache[characterId][expressionType] then
		return characterCache[characterId][expressionType]
	end

	-- Initialize character cache if not exists
	if not characterCache[characterId] then
		characterCache[characterId] = {}
	end

	local head = character:FindFirstChild("head") or character:FindFirstChild("Head")
	if not head then return nil end

	local result = nil

	if expressionType == "laugh" then
		local expressionsFolder = head:FindFirstChild("expressions")
		if expressionsFolder then
			local laughExpression = expressionsFolder:FindFirstChild("laugh")
			if laughExpression then
				result = {
					type = "laugh",
					folder = laughExpression
				}
			end
		end
	elseif expressionType == "tired" then
		local expressionsFolder = head:FindFirstChild("expressions")
		if expressionsFolder then
			local tiredEyesFolder = expressionsFolder:FindFirstChild("tired_eyes")
			if tiredEyesFolder then
				result = {
					type = "tired",
					part = tiredEyesFolder:FindFirstChild("tired")
				}
			end
		end
	elseif expressionType == "exeEyes" then
		-- More thorough search for EXE eyes components
		local normalEyes = head:FindFirstChild("eyes")
		local exeEyes = head:FindFirstChild("exeEye")

		-- Debug
		if not normalEyes or not exeEyes then
			-- Try searching deeper
			for _, child in pairs(head:GetChildren()) do
				if child.Name == "eyes" then
					normalEyes = child
				elseif child.Name == "exeEye" then
					exeEyes = child
				end
			end
		end

		if normalEyes or exeEyes then
			-- Create a result even if we only found some parts
			result = {
				type = "exeEyes",
				normalEyes = normalEyes,
				exeEyes = exeEyes
			}

			-- Add normal pupils if found
			if normalEyes then
				result.normalPupil1 = normalEyes:FindFirstChild("pupil1")
				result.normalPupil2 = normalEyes:FindFirstChild("pupil2")
				result.whiteEye = normalEyes:FindFirstChild("eyes")

				-- Try deeper search if not found directly
				if not result.normalPupil1 then
					for _, child in pairs(normalEyes:GetChildren()) do
						if child.Name == "pupil1" then
							result.normalPupil1 = child
						elseif child.Name == "pupil2" then
							result.normalPupil2 = child
						elseif child.Name == "eyes" then
							result.whiteEye = child
						end
					end
				end
			end

			-- Add exe pupils if found
			if exeEyes then
				result.exeEye1 = exeEyes:FindFirstChild("exeEye1")
				result.exeEye2 = exeEyes:FindFirstChild("exeEye2")

				-- Try deeper search if not found directly
				if not result.exeEye1 then
					for _, child in pairs(exeEyes:GetChildren()) do
						if child.Name == "exeEye1" then
							result.exeEye1 = child
						elseif child.Name == "exeEye2" then
							result.exeEye2 = child
						end
					end
				end
			end
		end
	end

	-- Cache the result
	characterCache[characterId][expressionType] = result

	return result
end

-- Function to show expression on another player's character
local function showExpression(character, expressionType)
	if not character then return end

	local parts = findExpressionParts(character, expressionType)
	if not parts then return end

	if parts.type == "laugh" then
		-- Show laugh expression
		for _, part in pairs(parts.folder:GetChildren()) do
			if part:IsA("BasePart") then
				part.Transparency = 0
				part.CanCollide = false
			end
		end
	elseif parts.type == "tired" and parts.part then
		-- Show tired expression
		parts.part.Transparency = 0
		parts.part.CanCollide = false
	elseif parts.type == "exeEyes" then
		-- Show EXE eyes - more robust implementation

		-- First, try to find parts if they weren't found earlier
		if not parts.normalPupil1 or not parts.normalPupil2 or not parts.exeEye1 or not parts.exeEye2 then
			-- Try to re-discover parts
			parts = findExpressionParts(character, "exeEyes")
			if not parts then return end
		end

		-- Hide normal pupils if they exist
		if parts.normalPupil1 then
			parts.normalPupil1.Transparency = 1
		end

		if parts.normalPupil2 then
			parts.normalPupil2.Transparency = 1
		end

		-- Show EXE pupils if they exist
		if parts.exeEye1 then
			parts.exeEye1.Transparency = 0
		end

		if parts.exeEye2 then
			parts.exeEye2.Transparency = 0
		end

		-- Change eye color if possible
		if parts.whiteEye then
			parts.whiteEye.Color = Color3.fromRGB(0, 0, 0)
		elseif parts.normalEyes then
			-- Try to find the main eye part by other means
			for _, part in pairs(parts.normalEyes:GetChildren()) do
				if part:IsA("BasePart") and not part.Name:find("pupil") then
					part.Color = Color3.fromRGB(0, 0, 0)
				end
			end
		end

		-- Alternate approach: just try to make all EXE parts visible
		if parts.exeEyes then
			for _, part in pairs(parts.exeEyes:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 0
				end
			end
		end
	end
end

-- Function to hide expression on another player's character
local function hideExpression(character, expressionType)
	if not character then return end

	local parts = findExpressionParts(character, expressionType)
	if not parts then return end

	if parts.type == "laugh" then
		-- Hide laugh expression
		for _, part in pairs(parts.folder:GetChildren()) do
			if part:IsA("BasePart") then
				part.Transparency = 1
				part.CanCollide = false
			end
		end
	elseif parts.type == "tired" and parts.part then
		-- Hide tired expression
		parts.part.Transparency = 1
		parts.part.CanCollide = false
	elseif parts.type == "exeEyes" then
		-- Hide EXE eyes, restore normal eyes - more robust implementation

		-- First, try to find parts if they weren't found earlier
		if not parts.normalPupil1 or not parts.normalPupil2 or not parts.exeEye1 or not parts.exeEye2 then
			-- Try to re-discover parts
			parts = findExpressionParts(character, "exeEyes")
			if not parts then return end
		end

		-- Show normal pupils if they exist
		if parts.normalPupil1 then
			parts.normalPupil1.Transparency = 0
		end

		if parts.normalPupil2 then
			parts.normalPupil2.Transparency = 0
		end

		-- Hide EXE pupils if they exist
		if parts.exeEye1 then
			parts.exeEye1.Transparency = 1
		end

		if parts.exeEye2 then
			parts.exeEye2.Transparency = 1
		end

		-- Restore eye color if possible
		if parts.whiteEye then
			parts.whiteEye.Color = Color3.fromRGB(255, 255, 255)
		elseif parts.normalEyes then
			-- Try to find the main eye part by other means
			for _, part in pairs(parts.normalEyes:GetChildren()) do
				if part:IsA("BasePart") and not part.Name:find("pupil") then
					part.Color = Color3.fromRGB(255, 255, 255)
				end
			end
		end

		-- Alternate approach: hide all EXE parts
		if parts.exeEyes then
			for _, part in pairs(parts.exeEyes:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 1
				end
			end
		end
	end
end

-- Hide all expressions on a character (used when type is unknown)
local function hideAllExpressions(character)
	if not character then return end

	-- Try hiding all known expression types
	hideExpression(character, "laugh")
	hideExpression(character, "tired")
	hideExpression(character, "exeEyes")
end

-- Clear cache when character changes
local function clearCharacterCache(character)
	if character then
		local characterId = character:GetFullName()
		characterCache[characterId] = nil
	end
end

-- Listen for expression events from the server
expressionEvent.OnClientEvent:Connect(function(userId, expressionType, showState)
	-- Don't process our own expressions (the laugh script already handles those)
	if userId == player.UserId then return end

	-- Find the player by userId
	local targetPlayer = Players:GetPlayerByUserId(userId)
	if not targetPlayer or not targetPlayer.Character then return end

	-- Handle the expression
	if showState then
		-- Show the expression
		showExpression(targetPlayer.Character, expressionType)
	else
		-- Hide the expression
		if expressionType == "any" then
			hideAllExpressions(targetPlayer.Character)
		else
			hideExpression(targetPlayer.Character, expressionType)
		end
	end
end)

-- Handle character changes for all players
local function setupCharacterRemoving(otherPlayer)
	otherPlayer.CharacterRemoving:Connect(function(character)
		clearCharacterCache(character)
	end)
end

-- Set up for existing players
for _, otherPlayer in pairs(Players:GetPlayers()) do
	setupCharacterRemoving(otherPlayer)
end

-- Set up for new players
Players.PlayerAdded:Connect(setupCharacterRemoving)

print("ExpressionViewer script loaded! You will now see EXE expressions.")