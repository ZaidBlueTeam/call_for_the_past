wait(1.1)
local TS = game:GetService("TweenService")
local TI1 = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TI2 = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local plr = game.Players.LocalPlayer
local speed = script.Parent:WaitForChild("Sprint Speed").Value
local walk = script.Parent:WaitForChild("Walk Speed").Value
local h = plr.Character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local ZoomIn = {FieldOfView = 70}
local ZoomOut = {FieldOfView = 80}
local Walking = {WalkSpeed = walk}
local Sprinting = {WalkSpeed = speed}

local isRunning = false

script.Parent.Equipped:Connect(function()
	if not isRunning then
		isRunning = true
		TS:Create(h, TI1, Sprinting):Play()
		TS:Create(camera, TI1, ZoomOut):Play()
	end
end)

script.Parent.Unequipped:Connect(function()
	if isRunning then
		isRunning = false
		TS:Create(h, TI2, Walking):Play()
		TS:Create(camera, TI2, ZoomIn):Play()
	end
end)

























-- heheheha