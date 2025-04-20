local TeleportPart3 = script.Parent.TeleportPart3
local TeleportPart4 = script.Parent.TeleportPart4

TeleportPart3.Touched:Connect(function(hit)
	local w = hit.Parent:FindFirstChild("HumanoidRootPart")
	if w then
		w.CFrame = TeleportPart4.CFrame + Vector3.new(0, 5, 0)
		TeleportPart4.CanTouch = false
		wait(1)
		TeleportPart4.CanTouch = true
	end
end)

TeleportPart4.Touched:Connect(function(hit)
	local w = hit.Parent:FindFirstChild("HumanoidRootPart")
	if w then
		w.CFrame = TeleportPart3.CFrame + Vector3.new(0, 5, 0)
		TeleportPart3.CanTouch = false
		wait(1)
		TeleportPart3.CanTouch = true
	end
end)