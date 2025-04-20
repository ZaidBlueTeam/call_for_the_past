local Event = script.Parent:WaitForChild('LookEvent')
local Ang = CFrame.Angles
local aSin = math.asin
local aCos = math.acos

local Character = script.Parent.Parent
local Head = Character.head.head
local Humanoid = Character:WaitForChild('Humanoid')

local Torso
local Neck

if Humanoid.RigType == Enum.HumanoidRigType.R6 then
	Torso = Character:WaitForChild('Torso')
	Neck = Torso.Parent.torso.main:WaitForChild('head')
end

local RootPart = Character:WaitForChild('HumanoidRootPart')
local NeckOrgnC0 = Neck.C0

local MaxHeadRotationY = math.rad(150) -- Y ekseni için maksimum dönüş açısı (örneğin 80 derece)

Event.OnServerEvent:Connect(function(Player, CameraCFrame, HeadHorFactor, HeadVertFactor, UpdateSpeed, TorsoHorFactor, TorsoVertFactor)
	if Humanoid.RigType == Enum.HumanoidRigType.R6 then
		local HeadPosition = Head.CFrame.Position
		local LookDirection = (CameraCFrame.Position - HeadPosition).unit
		local TorsoLookVector = Torso.CFrame.lookVector
		local TorsoRightVector = Torso.CFrame.rightVector
		local TorsoUpVector = Torso.CFrame.upVector

		local DotLookUp = LookDirection:Dot(TorsoUpVector)
		local DotLookRight = LookDirection:Dot(TorsoRightVector)

		-- Kafayı yukarıya veya aşağıya hareket ettirmeyi durdurun
		local NeckRotationX = -aSin(DotLookUp) * HeadVertFactor

		-- Kafayı sağa veya sola döndürün
		local NeckRotationY = aSin(DotLookRight) * HeadHorFactor

		-- Sınırlandırma için NeckRotationY'yi kontrol edin
		NeckRotationY = math.clamp(NeckRotationY, -MaxHeadRotationY, MaxHeadRotationY)

		Neck.C0 = Neck.C0:Lerp(NeckOrgnC0 * Ang(NeckRotationX, NeckRotationY, 0), UpdateSpeed / 2)
	end
end)
