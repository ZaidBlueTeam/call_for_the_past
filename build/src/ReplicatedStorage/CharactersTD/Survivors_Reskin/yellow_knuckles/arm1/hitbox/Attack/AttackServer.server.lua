LArm = script.Parent.Parent.Parent:WaitForChild("hitbox")
RArm = script.Parent.Parent.Parent:WaitForChild("hitbox")
local human = RArm.Parent.Parent:WaitForChild("Humanoid")

attacking = false
canattack = false

script.Parent.RemoteEvent.OnServerEvent:connect(function(plr, AttackArm)
	canattack = true
	wait(0.1)
	LArm.Transparency = 0.55
	script.Parent.Parent.swoosh:Play()
	attacking = AttackArm and "right" or "left"
	wait(0.6)
	LArm.Transparency = 1
	attacking = false
end)

function a(hit, arm)
	if canattack  and attacking == arm and hit.Parent:FindFirstChild("PlrValue").Other.Values.character.Value == "dummy" then
			canattack = false
			script.Parent.Parent.stun:Play()
			hit.Parent:FindFirstChild("PlrValue").Other.Values.Stun.Value = true
			local slide = Instance.new("BodyVelocity")
			slide.MaxForce = Vector3.new(1,0,1) * 30000
			slide.Velocity = human.Parent.HumanoidRootPart.CFrame.lookVector * 50
			slide.Parent = hit.Parent.HumanoidRootPart

			for count = 1, 19 do
				wait(0.1)
				slide.Velocity*= 0.7
			end
			slide:Destroy()
			wait(3)
			hit.Parent:FindFirstChild("PlrValue").Other.Values.Stun.Value = false
	end	
end

LArm.Touched:connect(function(hit)
	a(hit, "left")
end)
RArm.Touched:connect(function(hit)
	a(hit, "right")
end)