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
local isAutoRunning = false -- Auto-run status

-- Function to check if the player is moving
local function isPlayerMoving()
	return h.MoveDirection.Magnitude > 0
end

-- Toggle sprint function for Shift key
local function toggleSprint()
	if isRunning then
		-- Stop sprinting
		isRunning = false
		TS:Create(h, TI2, Walking):Play() -- Smoothly restore walk speed
		if wasMoving then -- Only change FOV if they were moving
			TS:Create(camera, TI2, ZoomIn):Play() -- Tween FOV back to normal
		end
	else
		-- Start sprinting
		isRunning = true
		TS:Create(h, TI1, Sprinting):Play() -- Smoothly increase walk speed
		if isPlayerMoving() then
			TS:Create(camera, TI1, ZoomOut):Play() -- Zoom out FOV when moving
		end
	end
end

-- Toggle auto-run function for Ctrl key
local function toggleAutoRun()
	if not isAutoRunning then
		-- Start auto-running
		isAutoRunning = true
		TS:Create(h, TI1, Sprinting):Play() -- Start sprinting
		TS:Create(camera, TI1, ZoomOut):Play() -- Zoom out FOV for auto-run
	else
		-- Stop auto-running
		isAutoRunning = false
		TS:Create(h, TI2, Walking):Play() -- Restore walk speed
		if wasMoving then -- Only change FOV if they were moving
			TS:Create(camera, TI2, ZoomIn):Play() -- Tween FOV back to normal
		end
	end
end

-- Input detection for sprint and auto-run toggle
UIS.InputBegan:Connect(function(key, process)
	if not process then -- If the key isn't being used for something else
		if key.KeyCode == Enum.KeyCode.LeftShift or key.KeyCode == Enum.KeyCode.RightShift then
			if not isAutoRunning then -- If not auto-running, hold shift to sprint
				isRunning = true
				TS:Create(h, TI1, Sprinting):Play() -- Smoothly increase walk speed
			end
		elseif key.KeyCode == Enum.KeyCode.LeftControl or key.KeyCode == Enum.KeyCode.RightControl then
			toggleAutoRun() -- Toggle auto-run on Ctrl press
		end
	end
end)

-- Input detection for releasing Shift
UIS.InputEnded:Connect(function(key, process)
	if not process then
		if key.KeyCode == Enum.KeyCode.LeftShift or key.KeyCode == Enum.KeyCode.RightShift then
			if not isAutoRunning then
				isRunning = false
				TS:Create(h, TI2, Walking):Play() -- Restore walk speed when shift is released
				if wasMoving then -- Only change FOV if they were moving
					TS:Create(camera, TI2, ZoomIn):Play() -- Tween FOV back to normal
				end
			end
		end
	end
end)

-- Detect if the player is moving and adjust the FOV accordingly
game:GetService("RunService").Heartbeat:Connect(function()
	if isRunning and isPlayerMoving() then -- If sprinting and moving
		if not wasMoving then -- If they weren't previously moving
			wasMoving = true -- Now they are moving
			TS:Create(camera, TI1, ZoomOut):Play() -- Change FOV to zoom out
		end
	elseif isAutoRunning and isPlayerMoving() then -- Auto-run and moving
		if not wasMoving then
			wasMoving = true
			TS:Create(camera, TI1, ZoomOut):Play() -- Change FOV to zoom out
		end
	else
		if wasMoving then -- If they are no longer moving
			wasMoving = false -- Not moving anymore
			TS:Create(camera, TI2, ZoomIn):Play() -- Change FOV back to normal
		end
	end
end)

-- Touch input: if touch enabled, provide sprint tool
if UIS.TouchEnabled then -- If touch enabled, provide sprint tool
	local tool = script.Sprint
	tool["Sprint Speed"].Value = sprint
	tool["Walk Speed"].Value = walk
	tool:Clone().Parent = plr.StarterGear
	tool.Parent = plr.Backpack
end

-- Controller support for Sprint
local isAutoSprinting = false

-- Controller support for Sprint
local isAutoSprinting = false
local UIS = game:GetService("UserInputService") -- Get UserInputService properly

-- Handle sprint with LT
UIS.InputChanged:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.ButtonL2 then
		if input.Position.Z > 0.5 then
			-- Use your existing sprint system
			isRunning = true
			TS:Create(h, TI1, Sprinting):Play()
			if isPlayerMoving() then
				TS:Create(camera, TI1, ZoomOut):Play()
			end
		else
			if not isAutoSprinting then
				isRunning = false
				TS:Create(h, TI2, Walking):Play()
				if wasMoving then
					TS:Create(camera, TI2, ZoomIn):Play()
				end
			end
		end
	end
end)

-- Handle auto-sprint toggle with LB
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.ButtonL1 then
		isAutoSprinting = not isAutoSprinting

		if isAutoSprinting then
			isRunning = true
			TS:Create(h, TI1, Sprinting):Play()
			if isPlayerMoving() then
				TS:Create(camera, TI1, ZoomOut):Play()
			end
		else
			isRunning = false
			TS:Create(h, TI2, Walking):Play()
			if wasMoving then
				TS:Create(camera, TI2, ZoomIn):Play()
			end
		end
	end
end)

