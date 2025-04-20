local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DashEvent = ReplicatedStorage:WaitForChild("DashEvent") -- RemoteEvent to trigger dash

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local dashAnim = Instance.new("Animation")
dashAnim.AnimationId = "rbxassetid://140204852176137" -- Dash animation ID

local isDashing = false
local DASH_DURATION = 1.5 -- How long dash lasts before stopping
local DASH_SPEED = 70 -- Dash speed (adjustable)
local DASH_COOLDOWN = 20 -- Cooldown time before dashing again
local dashCooldown = false

-- Function to start dash
local function startDash()
	if isDashing or dashCooldown then return end  
	isDashing = true
	dashCooldown = true

	-- Play dash animation
	local animTrack = humanoid:LoadAnimation(dashAnim)
	animTrack:Play()
	animTrack:AdjustSpeed(3) -- Adjust speed if needed

	-- Fire event to server to handle dash logic
	DashEvent:FireServer(DASH_SPEED, DASH_DURATION)

	-- Stop dash after duration
	task.delay(DASH_DURATION, function()
		isDashing = false
		animTrack:Stop()
	end)

	-- Start cooldown
	task.delay(DASH_COOLDOWN, function()
		dashCooldown = false
	end)
end

-- Bind "E" key to start dashing
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then
		startDash()
	end
end)

-- Controller support for Dash using X button
local UserInputService = game:GetService("UserInputService")

-- Handle dash with X button
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.ButtonX then
		-- Call your existing dash function
		startDash()
	end
end)
