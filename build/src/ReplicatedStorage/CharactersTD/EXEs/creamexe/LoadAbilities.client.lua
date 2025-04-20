local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player.PlayerGui
local Abilities = require(game.StarterGui.gui.client.Abilities)
local objects = require(game.StarterGui.gui.client.objects)

Abilities.CreateAbility("Action1", "Arm Cannon", 11112394959, 6472846460, false, "f")
Abilities.CreateAbility("Action2", "Glide", 11112378242, 7031565438, false, "e")

script.Parent.Humanoid.Died:Connect(function()
	Abilities.Destroy("Arm Cannon")
	Abilities.Destroy("Glide")
end)
objects.springs()