local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

Humanoid.StateChanged:Connect(function(old,new)
	if new == Enum.HumanoidStateType.Jumping then
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
		task.wait(2)  -- How long the cooldown lasts
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
	end
end)