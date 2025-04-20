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

-- Find the "Tired" part in the character
local head = character:FindFirstChild("head")
local expressionsFolder = head and head:FindFirstChild("expressions")
local tiredEyesFolder = expressionsFolder and expressionsFolder:FindFirstChild("tired_eyes")
local tiredPart = tiredEyesFolder and tiredEyesFolder:FindFirstChild("tired")

-- Function to show the tired part (make it visible)
local function showTiredPart()
	if tiredPart then
		-- Make the 'tired' part visible
		tiredPart.Transparency = 0  -- Make the part visible
		tiredPart.CanCollide = false -- Prevent collision during the expression
		tiredPart.Anchored = false   -- Keep the part anchored (if necessary)
	end
end

-- Function to hide the tired part (make it invisible)
local function hideTiredPart()
	if tiredPart then
		-- Make the 'tired' part invisible again
		tiredPart.Transparency = 1  -- Make the part invisible
		tiredPart.CanCollide = false -- Keep collision off
		tiredPart.Anchored = false  -- Unanchor if needed (for movement)
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
local lastTauntTime = 0 -- Last time the laugh animation was triggered

-- Flag to prevent spamming
local canTrigger = true

-- Detect the key press and play the animation with cooldown
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Q and canTrigger then
		local currentTime = tick()
		if currentTime - lastTauntTime >= cooldownTime then
			-- Prevent further triggering of the animation
			canTrigger = false

			-- Setup laugh sound
			local laughSound = setupLaughSound()

			-- Show the tired part when the animation starts
			showTiredPart()

			-- Play the laugh animation locally
			local playAnim = humanoid:LoadAnimation(anim)
			playAnim:Play()

			-- Tell the server to play the sound (via RemoteEvent)
			tauntEvent:FireServer()

			-- Update the last taunt time to the current time
			lastTauntTime = currentTime

			-- Create a separate thread for animation cleanup
			task.spawn(function()
				-- Wait for animation to complete
				wait(3.3) -- Adjust this time to match the length of your animation

				-- Stop animation and hide tired part
				if playAnim.IsPlaying then
					playAnim:Stop()
				end
				hideTiredPart()
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
			local remainingCooldown = cooldownTime - (currentTime - lastTauntTime)
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
	tiredEyesFolder = expressionsFolder and expressionsFolder:FindFirstChild("tired_eyes")
	tiredPart = tiredEyesFolder and tiredEyesFolder:FindFirstChild("tired")

	-- Reset states
	canTrigger = true
	lastTauntTime = 0
end)

print("Laugh script (version 4 - Tired Eyes) loaded! Press Q to laugh.")

-- Controller support for Laugh/Taunt (without using mouse)
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.ButtonY and canTrigger then -- Y button
		local currentTime = tick()
		if currentTime - lastTauntTime >= cooldownTime then
			-- Prevent further triggering of the animation
			canTrigger = false

			-- Show the tired part when the animation starts
			showTiredPart()

			-- Play the laugh animation locally
			local playAnim = humanoid:LoadAnimation(anim)
			playAnim:Play()

			-- Tell the server to play the sound (via RemoteEvent)
			if tauntEvent then
				tauntEvent:FireServer()  -- Trigger the sound to play on the server side
			end

			-- Revert to normal eyes and stop the animation after it ends
			wait(3.3) -- Adjust this time to match the length of your animation
			playAnim:Stop()
			hideTiredPart()

			-- Update the last taunt time to the current time
			lastTauntTime = currentTime

			-- Re-enable triggering after cooldown
			wait(cooldownTime)
			canTrigger = true
		else
			-- Notify the player that they need to wait before laughing again
			local remainingCooldown = cooldownTime - (currentTime - lastTauntTime)
			print("Please wait " .. math.ceil(remainingCooldown) .. " more seconds before laughing again.")
		end
	end
end)