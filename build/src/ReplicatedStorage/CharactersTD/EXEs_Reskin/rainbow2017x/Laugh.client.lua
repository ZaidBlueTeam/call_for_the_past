local player = game.Players.LocalPlayer
repeat wait() until player.Character and player.Character:FindFirstChild("Humanoid")

local character = player.Character
local humanoid = character:FindFirstChild("Humanoid")
local mouse = player:GetMouse()
local camera = game.Workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tauntEvent = ReplicatedStorage:FindFirstChild("TauntEvent")

-- Define the laugh animation ID (replace with your actual animation ID)
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://111233933866620" -- This is your laugh animation ID

-- Find the "Laugh" parts in the character
local head = character:FindFirstChild("head")
local expressionsFolder = head and head:FindFirstChild("expressions")
local laughExpression = expressionsFolder and expressionsFolder:FindFirstChild("laugh")

-- Function to show the laugh expression (make laugh parts visible)
local function showLaughExpression()
	if laughExpression then
		-- Loop through all the parts inside the "Laugh" folder
		for _, part in ipairs(laughExpression:GetChildren()) do
			if part:IsA("BasePart") then
				part.Transparency = 0  -- Make parts visible
				part.CanCollide = false -- Prevent collision during the expression
				part.Anchored = false    -- Keep the parts anchored (if necessary)
			end
		end
	end
end

-- Function to hide the laugh expression (make laugh parts invisible)
local function hideLaughExpression()
	if laughExpression then
		-- Loop through all the parts inside the "Laugh" folder
		for _, part in ipairs(laughExpression:GetChildren()) do
			if part:IsA("BasePart") then
				part.Transparency = 1  -- Make parts invisible again
				part.CanCollide = true -- Allow collision again (if necessary)
				part.Anchored = false  -- Unanchor if needed (for movement)
			end
		end
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

			-- Show the laugh expression when the animation starts
			showLaughExpression()

			-- Play the laugh animation locally
			local playAnim = humanoid:LoadAnimation(anim)
			playAnim:Play()

			-- Tell the server to play the sound (via RemoteEvent)
			if tauntEvent then
				tauntEvent:FireServer()  -- Trigger the sound to play on the server side
			end

			-- Revert to normal eyes and stop the animation after it ends
			wait(2.4) -- Adjust this time to match the length of your animation
			playAnim:Stop()
			hideLaughExpression()

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
