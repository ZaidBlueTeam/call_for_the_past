local bouncePad = script.Parent
local soundCooldown = 1
local canSound = true

-- Configuration
local BASE_FORCE = 60       -- Base force multiplier (was fixed at 150 before)
local MIN_VELOCITY = 60     -- Minimum velocity for short jumps
local MAX_FORCE = 60        -- Maximum force for very long jumps
local VELOCITY_DURATION = 0.2 -- How long the velocity lasts (shorter = faster arrival)

-- Team-based cooldown durations (in seconds)
local teamCooldowns = {
	["EXE"] = 2,     -- EXE team has a shorter cooldown of 2 seconds
	["Survivor"] = 5 -- Survivor team has a longer cooldown of 5 seconds
}
local defaultCooldown = 1 -- Default cooldown for any other teams

-- Table to track individual player cooldowns
local playerCooldowns = {}

-- Animation Setup
local springAnim = Instance.new("Animation")
springAnim.AnimationId = "rbxassetid://78879009149730" -- Replace with your animation ID

-- Function to get the appropriate cooldown duration based on team
local function getCooldownDuration(player)
	if player and player.Team then
		local teamName = player.Team.Name
		return teamCooldowns[teamName] or defaultCooldown
	end
	return defaultCooldown
end

-- Function to check if a player is on cooldown
local function isOnCooldown(player)
	if not player then return false end

	local userId = player.UserId
	return playerCooldowns[userId] ~= nil
end

-- Function to put a player on cooldown
local function putOnCooldown(player)
	if not player then return end

	local userId = player.UserId
	local cooldownTime = getCooldownDuration(player)

	-- Set cooldown flag
	playerCooldowns[userId] = true

	-- Create cooldown indicator for the player
	local cooldownGui = Instance.new("ScreenGui")
	cooldownGui.Name = "SpringCooldownGui"

	local cooldownFrame = Instance.new("Frame")
	cooldownFrame.Size = UDim2.new(0, 200, 0, 30)
	cooldownFrame.Position = UDim2.new(0.5, -100, 0.8, 0)
	cooldownFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cooldownFrame.BackgroundTransparency = 0.5
	cooldownFrame.BorderColor3 = Color3.fromRGB(255, 165, 0)
	cooldownFrame.Parent = cooldownGui

	local cooldownText = Instance.new("TextLabel")
	cooldownText.Size = UDim2.new(1, 0, 1, 0)
	cooldownText.BackgroundTransparency = 1
	cooldownText.TextColor3 = Color3.fromRGB(255, 255, 255)
	cooldownText.Font = Enum.Font.GothamBold
	cooldownText.TextSize = 16
	cooldownText.Text = "Spring Cooldown: " .. cooldownTime .. "s"
	cooldownText.Parent = cooldownFrame

	cooldownGui.Parent = player.PlayerGui

	-- Start cooldown countdown
	for i = cooldownTime, 1, -1 do
		cooldownText.Text = "Spring Cooldown: " .. i .. "s"
		wait(1)
	end

	-- Remove cooldown flag and GUI
	playerCooldowns[userId] = nil
	cooldownGui:Destroy()
end

-- Calculate the best force for the spring jump
local function calculateSpringForce(directionVector)
	-- Calculate distance factor (normalized based on direction vector)
	local distance = directionVector.Magnitude

	-- Ensure we're never below MIN_VELOCITY for short jumps
	local forceMagnitude = math.max(BASE_FORCE, MIN_VELOCITY / directionVector.Unit.Magnitude)

	-- Cap at maximum force for very long jumps
	forceMagnitude = math.min(forceMagnitude, MAX_FORCE)

	-- Return direction * force
	return directionVector.Unit * forceMagnitude
end

bouncePad.Touched:Connect(function(touch)
	local char = touch.Parent
	local player = game.Players:GetPlayerFromCharacter(char)

	-- Check if it's a player, has required parts, and not on individual cooldown
	if player and 
		char:FindFirstChild("HumanoidRootPart") and 
		not char:FindFirstChild("HumanoidRootPart"):FindFirstChild("BodyVelocity") and 
		not isOnCooldown(player) and
		canSound == true then

		-- Debug info
		print("Spring used by: " .. player.Name)
		if player.Team then
			print("Player team: " .. player.Team.Name)
			print("Team cooldown: " .. getCooldownDuration(player) .. "s")
		end

		canSound = false

		-- Play bounce animation
		local humanoid = char:FindFirstChild("Humanoid")
		if humanoid then
			local animTrack = humanoid:LoadAnimation(springAnim)
			animTrack:Play()

			-- Stop animation after bounce
			task.delay(1, function()
				animTrack:Stop()
			end)
		end

		-- Calculate the desired velocity (this is the key improvement)
		local directionVector = bouncePad.CFrame.LookVector
		local velocityVector = calculateSpringForce(directionVector)

		-- Create and apply the bounce force
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = velocityVector
		bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bodyVelocity.P = math.huge  -- High P value for immediate effect
		bodyVelocity.Parent = char.HumanoidRootPart

		-- Play sound
		script.Parent.Spring:Play()

		-- Apply player-specific cooldown
		spawn(function()
			putOnCooldown(player)
		end)

		-- Reset sound cooldown
		wait(soundCooldown)
		canSound = true

		-- Remove bounce force after short delay (REDUCED to make jumps faster)
		wait(VELOCITY_DURATION)
		bodyVelocity:Destroy()
	end
end)

-- Clean up cooldowns when players leave
game.Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil
end)