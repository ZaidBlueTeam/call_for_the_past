-- thank you for using. i comment everything incase you want to understand it but if you already do then good for you.
wait(1) -- just to wait for the character to actually load in
local UIS = game:GetService("UserInputService") -- get the service to detect if the player presses a key
local TS = game:GetService("TweenService") -- tween service to tween the field of view of the camera
local TI1 = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out) -- tween info for sprinting
local TI2 = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) -- tween info for not sprinting
local plr = game.Players.LocalPlayer -- get player
local sprint = script:WaitForChild("Sprint Speed").Value -- speed of the sprint
local walk = script:WaitForChild("Walk Speed").Value
local camera = workspace.CurrentCamera -- get players camera
local h = plr.Character:WaitForChild("Humanoid") -- humanoid so we can change the speed of the player
local ZoomIn = {FieldOfView = 70} -- normal fov
local ZoomOut = {FieldOfView = 80} -- fov when sprinting
local Walking = {WalkSpeed = walk} -- normal walk speed
local Sprinting = {WalkSpeed = sprint} -- the sprint speed (you can change this under this script)

local isRunning = false -- player running variable

UIS.InputBegan:Connect(function(key, process) -- when the player presses a key
	if not process then -- if the player isnt using the key for something else
		if (key.KeyCode == Enum.KeyCode.LeftShift or key.KeyCode == Enum.KeyCode.RightShift or key.KeyCode == Enum.KeyCode.ButtonL2) then -- when the key is left shift 
			if not isRunning then -- if player is not sprinting then
				isRunning = true -- pretty obvious
				TS:Create(h, TI1, Sprinting):Play() -- smoothly increases the players walkspeed
				TS:Create(camera, TI1, ZoomOut):Play() -- tween field of view to be out
			end
		end
	end
end)

UIS.InputEnded:Connect(function(key, process) -- this all does the same as the above but the opposite and when the player lets go of the shift key
	if not process then
		if (key.KeyCode == Enum.KeyCode.LeftShift or key.KeyCode == Enum.KeyCode.RightShift or key.KeyCode == Enum.KeyCode.ButtonL2) then
			if isRunning then
				isRunning = false
				TS:Create(h, TI2, Walking):Play()
				TS:Create(camera, TI2, ZoomIn):Play()
			end
		end
	end
end)

if UIS.TouchEnabled then -- if the player has a touch enabled device (mobile or touch enabled desktop), then it will run give the player a sprint tool
	local tool = script.Sprint
	tool["Sprint Speed"].Value = sprint
	tool["Walk Speed"].Value = walk
	tool:Clone().Parent = plr.StarterGear
	tool.Parent = plr.Backpack
	return
end


















-- heheheha