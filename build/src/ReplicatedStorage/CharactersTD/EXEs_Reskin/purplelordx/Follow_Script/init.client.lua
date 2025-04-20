local RunService = game:GetService('RunService')
local Event = script:WaitForChild('LookEvent')
local Player = game.Players.LocalPlayer
local Camera = workspace:WaitForChild('Camera')
local Character = Player.Character or Player.CharacterAdded:Wait()
local Head = Character:WaitForChild('Head')
local Humanoid = Character:WaitForChild('Humanoid')

local Torso
local Neck

if Humanoid.RigType == Enum.HumanoidRigType.R6 then
	Torso = Character:WaitForChild('Torso')
	Neck = Torso.Parent.torso.main:WaitForChild('head')
end

local RootPart = Character:WaitForChild('HumanoidRootPart')
local Mouse = Player:GetMouse()

local Ang = CFrame.Angles
local aSin = math.asin
local aTan = math.atan

local NeckOrgnC0 = Neck.C0

local HeadHorFactor = 1
local HeadVertFactor = -0.2

local TorsoHorFactor = 0
local TorsoVertFactor = 0

local UpdateSpeed = 1

while task.wait(1/60) do
	local CameraCFrame = Camera.CoordinateFrame

	Event:FireServer(CameraCFrame, HeadHorFactor, HeadVertFactor, UpdateSpeed, TorsoHorFactor, TorsoVertFactor)
end