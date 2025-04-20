local UserInput = game:GetService("UserInputService")
local humanoid = script.Parent.Parent.Parent:WaitForChild("Humanoid")
local canpress = true
local cooldown = 5
local PlrValue = humanoid.Parent:WaitForChild("PlrValue")
local Abilities = PlrValue.Other.Values:WaitForChild("Abilities")
local Jetpack = Abilities:WaitForChild("Jetpack")
local Player = game.Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local Action = PlayerGui.gui.Abilities.regular.Action2

-------------------PC-------------------

UserInput.InputBegan:Connect(function(input , gameProccesedevent)
	if input.KeyCode == Enum.KeyCode.E and canpress and Jetpack.Value == true then
		canpress = false
		Action.abilityName.TextColor3 = Color3.new(1, 0.0224613, 0)
		Action.icon.ImageColor3 = Color3.new(1, 0.0224613, 0)
		script.JetPackEvent:FireServer()
		wait(cooldown)
		Action.abilityName.TextColor3 = Color3.new(255, 255, 255)
		Action.icon.ImageColor3 = Color3.new(255, 255, 255)
		canpress = true
	end

end)

-------------------Mobile-------------------

PlayerGui.gui.Abilities.Eggman.Jetpack.MouseButton1Click:Connect(function()
	if canpress and Jetpack.Value == true then
		canpress = false
		script.JetPackEvent:FireServer()
		PlayerGui.gui.Abilities.Eggman.Jetpack.ImageColor3 = Color3.new(1, 0.0449073, 0)
		wait(cooldown)
		PlayerGui.soundtracks.sfx.recharged:Play()
		PlayerGui.gui.Abilities.Eggman.Jetpack.ImageColor3 = Color3.new(0.988235, 1, 1)
		canpress = true
	end

end)