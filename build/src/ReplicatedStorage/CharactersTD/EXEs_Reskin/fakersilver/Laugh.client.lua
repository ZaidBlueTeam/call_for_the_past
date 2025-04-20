local player = game.Players.LocalPlayer
repeat wait() until player.Character and player.Character:FindFirstChild("Humanoid")

local character = player.Character
local humanoid = character:FindFirstChild("Humanoid")
local mouse = player:GetMouse()
local camera = game.Workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tauntEvent = ReplicatedStorage:FindFirstChild("TauntEvent")

-- Define the laugh animation ID
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://139232083405223" -- This is your laugh animation ID

-- Find the "Eyes" and "EXE Eyes" parts in the character
local head = character:FindFirstChild("head")
local normalEyes = head and head:FindFirstChild("eyes")
local normalPupil1 = normalEyes and normalEyes:FindFirstChild("pupil1")
local normalPupil2 = normalEyes and normalEyes:FindFirstChild("pupil2")

local exeEyes = head and head:FindFirstChild("exeEye")
local exeEye1 = exeEyes and exeEyes:FindFirstChild("exeEye1")
local exeEye2 = exeEyes and exeEyes:FindFirstChild("exeEye2")

-- The white eye part
local whiteEye = normalEyes and normalEyes:FindFirstChild("eyes")

-- Function to show EXE eyes and black out the white eye part
local function showExeEyes()
	if normalPupil1 and normalPupil2 then
		normalPupil1.Transparency = 1 -- Make normal pupils invisible
		normalPupil2.Transparency = 1
	end

	if exeEye1 and exeEye2 then
		exeEye1.Transparency = 0 -- Make EXE pupils visible
		exeEye2.Transparency = 0
	end

	if whiteEye then
		whiteEye.Color = Color3.fromRGB(0, 0, 0) -- Make the white eye part black
	end
end

-- Function to revert to normal eyes
local function revertToNormalEyes()
	if normalPupil1 and normalPupil2 then
		normalPupil1.Transparency = 0 -- Make normal pupils visible again
		normalPupil2.Transparency = 0
	end

	if exeEye1 and exeEye2 then
		exeEye1.Transparency = 1 -- Make EXE pupils invisible
		exeEye2.Transparency = 1
	end

	if whiteEye then
		whiteEye.Color = Color3.fromRGB(255, 255, 255) -- Revert the white eye part to white
	end
end

-- Find the "Laugh" sound inside the character model
local laughSound = character:FindFirstChild("Laugh")

-- Cooldown logic
local cooldownTime = 5 -- Cooldown in seconds
local lastLaughTime = 0 -- Last time the laugh animation was triggered

-- Flag to prevent spamming
local canTrigger = true

-- Detect the key press and play the animation with cooldown
mouse.KeyDown:Connect(function(key)
	if key == "q" and canTrigger then
		local currentTime = tick()
		if currentTime - lastLaughTime >= cooldownTime then
			-- Prevent further triggering of the animation
			canTrigger = false

			-- Show EXE eyes and black out the white eye part when the animation starts
			showExeEyes()

			-- Play the laugh animation locally
			local playAnim = humanoid:LoadAnimation(anim)
			playAnim:Play()

			-- Tell the server to play the sound (via RemoteEvent)
			if tauntEvent then
				tauntEvent:FireServer()  -- Trigger the sound to play on the server side
			end

			-- Revert to normal eyes and stop the animation after it ends
			wait(2) -- Adjust this time to match the length of your animation
			playAnim:Stop()
			revertToNormalEyes()

			-- Update the last laugh time to the current time
			lastLaughTime = currentTime

			-- Re-enable triggering after cooldown
			wait(cooldownTime)
			canTrigger = true
		else
			-- Notify the player that they need to wait before laughing again
			local remainingCooldown = cooldownTime - (currentTime - lastLaughTime)
			print("Please wait " .. math.ceil(remainingCooldown) .. " more seconds before laughing again.")
		end
	end
end)

-- Adjust sound based on camera distance
game:GetService("RunService").Heartbeat:Connect(function()
	if laughSound then
		-- Calculate the distance between the camera and the sound source (character)
		local distance = (camera.CFrame.Position - character.HumanoidRootPart.Position).Magnitude

		-- Set the MaxDistance and adjust volume based on distance
		local maxDistance = 50
		local minDistance = 10
		local volume = math.clamp(1 - (distance - minDistance) / (maxDistance - minDistance), 0, 1)

		-- Set the sound's volume based on the calculated distance
		laughSound.Volume = volume
	end
end)
