local UserInput = game:GetService("UserInputService")
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://16853549614" -- Paste your animation id here
local charge = Instance.new("Animation")
charge.AnimationId = "rbxassetid://16853546759" -- Paste your animation id here
local shoot = Instance.new("Animation")
shoot.AnimationId = "rbxassetid://16853551625" -- Paste your animation id shoot here
local humanoid = script.Parent.Parent.Parent:WaitForChild("Humanoid")
local playAnim = humanoid:LoadAnimation(anim)
local ChargeAnim = humanoid:LoadAnimation(charge)
local ShootAnim = humanoid:LoadAnimation(shoot)
local debounce = true
local Cooldown = 5
local CanShoot = false
local Fire = script.Parent.firepart
local player = game.Players.LocalPlayer
local character = player.Character
local mouse = player:GetMouse()
local PlrValue = humanoid.Parent.PlrValue
local CanRun = PlrValue.Other.Values.Movement.CanRun
local CanJump = PlrValue.Other.Values.Movement.CanJump
local PlayerGui = player.PlayerGui
local mouse = player:GetMouse()
local DefaultMouse = mouse.Icon

UserInput.InputBegan:Connect(function(input , gameProccesedevent)
	if input.KeyCode == Enum.KeyCode.F and debounce == true and CanShoot == false then
		debounce = false
		script.Parent.light.Enabled = true
		Fire.arcs.Enabled = true
		Fire.charging.Enabled = true
		Fire.core.Enabled = true
		ChargeAnim:Play()
		script.Parent.charge:Play()
		wait(2.315)
		script.PrototypeFollow.Enabled = true
		mouse.Icon = "rbxassetid://11512006852"
		ChargeAnim:Stop()
		playAnim:Play()
		CanShoot = true
		CanRun.Value = false
		CanJump.Value = false
		humanoid.WalkSpeed = 7
	end
end)

mouse.Button1Down:Connect(function()
	if CanShoot == true and debounce == false then
		CanShoot = false
		script.CannonEvent:FireServer(mouse.hit.p)
		mouse.Icon = DefaultMouse
		local lunge = Instance.new("BodyVelocity")
		lunge.MaxForce = Vector3.new(1,0,1) * 30000
		lunge.Velocity = humanoid.Parent.HumanoidRootPart.CFrame.lookVector * -50
		lunge.Parent = humanoid.Parent.HumanoidRootPart
		script.PrototypeFollow.Enabled = false
		playAnim:Stop()
		script.Parent.light.Enabled = false
		Fire.arcs.Enabled = false
		Fire.charging.Enabled = false
		Fire.core.Enabled = false
		wait(0.1)
		ShootAnim:Play()
		for count = 1, 12 do
			wait(0.05)
			lunge.Velocity*= 0.7
		end
		lunge:Destroy()
		CanRun.Value = true
		CanJump.Value = true
		wait(Cooldown)
		debounce = true
	end
end)



