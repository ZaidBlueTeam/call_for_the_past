local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Table to hold animations
local animations = {
	idle = "rbxassetid://18738028481",
	walk = "rbxassetid://18738069504",
	run = "rbxassetid://18738072556",
	jump = "rbxassetid://18738079416",
	fall = "rbxassetid://18738082233",
	-- Add other animations as needed
}

-- Function to load and play animation
local function playAnimation(animationId)
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local animationTrack = humanoid:LoadAnimation(animation)
	return animationTrack
end

-- Load animations
local animationTracks = {
	idle = playAnimation(animations.idle),
	walk = playAnimation(animations.walk),
	run = playAnimation(animations.run),
	jump = playAnimation(animations.jump),
	fall = playAnimation(animations.fall),
	-- Load other animations as needed
}

-- Function to stop all animations
local function stopAllAnimations()
	for _, track in pairs(animationTracks) do
		track:Stop()
	end
end

-- Function to adjust the speed of all animations
local function adjustAnimationSpeed(speedMultiplier)
	for _, track in pairs(animationTracks) do
		track:AdjustSpeed(speedMultiplier)
	end
end

-- Track if the jump animation is playing
local isJumping = false

-- Check for collisions
local function checkCollision()
	local characterRoot = character:FindFirstChild("HumanoidRootPart")
	if not characterRoot then return nil end

	local direction = characterRoot.CFrame.LookVector
	local ray = Ray.new(characterRoot.Position, direction * 5) -- Adjust length as needed
	local part, position = workspace:FindPartOnRay(ray, character)

	return part
end

-- State change handlers
humanoid.Running:Connect(function(speed)
	if not isJumping then
		if speed > 0 then
			local collidedPart = checkCollision()
			if collidedPart then
				-- If collision detected, play walk animation and adjust speed to 0
				if currentState ~= "Walking" then
					stopAllAnimations()
					animationTracks.walk:Play()
					adjustAnimationSpeed(0) -- Set animation speed to 0
					currentState = "Walking"
				end
			else
				-- If no collision detected, reset animation speed
				adjustAnimationSpeed(1)

				if speed > 16 then -- Assuming 16 is the speed threshold for running
					if currentState ~= "Running" then
						stopAllAnimations()
						animationTracks.run:Play()
						currentState = "Running"
					end
				else
					if currentState ~= "Walking" then
						if humanoid:GetState() == Enum.HumanoidStateType.Seated then
							stopAllAnimations()
							currentState = "Seated"
						else
							stopAllAnimations()
							animationTracks.walk:Play()
							currentState = "Walking"
						end
					end
				end
			end
		else
			if currentState ~= "Idle" then
				stopAllAnimations()
				animationTracks.idle:Play()
				currentState = "Idle"
			end
		end
	end
end)

humanoid.Jumping:Connect(function()
	if not isJumping then
		isJumping = true
		stopAllAnimations()
		animationTracks.jump:Play()
		currentState = "Jumping"

		-- Connect to the animation track's Stopped event
		local jumpTrack = animationTracks.jump
		jumpTrack.Stopped:Connect(function()
			-- Check if the character is in Freefall or Landing state
			if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				stopAllAnimations()
				animationTracks.fall:Play()
				currentState = "Freefall"
			end
		end)
	end
end)

humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Freefall then
		if currentState ~= "Freefall" and not isJumping then
			stopAllAnimations()
			animationTracks.fall:Play()
			currentState = "Freefall"
		end
	elseif newState == Enum.HumanoidStateType.Landed then
		if animationTracks.fall.IsPlaying then
			animationTracks.fall:Stop()
		end

		-- Ensure the idle animation is played correctly after landing
		if currentState ~= "Idle" and not isJumping then
			stopAllAnimations()
			animationTracks.idle:Play()
			currentState = "Idle"
		end
		isJumping = false -- Reset the jump flag
	elseif newState == Enum.HumanoidStateType.Seated then
		if currentState ~= "Seated" then
			stopAllAnimations()
			currentState = "Seated"
		end
	elseif newState == Enum.HumanoidStateType.RunningNoPhysics then
		if currentState ~= "RunningNoPhysics" then
			stopAllAnimations()
			currentState = "RunningNoPhysics"
		end
	end
end)

-- Initialize with idle animation
animationTracks.idle:Play()
currentState = "Idle"
