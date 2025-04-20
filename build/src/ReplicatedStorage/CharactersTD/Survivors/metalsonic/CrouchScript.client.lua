--[[ Made by coolcapidog
Channel ->> https://www.youtube.com/c/coolcapidog
You can change the settings but you shouldn't change anything except settings.
]]

local NormalWalkSpeed = 16
local CrouchSpeed = 10
local AnimID = "rbxassetid://138118566124982"

local cas = game:GetService("ContextActionService")
local Leftc = Enum.KeyCode.LeftControl
local RightC = Enum.KeyCode.RightControl
local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local Humanoid = char:WaitForChild("Humanoid")
local CrouchAnim = Instance.new("Animation")
CrouchAnim.AnimationId = AnimID
local CAnim = Humanoid:LoadAnimation(CrouchAnim)

local Camera = game.Workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

UIS.InputBegan:Connect(function(key, gameProcessed)
	if gameProcessed then return end
	if key.KeyCode == Enum.KeyCode.LeftControl then
		Humanoid.WalkSpeed = CrouchSpeed
		Humanoid.JumpPower = 0
		Humanoid.JumpHeight = 0
		CAnim:Play()
	end
end)

UIS.InputEnded:Connect(function(key, gameProcessed)
	if gameProcessed then return end
	if key.KeyCode == Enum.KeyCode.LeftControl then
		Humanoid.WalkSpeed = NormalWalkSpeed
		Humanoid.JumpPower = 50
		Humanoid.JumpHeight = 7.2
		CAnim:Stop()
	end
end)

--------------------------------------------------- Mobile Button

local function handleContext(name, state, input)
	if state == Enum.UserInputState.Begin then
		Humanoid.WalkSpeed = CrouchSpeed
		CAnim:Play()
	else
		Humanoid.WalkSpeed = NormalWalkSpeed
		CAnim:Stop()
	end
end

cas:BindAction("Crouch", handleContext, true, Leftc, RightC)
cas:SetPosition("Crouch", UDim2.new(.2, 0, .5, 0))
cas:SetTitle("Crouch", "Crouch")
cas:GetButton("Crouch").Size = UDim2.new(.3, 0, .3, 0)