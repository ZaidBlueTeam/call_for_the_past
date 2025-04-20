wait(1) -- Wait for the character to load in
local UIS = game:GetService("UserInputService") -- Service to detect key presses
local TS = game:GetService("TweenService") -- Tween service for animating camera FOV
local TI1 = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out) -- Tween info for sprinting
local TI2 = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) -- Tween info for walking
local plr = game.Players.LocalPlayer -- Get the player
local sprint = script:WaitForChild("Sprint Speed").Value -- Speed of the sprint
local walk = script:WaitForChild("Walk Speed").Value -- Normal walk speed
local camera = workspace.CurrentCamera -- Get the player's camera
local h = plr.Character:WaitForChild("Humanoid") -- Humanoid for changing player speed
local ZoomIn = {FieldOfView = 70} -- Normal FOV
local ZoomOut = {FieldOfView = 80} -- FOV while sprinting
local Walking = {WalkSpeed = walk} -- Normal walk speed settings
local Sprinting = {WalkSpeed = sprint} -- Sprint speed settings

local isRunning = false -- Player running status
local wasMoving = false -- Player movement status

-- Function to check if the player is moving
local function isPlayerMoving()
	return h.MoveDirection.Magnitude > 0
end

UIS.InputBegan:Connect(function(key, process) -- When a key is pressed
	if not process then -- If the key isn't being used for something else
		if (key.KeyCode == Enum.KeyCode.LeftShift or key.KeyCode == Enum.KeyCode.RightShift or key.KeyCode == Enum.KeyCode.ButtonL2) then -- When shift is pressed
			if not isRunning then -- If player is not sprinting
				isRunning = true -- Set running to true
				TS:Create(h, TI1, Sprinting):Play() -- Smoothly increase player's walk speed
			end
		end
	end
end)

UIS.InputEnded:Connect(function(key, process) -- When a key is released
	if not process then
		if (key.KeyCode == Enum.KeyCode.LeftShift or key.KeyCode == Enum.KeyCode.RightShift or key.KeyCode == Enum.KeyCode.ButtonL2) then
			if isRunning then
				isRunning = false -- Set running to false
				TS:Create(h, TI2, Walking):Play() -- Restore walk speed
				if wasMoving then -- Only change FOV if they were moving
					TS:Create(camera, TI2, ZoomIn):Play() -- Tween FOV back to normal
				end
			end
		end
	end
end)

game:GetService("RunService").Heartbeat:Connect(function()
	if isRunning and isPlayerMoving() then -- If sprinting and moving
		if not wasMoving then -- If they weren't previously moving
			wasMoving = true -- Now they are moving
			TS:Create(camera, TI1, ZoomOut):Play() -- Change FOV to zoom out
		end
	else
		if wasMoving then -- If they are no longer moving
			wasMoving = false -- Not moving anymore
			TS:Create(camera, TI2, ZoomIn):Play() -- Change FOV back to normal
		end
	end
end)

if UIS.TouchEnabled then -- If touch enabled, provide sprint tool
	local tool = script.Sprint
	tool["Sprint Speed"].Value = sprint
	tool["Walk Speed"].Value = walk
	tool:Clone().Parent = plr.StarterGear
	tool.Parent = plr.Backpack
end