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

-- Function to find different expression parts on a character
local function findExpressionParts(character, expressionType)
	local head = character:FindFirstChild("head") or character:FindFirstChild("Head")
	if not head then return nil end

	if expressionType == "laugh" then
		local expressionsFolder = head:FindFirstChild("expressions")
		if expressionsFolder then
			local laughExpression = expressionsFolder:FindFirstChild("laugh")
			if laughExpression then
				return {
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
				return {
					type = "tired",
					part = tiredEyesFolder:FindFirstChild("tired")
				}
			end
		end
	elseif expressionType == "exeEyes" then
		local normalEyes = head:FindFirstChild("eyes")
		local exeEyes = head:FindFirstChild("exeEye")

		if normalEyes and exeEyes then
			return {
				type = "exeEyes",
				normalEyes = normalEyes,
				exeEyes = exeEyes,
				normalPupil1 = normalEyes:FindFirstChild("pupil1"),
				normalPupil2 = normalEyes:FindFirstChild("pupil2"),
				exeEye1 = exeEyes:FindFirstChild("exeEye1"),
				exeEye2 = exeEyes:FindFirstChild("exeEye2"),
				whiteEye = normalEyes:FindFirstChild("eyes")
			}
		end
	end

	return nil
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
		-- Show EXE eyes
		if parts.normalPupil1 and parts.normalPupil2 then
			parts.normalPupil1.Transparency = 1
			parts.normalPupil2.Transparency = 1
		end

		if parts.exeEye1 and parts.exeEye2 then
			parts.exeEye1.Transparency = 0
			parts.exeEye2.Transparency = 0
		end

		if parts.whiteEye then
			parts.whiteEye.Color = Color3.fromRGB(0, 0, 0)
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
		-- Hide EXE eyes, restore normal eyes
		if parts.normalPupil1 and parts.normalPupil2 then
			parts.normalPupil1.Transparency = 0
			parts.normalPupil2.Transparency = 0
		end

		if parts.exeEye1 and parts.exeEye2 then
			parts.exeEye1.Transparency = 1
			parts.exeEye2.Transparency = 1
		end

		if parts.whiteEye then
			parts.whiteEye.Color = Color3.fromRGB(255, 255, 255)
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

-- Listen for expression events from the server
expressionEvent.OnClientEvent:Connect(function(userId, expressionType, showState)
	-- Find the player by userId
	local targetPlayer = Players:GetPlayerByUserId(userId)
	if not targetPlayer or not targetPlayer.Character then return end

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

print("Expression Client Script loaded!")