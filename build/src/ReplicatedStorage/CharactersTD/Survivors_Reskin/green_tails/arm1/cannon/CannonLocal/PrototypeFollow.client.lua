local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local canOriente = true

local function OrienterVersSouris()
	local mouse = player:GetMouse()
	local lookVector = (mouse.Hit.p - character.Head.Position).unit
	character:SetPrimaryPartCFrame(CFrame.new(character.PrimaryPart.Position, character.PrimaryPart.Position + Vector3.new(lookVector.x, 0, lookVector.z)))
end

if canOriente then
	game:GetService("RunService").Stepped:Connect(OrienterVersSouris)
else
	game:GetService("RunService").Stepped:Disconnect()
end
