local human = script.Parent.Parent.Parent:WaitForChild("Humanoid")
local Player = game.Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local AttackArm = true

local canattack = true


-------------------PC-------------------

game:GetService("UserInputService").InputBegan:connect(function(input, gamepor)
	if (input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonY) and canattack and human.Parent.PlrValue.Other.Values.Abilities.Punch.Value == true then
		canattack = false
		script.RemoteEvent:FireServer(AttackArm)
		human:LoadAnimation(AttackArm and script.R or script.L):Play()
		wait(5)
		AttackArm = not AttackArm
		canattack = true
	end	
end)