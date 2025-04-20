local humanoid = script.Parent:WaitForChild("Humanoid")
local rootPart = script.Parent:WaitForChild("HumanoidRootPart")
local animation = Instance.new("Animation")

humanoid.StateChanged:Connect(function(oldState, newState)
	if newState == Enum.HumanoidStateType.Landed then
		local verticalSpeed = math.abs(rootPart.Velocity.Y)
		local horizontalSpeed = rootPart.Velocity.X
		if verticalSpeed > 90 and humanoid.WalkSpeed < 15 then
			print(1)
			local animationId = "rbxassetid://18679611951"
			local animationSpeed = 1.5
			animation.AnimationId = animationId
			local animationTrack = humanoid:LoadAnimation(animation)
			animationTrack:Play()
			animationTrack:AdjustSpeed(animationSpeed)
			local floorMaterial = humanoid.FloorMaterial
			script.LandEvent:FireServer()
		elseif verticalSpeed > 1 and verticalSpeed < 90 then
			print(2)
			local animationId = "rbxassetid://18679625495"
			local animationSpeed = 1
			animation.AnimationId = animationId
			local animationTrack = humanoid:LoadAnimation(animation)
			animationTrack:Play()
			animationTrack:AdjustSpeed(animationSpeed)
			local floorMaterial = humanoid.FloorMaterial
			script.LandEvent:FireServer()
		elseif verticalSpeed > 90 and humanoid.WalkSpeed > 15 then
			print(3)
			local animationId = "rbxassetid://18679671519"
			local animationSpeed = 1
			animation.AnimationId = animationId
			local animationTrack = humanoid:LoadAnimation(animation)
			animationTrack:Play()
			animationTrack:AdjustSpeed(animationSpeed)
			local floorMaterial = humanoid.FloorMaterial
			script.LandEvent:FireServer()
		end
	end
end)