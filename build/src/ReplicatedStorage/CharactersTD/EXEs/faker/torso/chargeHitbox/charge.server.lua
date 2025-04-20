local Part = script.Parent
local FLOAT_FORCE = 9000000000000000

Part.Touched:Connect(function(hit)
	if hit.Parent:WaitForChild("Humanoid") ~= nil then
		script.Parent.Parent.torso.chargeTargetHit:Play()
		local glideForce = Instance.new("BodyVelocity")
		glideForce.Name = "GlideForce"
		glideForce.MaxForce = Vector3.new(0, FLOAT_FORCE, 0)
		glideForce.Velocity = Vector3.new(0, 100, 0)
		glideForce.Parent = hit.Parent.HumanoidRootPart
		task.wait(0.3)
		glideForce:Destroy()
	end
end)