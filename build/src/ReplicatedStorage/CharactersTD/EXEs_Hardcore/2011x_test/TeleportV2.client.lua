-- Simplified Teleport Points Ability Script
-- Press X to place a teleport point (up to 3)
-- Press 1, 2, or 3 to teleport to the corresponding point
-- Includes animation and localized sound effects

-- Configuration
local PLACEMENT_KEY = Enum.KeyCode.X -- Key to place teleport points
local MAX_TELEPORT_POINTS = 4 -- Maximum number of teleport points
local SOUND_RADIUS = 30 -- How far the teleport sound can be heard (in studs)
local COOLDOWN_DURATION = 5 -- Cooldown between teleports (in seconds)

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local teleportPoints = {}
local teleportMarkers = {}
local currentPointIndex = 1 -- Start with point 1
local cooldownActive = false
local markersFolder

-- Function to get or create markers folder
local function getMarkersFolder()
	if not markersFolder or not markersFolder.Parent then
		markersFolder = Instance.new("Folder")
		markersFolder.Name = "TeleportMarkers_" .. player.UserId
		markersFolder.Parent = workspace
	end
	return markersFolder
end

-- Clean up all teleport markers
local function cleanupAllMarkers()
	-- Clear tracked markers in our table
	for _, marker in pairs(teleportMarkers) do
		if marker and marker.Parent then
			marker:Destroy()
		end
	end
	teleportMarkers = {}

	-- Clean up markers folder
	if markersFolder and markersFolder.Parent then
		markersFolder:Destroy()
		markersFolder = nil
	end

	print("All teleport markers cleaned up")
end

-- Create animation object for teleportation
local function setupTeleportAnimation()
	-- Create animation instance
	local teleportAnim = Instance.new("Animation")
	teleportAnim.AnimationId = "rbxassetid://103055532252719" -- Ninja Dash animation

	-- Load the animation
	local animTrack = humanoid:LoadAnimation(teleportAnim)
	animTrack.Priority = Enum.AnimationPriority.Action
	animTrack.Looped = false

	return animTrack
end

local teleportAnimation = setupTeleportAnimation()

-- Create teleport point markers
local function createTeleportMarker(position, pointNumber)
	-- Create the marker part
	local marker = Instance.new("Part")
	marker.Size = Vector3.new(1, 3, 1)
	marker.Anchored = true
	marker.CanCollide = false
	marker.Material = Enum.Material.Neon
	marker.BrickColor = BrickColor.new("Bright blue")
	marker.Transparency = 0.5
	marker.Position = position + Vector3.new(0, 1.5, 0) -- Slightly above ground
	marker.Name = "TeleportMarker_" .. pointNumber

	-- Add to our folder
	marker.Parent = getMarkersFolder()

	-- Add number label
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 70, 0, 70)
	billboard.Adornee = marker
	billboard.AlwaysOnTop = true
	billboard.Parent = marker

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 24
	textLabel.Text = "Teleport\nPoint " .. pointNumber
	textLabel.Parent = billboard

	-- Add pulsing effect
	local function pulseMarker()
		while marker and marker.Parent do
			for i = 0, 1, 0.05 do
				if not marker or not marker.Parent then break end
				marker.Transparency = 0.3 + (i * 0.4)
				task.wait(0.05)
			end
			for i = 1, 0, -0.05 do
				if not marker or not marker.Parent then break end
				marker.Transparency = 0.3 + (i * 0.4)
				task.wait(0.05)
			end
		end
	end

	task.spawn(pulseMarker)

	return marker
end

-- Create a sound effect for teleportation
local function createTeleportSound()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://4844057081" -- Teleport whoosh sound
	sound.Volume = 1.0
	sound.RollOffMinDistance = 5
	sound.RollOffMaxDistance = SOUND_RADIUS
	sound.RollOffMode = Enum.RollOffMode.LinearSquare

	return sound
end

-- Function to place a teleport point
local function placeTeleportPoint()
	-- Check if character exists
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local position = character.HumanoidRootPart.Position
	print("Setting teleport point " .. currentPointIndex .. " at " .. tostring(position))

	-- Remove old marker if it exists
	if teleportMarkers[currentPointIndex] and teleportMarkers[currentPointIndex].Parent then
		teleportMarkers[currentPointIndex]:Destroy()
	end

	-- Save the position and create marker
	teleportPoints[currentPointIndex] = position
	teleportMarkers[currentPointIndex] = createTeleportMarker(position, currentPointIndex)

	-- Provide feedback
	local notification = Instance.new("ScreenGui")
	notification.Name = "TeleportNotification"

	local notificationText = Instance.new("TextLabel")
	notificationText.Size = UDim2.new(0, 250, 0, 50)
	notificationText.Position = UDim2.new(0.5, -125, 0.2, 0)
	notificationText.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
	notificationText.BackgroundTransparency = 0.3
	notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
	notificationText.Font = Enum.Font.GothamBold
	notificationText.TextSize = 18
	notificationText.Text = "Teleport Point " .. currentPointIndex .. " Set!"
	notificationText.Parent = notification

	notification.Parent = player.PlayerGui

	-- Remove notification after 1.5 seconds
	task.delay(1.5, function()
		if notification and notification.Parent then
			notification:Destroy()
		end
	end)

	-- Move to next point index (cycling through 1-3)
	currentPointIndex = (currentPointIndex % MAX_TELEPORT_POINTS) + 1
end

-- Function to teleport to a saved point
local function teleportToPoint(pointIndex)
	print("Attempting to teleport to point " .. pointIndex)

	-- Check for cooldown
	if cooldownActive then
		print("Teleport failed: Cooldown active")

		-- Provide feedback about cooldown
		local notification = Instance.new("ScreenGui")
		notification.Name = "CooldownNotification"

		local notificationText = Instance.new("TextLabel")
		notificationText.Size = UDim2.new(0, 250, 0, 50)
		notificationText.Position = UDim2.new(0.5, -125, 0.2, 0)
		notificationText.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		notificationText.BackgroundTransparency = 0.3
		notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
		notificationText.Font = Enum.Font.GothamBold
		notificationText.TextSize = 18
		notificationText.Text = "Teleport on cooldown!"
		notificationText.Parent = notification

		notification.Parent = player.PlayerGui

		-- Remove notification after 1 second
		task.delay(1, function()
			if notification and notification.Parent then
				notification:Destroy()
			end
		end)

		return
	end

	-- Check if point exists
	if not teleportPoints[pointIndex] then
		print("Teleport failed: Point " .. pointIndex .. " not set")

		-- Provide feedback that point doesn't exist
		local notification = Instance.new("ScreenGui")
		notification.Name = "TeleportNotification"

		local notificationText = Instance.new("TextLabel")
		notificationText.Size = UDim2.new(0, 250, 0, 50)
		notificationText.Position = UDim2.new(0.5, -125, 0.2, 0)
		notificationText.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
		notificationText.BackgroundTransparency = 0.3
		notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
		notificationText.Font = Enum.Font.GothamBold
		notificationText.TextSize = 18
		notificationText.Text = "Teleport Point " .. pointIndex .. " not set!"
		notificationText.Parent = notification

		notification.Parent = player.PlayerGui

		-- Remove notification after 1.5 seconds
		task.delay(1.5, function()
			if notification and notification.Parent then
				notification:Destroy()
			end
		end)

		return
	end

	-- Check if character exists
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	-- Activate cooldown
	cooldownActive = true
	print("Teleporting to position: " .. tostring(teleportPoints[pointIndex]))

	-- TEST: Try to make the character jump to confirm animation system is working
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	-- Play teleport animation with more debugging
	if teleportAnimation then
		print("Attempting to play teleport animation")

		local success, message = pcall(function()
			teleportAnimation:Play()
			return "Animation played successfully"
		end)

		if not success then
			print("Failed to play animation: " .. tostring(message))
		else
			print(message)
		end
	else
		print("Teleport animation is nil")
	end

	-- Create and play teleport sound
	local teleportSound = createTeleportSound()
	teleportSound.Parent = character.HumanoidRootPart
	teleportSound:Play()

	-- Create teleport effect
	local effect = Instance.new("Part")
	effect.Shape = Enum.PartType.Ball
	effect.Size = Vector3.new(5, 5, 5)
	effect.Material = Enum.Material.ForceField
	effect.BrickColor = BrickColor.new("Bright blue")
	effect.CanCollide = false
	effect.Anchored = true
	effect.CFrame = CFrame.new(character.HumanoidRootPart.Position)
	effect.Transparency = 0.3
	effect.Parent = workspace

	-- Animate and remove teleport effect
	task.spawn(function()
		for i = 1, 10 do
			if effect and effect.Parent then
				effect.Size = Vector3.new(5 - i/2, 5 - i/2, 5 - i/2)
				effect.Transparency = 0.3 + (i * 0.07)
			end
			task.wait(0.03)
		end
		if effect and effect.Parent then
			effect:Destroy()
		end
	end)

	-- Teleport after a short delay (for effect)
	task.delay(0.3, function()
		-- Perform the actual teleport
		if character and character:FindFirstChild("HumanoidRootPart") then
			character.HumanoidRootPart.CFrame = CFrame.new(teleportPoints[pointIndex])
		end

		-- Create arrival effect
		local arrivalEffect = Instance.new("Part")
		arrivalEffect.Shape = Enum.PartType.Ball
		arrivalEffect.Size = Vector3.new(1, 1, 1)
		arrivalEffect.Material = Enum.Material.Neon
		arrivalEffect.BrickColor = BrickColor.new("Bright blue")
		arrivalEffect.CanCollide = false
		arrivalEffect.Anchored = true
		arrivalEffect.CFrame = CFrame.new(teleportPoints[pointIndex])
		arrivalEffect.Transparency = 0.3
		arrivalEffect.Parent = workspace

		-- Create and play arrival sound
		local arrivalSound = createTeleportSound()
		arrivalSound.Parent = character.HumanoidRootPart
		arrivalSound:Play()

		-- Animate and remove arrival effect
		for i = 1, 10 do
			arrivalEffect.Size = Vector3.new(i/2, i/2, i/2)
			arrivalEffect.Transparency = 0.3 + (i * 0.07)
			task.wait(0.03)
		end
		arrivalEffect:Destroy()

		-- Add cooldown visual indication
		local cooldownGui = Instance.new("ScreenGui")
		cooldownGui.Name = "TeleportCooldownGui"

		local cooldownFrame = Instance.new("Frame")
		cooldownFrame.Size = UDim2.new(0, 200, 0, 30)
		cooldownFrame.Position = UDim2.new(0.5, -100, 0.9, -30)
		cooldownFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		cooldownFrame.BackgroundTransparency = 0.5
		cooldownFrame.BorderColor3 = Color3.fromRGB(0, 162, 255)
		cooldownFrame.Parent = cooldownGui

		local cooldownText = Instance.new("TextLabel")
		cooldownText.Size = UDim2.new(1, 0, 1, 0)
		cooldownText.BackgroundTransparency = 1
		cooldownText.TextColor3 = Color3.fromRGB(255, 255, 255)
		cooldownText.Font = Enum.Font.GothamBold
		cooldownText.TextSize = 16
		cooldownText.Text = "Teleport Cooldown: " .. COOLDOWN_DURATION .. "s"
		cooldownText.Parent = cooldownFrame

		cooldownGui.Parent = player.PlayerGui

		-- Cooldown timer
		local timeLeft = COOLDOWN_DURATION
		local connection
		connection = RunService.Heartbeat:Connect(function(deltaTime)
			timeLeft = timeLeft - deltaTime

			-- Update cooldown text
			if cooldownText and cooldownText.Parent then
				local displayTime = math.max(0, math.ceil(timeLeft))
				cooldownText.Text = "Teleport Cooldown: " .. displayTime .. "s"
			end

			-- End cooldown
			if timeLeft <= 0 then
				cooldownActive = false

				if connection then
					connection:Disconnect()
				end

				if cooldownGui and cooldownGui.Parent then
					cooldownGui:Destroy()
				end
			end
		end)
	end)
end

-- Setup death detection
local function setupDeathDetection()
	if not character or not character:FindFirstChild("Humanoid") then return end

	local deathConnection
	deathConnection = character.Humanoid.Died:Connect(function()
		print("Player died - cleaning up markers")
		cleanupAllMarkers()

		-- Clear teleport points
		teleportPoints = {}
		currentPointIndex = 1

		-- Disconnect after death
		if deathConnection then
			deathConnection:Disconnect()
		end
	end)
end

-- Handle character respawning
local function onCharacterAdded(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	print("Character respawned - clearing old teleport points")

	-- Reset teleport points
	teleportPoints = {}

	-- Clean up all markers
	cleanupAllMarkers()

	-- Reset variables
	currentPointIndex = 1
	cooldownActive = false

	-- Remove any cooldown GUI
	local existingCooldownGui = player.PlayerGui:FindFirstChild("TeleportCooldownGui")
	if existingCooldownGui then
		existingCooldownGui:Destroy()
	end

	-- Reload teleport animation with delay to make sure humanoid is fully loaded
	task.delay(1, function()
		print("Loading teleport animation after character respawn")
		teleportAnimation = setupTeleportAnimation()
	end)

	-- Setup death detection
	setupDeathDetection()

	-- Notify player
	local notification = Instance.new("ScreenGui")
	notification.Name = "ResetNotification"

	local notificationText = Instance.new("TextLabel")
	notificationText.Size = UDim2.new(0, 300, 0, 50)
	notificationText.Position = UDim2.new(0.5, -150, 0.2, 0)
	notificationText.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
	notificationText.BackgroundTransparency = 0.3
	notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
	notificationText.Font = Enum.Font.GothamBold
	notificationText.TextSize = 18
	notificationText.Text = "Teleport points have been reset"
	notificationText.Parent = notification

	notification.Parent = player.PlayerGui

	-- Remove notification after 2 seconds
	task.delay(2, function()
		if notification and notification.Parent then
			notification:Destroy()
		end
	end)
end

-- Connect character added event
player.CharacterAdded:Connect(onCharacterAdded)

-- Handle key presses
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Place teleport point with X
	if input.KeyCode == PLACEMENT_KEY then
		print("X key pressed - placing teleport point")
		placeTeleportPoint()
		-- Teleport with 1, 2, 3
	elseif input.KeyCode == Enum.KeyCode.One or 
		input.KeyCode == Enum.KeyCode.Two or 
		input.KeyCode == Enum.KeyCode.Three then

		local pointIndex = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
		print("Number " .. pointIndex .. " key pressed - attempting teleport")

		if pointIndex <= MAX_TELEPORT_POINTS then
			teleportToPoint(pointIndex)
		end
	end
end)

-- Load animation
local teleportAnimation = setupTeleportAnimation()

-- Run initial setup
task.spawn(function()
	-- Clean up any existing markers
	cleanupAllMarkers()

	-- Setup death detection for initial character
	setupDeathDetection()

	-- Show initialization message
	print("Teleport script loaded! Press X to set points, 1-3 to teleport")
end)

print("Simplified Teleport Script Loaded!")
print("Press X to place teleport points")
print("Press 1-4 to teleport to saved points")

-- Controller support for Teleport Points
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	-- Teleport to points with D-Pad
	if input.KeyCode == Enum.KeyCode.DPadUp then
		teleportToPoint(1)
	elseif input.KeyCode == Enum.KeyCode.DPadLeft then
		teleportToPoint(2)
	elseif input.KeyCode == Enum.KeyCode.DPadDown then
		teleportToPoint(3)
	elseif input.KeyCode == Enum.KeyCode.DPadRight then
		teleportToPoint(4)
	end

	-- B button (secondary option) to place teleport point
	if input.KeyCode == Enum.KeyCode.ButtonB and player.Team and player.Team.Name ~= "Survivor" then
		placeTeleportPoint()
	end
end)