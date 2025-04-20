local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
repeat wait() until player.Character and player.Character:FindFirstChild("Humanoid")

local character = player.Character
local humanoid = character:FindFirstChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- Create or get the remote event for laugh/taunt
local tauntEvent = ReplicatedStorage:FindFirstChild("TauntEvent")
if not tauntEvent then
	tauntEvent = Instance.new("RemoteEvent")
	tauntEvent.Name = "TauntEvent"
	tauntEvent.Parent = ReplicatedStorage
end

-- Define the laugh animation ID
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://111233933866620" -- Your laugh animation ID

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
				part.Anchored = false   -- Keep the parts anchored (if necessary)
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
				part.CanCollide = false -- Keep collision off
				part.Anchored = false  -- Unanchor if needed (for movement)
			end
		end
	end
end

-- Setup or get laugh sound
local function setupLaughSound()
	local laughSound = character:FindFirstChild("Laugh")
	if not laughSound then
		-- Create laugh sound if it doesn't exist
		laughSound = Instance.new("Sound")
		laughSound.Name = "Laugh"
		laughSound.SoundId = "rbxassetid://0" -- Replace with your laugh sound ID
		laughSound.Volume = 1
		laughSound.RollOffMode = Enum.RollOffMode.InverseTapered
		laughSound.RollOffMaxDistance = 60
		laughSound.RollOffMinDistance = 10
		laughSound.EmitterSize = 5
		laughSound.Parent = rootPart -- Attach to HumanoidRootPart to follow player
	else
		-- Update existing sound to ensure it's properly configured
		laughSound.RollOffMode = Enum.RollOffMode.InverseTapered
		laughSound.RollOffMaxDistance = 60
		laughSound.RollOffMinDistance = 10
		laughSound.EmitterSize = 5

		-- Move sound to HumanoidRootPart if it's not already there
		if laughSound.Parent ~= rootPart then
			laughSound.Parent = rootPart
		end
	end

	return laughSound
end

-- Cooldown logic
local cooldownTime = 5 -- Cooldown in seconds
local lastLaughTime = 0 -- Last time the laugh animation was triggered

-- Flag to prevent spamming
local canTrigger = true

-- Detect the key press and play the animation with cooldown
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Q and canTrigger then
		local currentTime = tick()
		if currentTime - lastLaughTime >= cooldownTime then
			-- Prevent further triggering of the animation
			canTrigger = false

			-- Setup laugh sound
			local laughSound = setupLaughSound()

			-- Show the laugh expression when the animation starts
			showLaughExpression()

			-- Play the laugh animation locally
			local playAnim = humanoid:LoadAnimation(anim)
			playAnim:Play()

			-- Tell the server to play the sound (via RemoteEvent)
			tauntEvent:FireServer()

			-- Update the last laugh time to the current time
			lastLaughTime = currentTime

			-- Create a separate thread for animation cleanup
			task.spawn(function()
				-- Wait for animation to complete
				wait(1.8) -- Adjust this time to match the length of your animation

				-- Stop animation and hide expression
				if playAnim.IsPlaying then
					playAnim:Stop()
				end
				hideLaughExpression()
			end)

			-- Create a separate thread for cooldown
			task.spawn(function()
				-- Wait for cooldown period
				wait(cooldownTime)

				-- Re-enable triggering
				canTrigger = true
				print("Laugh is ready to use again!")
			end)
		else
			-- Notify the player that they need to wait before laughing again
			local remainingCooldown = cooldownTime - (currentTime - lastLaughTime)
			print("Please wait " .. math.ceil(remainingCooldown) .. " more seconds before laughing again.")
		end
	end
end)

-- Handle character changes
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")

	head = character:FindFirstChild("head")
	expressionsFolder = head and head:FindFirstChild("expressions")
	laughExpression = expressionsFolder and expressionsFolder:FindFirstChild("laugh")

	-- Reset states
	canTrigger = true
	lastLaughTime = 0
end)

print("Laugh script (version 1) loaded! Press Q to laugh.")

-- Controller support for Laugh/Taunt
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.ButtonY and canTrigger then -- Y button
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
			wait(1.8) -- Adjust this time to match the length of your animation
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