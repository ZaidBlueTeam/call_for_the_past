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
anim.AnimationId = "rbxassetid://139232083405223" -- EXE laugh animation ID

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

			-- Show EXE eyes and black out the white eye part when the animation starts
			showExeEyes()

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
				wait(2) -- Adjust this time to match the length of your animation

				-- Stop animation and revert eyes
				if playAnim.IsPlaying then
					playAnim:Stop()
				end
				revertToNormalEyes()
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
	normalEyes = head and head:FindFirstChild("eyes")
	normalPupil1 = normalEyes and normalEyes:FindFirstChild("pupil1")
	normalPupil2 = normalEyes and normalEyes:FindFirstChild("pupil2")

	exeEyes = head and head:FindFirstChild("exeEye")
	exeEye1 = exeEyes and exeEyes:FindFirstChild("exeEye1")
	exeEye2 = exeEyes and exeEyes:FindFirstChild("exeEye2")

	whiteEye = normalEyes and normalEyes:FindFirstChild("eyes")

	-- Reset states
	canTrigger = true
	lastLaughTime = 0
end)

print("Laugh script (version 3 - EXE Eyes) loaded! Press Q to laugh.")

-- Controller support for Laugh/Taunt (without using mouse)
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.ButtonY and canTrigger then -- Y button
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