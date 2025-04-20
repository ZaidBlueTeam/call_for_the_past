local humanoid = script.Parent.Parent.Parent.Parent:WaitForChild("Humanoid")
local Sound = script.Parent.Parent.sfx
local anim = Instance.new("Animation")
anim.AnimationId = "http://www.roblox.com/asset/?id=16760667379"
local PlayAnim = humanoid:LoadAnimation(anim)

script.Parent.JetPackEvent.OnServerEvent:Connect(function()
	PlayAnim:Play()
	script.Parent.Parent.hole1.fire.Enabled = true
	script.Parent.Parent.hole2.fire.Enabled = true
	script.Parent.Parent.light.Enabled = true
	Sound:Play()
	local lunge = Instance.new("BodyVelocity")
	lunge.MaxForce = Vector3.new(0,1,0) * 30000
	lunge.Velocity = humanoid.Parent.HumanoidRootPart.CFrame.UpVector * 300
	lunge.Parent = humanoid.Parent.HumanoidRootPart
	for count = 1, 13 do
		wait(0.05)
		lunge.Velocity*= 0.7
	end
	script.Parent.Parent.hole1.fire.Enabled = false
	script.Parent.Parent.hole2.fire.Enabled = false
	script.Parent.Parent.light.Enabled = false
	PlayAnim:Stop()
	lunge:Destroy()
end)