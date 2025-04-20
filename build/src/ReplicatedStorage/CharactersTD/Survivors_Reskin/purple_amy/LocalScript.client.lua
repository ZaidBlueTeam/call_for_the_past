local char = script.Parent
local Players = game:GetService("Players")
local player = Players:GetPlayerFromCharacter(char)
local Gui = script.ScreenGui
local CurHP=Gui.CurHP
local MaxHP=Gui.MaxHP
Gui.Parent = player.PlayerGui
CurHP.Text = char.Humanoid.Health
MaxHP.Text = char.Humanoid.MaxHealth
local HPBar= Gui.HPFrame.HPBar
while true do
	wait(0.2)
	CurHP.Text = char.Humanoid.Health
	MaxHP.Text = " / "..char.Humanoid.MaxHealth
	HPBar:TweenSize(UDim2.new(char.Humanoid.Health/char.Humanoid.MaxHealth, 0, 1, 0))
		
end