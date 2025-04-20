-- Minion Attack Local Script (No Chase Music)
-- Place this in the minion character model

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Get or create RemoteEvents
local MinionAttackEvent = ReplicatedStorage:FindFirstChild("MinionAttackEvent")
if not MinionAttackEvent then
	MinionAttackEvent = Instance.new("RemoteEvent")
	MinionAttackEvent.Name = "MinionAttackEvent"
	MinionAttackEvent.Parent = ReplicatedStorage
end

-- Create reset event
local MinionResetEvent = ReplicatedStorage:FindFirstChild("MinionResetEvent")
if not MinionResetEvent then
	MinionResetEvent = Instance.new("RemoteEvent")
	MinionResetEvent.Name = "MinionResetEvent"
	MinionResetEvent.Parent = ReplicatedStorage
end

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

-- Configuration
local ATTACK_HOLD_MAX = 0.1     -- Max time you can hold attack
local ATTACK_COOLDOWN = 1.1     -- Cooldown between attacks
local LUNGE_SPEED_BOOST = 10    -- Speed boost during lunge
local LUNGE_DURATION = 0.1      -- How long the lunge lasts
local FREEZE_TIME_POSITION = 0.3 -- Time position when animation freezes
local DEBUG_MODE = true         -- Enable debug messages

-- Attack animation
local attackAnim = Instance.new("Animation")
attackAnim.AnimationId = "rbxassetid://88785427345398" -- Attack animation

-- Attack sound effects
local swingSound = Instance.new("Sound")
swingSound.SoundId = "rbxassetid://5789650122" -- Swing sound
swingSound.Volume = 0.8
swingSound.Parent = char:WaitForChild("HumanoidRootPart")

-- Attack state variables
local isAttacking = false
local holdingAttack = false
local onCooldown = false
local attackStartTime = 0
local animTrack = nil
local countdownConnection = nil
local cooldownIndicator = nil
local resetRequested = false

-- Print debug messages
local function debugPrint(message)
	if DEBUG_MODE then
		print("[MINION ATTACK] " .. message)
	end
end

-- Function to reset the attack system
local function resetAttackSystem()
	-- Reset attack state variables 
	isAttacking = false
	holdingAttack = false
	onCooldown = false
	attackStartTime = 0

	-- Reset humanoid speed if it was changed
	if humanoid and humanoid.Parent then
		-- Option: Reset to default speed if needed
		-- humanoid.WalkSpeed = DEFAULT_WALK_SPEED
	end

	-- Stop any existing animation
	if animTrack and animTrack.IsPlaying then
		animTrack:Stop()
	end
	animTrack = nil

	-- Clear any cooldown UI and connections
	if countdownConnection then
		countdownConnection:Disconnect()
		countdownConnection = nil
	end

	if cooldownIndicator and cooldownIndicator.Parent then
		cooldownIndicator:Destroy()
		cooldownIndicator = nil
	end

	-- Request reset from server
	if not resetRequested then
		resetRequested = true
		MinionAttackEvent:FireServer("RequestReset")

		-- Reset flag after delay to prevent spam
		task.delay(0.2, function()
			resetRequested = false
		end)
	end

	debugPrint("ATTACK SYSTEM RESET")
end

-- Handle invincibility clearing
MinionResetEvent.OnClientEvent:Connect(function(action)
	if action == "ResetAttack" then
		resetAttackSystem()
		debugPrint("Attack reset by server")
	end
end)

-- Function to handle response from server
local function handleServerResponse(responseType)
	if responseType == "Hit" then
		-- Play hit sound
		local hitSound = Instance.new("Sound")
		hitSound.SoundId = "rbxassetid://6361963422" -- Hit sound
		hitSound.Volume = 1
		hitSound.Parent = char:WaitForChild("HumanoidRootPart")
		hitSound:Play()
		game.Debris:AddItem(hitSound, 2)

	elseif responseType == "Swing" then
		-- Play swing sound
		if swingSound then
			swingSound:Play()
		end

	elseif responseType == "AttackReset" then
		-- Server confirms our attack has been reset
		debugPrint("Server confirmed attack reset")

		-- Reset attacking state
		isAttacking = false
		holdingAttack = false
		onCooldown = false

		if countdownConnection then
			countdownConnection:Disconnect()
			countdownConnection = nil
		end
	end
end

-- Connect to server responses
MinionAttackEvent.OnClientEvent:Connect(handleServerResponse)

-- Clean up cooldown resources
local function cleanupCooldown()
	if countdownConnection then
		countdownConnection:Disconnect()
		countdownConnection = nil
	end

	if cooldownIndicator and cooldownIndicator.Parent then
		cooldownIndicator:Destroy()
		cooldownIndicator = nil
	end
end

-- Function to create the cooldown indicator
local function createCooldownIndicator()
	-- Clean up any existing cooldown UI
	cleanupCooldown()

	-- Create new cooldown indicator
	cooldownIndicator = Instance.new("ScreenGui")
	cooldownIndicator.Name = "MinionAttackCooldown"

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 30)
	frame.Position = UDim2.new(0.5, -100, 0.9, -30)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = cooldownIndicator

	-- Add rounded corners
	local cornerRadius = Instance.new("UICorner")
	cornerRadius.CornerRadius = UDim.new(0, 8)
	cornerRadius.Parent = frame

	local text = Instance.new("TextLabel")
	text.Name = "CooldownText"
	text.Text = "Attack Cooldown: " .. ATTACK_COOLDOWN .. "s"
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 16
	text.Parent = frame

	cooldownIndicator.Parent = player.PlayerGui

	return text
end

-- Function for attack release cooldown
local function startCooldown()
	-- Set cooldown
	onCooldown = true

	-- Create and show cooldown indicator
	local cooldownText = createCooldownIndicator()

	-- Countdown timer for cooldown
	local timeLeft = ATTACK_COOLDOWN
	countdownConnection = RunService.Heartbeat:Connect(function(deltaTime)
		timeLeft = timeLeft - deltaTime

		if timeLeft <= 0 then
			-- Reset the attack system at end of cooldown
			resetAttackSystem()

			-- Destroy the countdown connection
			if countdownConnection then
				countdownConnection:Disconnect()
				countdownConnection = nil
			end
		elseif cooldownText and cooldownText.Parent then
			cooldownText.Text = "Attack Cooldown: " .. math.ceil(timeLeft) .. "s"
		end
	end)
end

-- Start attack function
local function startAttack()
	-- Don't allow attack if already attacking or on cooldown
	if isAttacking or onCooldown then 
		debugPrint("Attack blocked - already attacking or on cooldown")
		return 
	end

	-- Set attack state
	isAttacking = true
	holdingAttack = true
	attackStartTime = tick()

	debugPrint("Attack started")

	-- Play attack animation
	if animTrack then
		animTrack:Stop()
	end

	animTrack = humanoid:LoadAnimation(attackAnim)
	animTrack:Play()

	-- Lunge effect - temporary speed boost
	local originalSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = originalSpeed + LUNGE_SPEED_BOOST

	-- Restore original speed after lunge duration
	task.delay(LUNGE_DURATION, function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = originalSpeed
		end
	end)

	-- Freeze animation at charging position if still holding
	task.delay(FREEZE_TIME_POSITION, function()
		if holdingAttack and animTrack and animTrack.IsPlaying then
			animTrack.TimePosition = FREEZE_TIME_POSITION
			animTrack:AdjustSpeed(0)
		end
	end)

	-- Tell server we started attack
	MinionAttackEvent:FireServer("Start")
end

-- Release attack function
local function releaseAttack()
	if not holdingAttack then return end
	holdingAttack = false

	debugPrint("Attack released")

	-- Resume animation if it was frozen
	if animTrack and animTrack.IsPlaying then
		animTrack:AdjustSpeed(1)
	end

	-- Fire attack event to server
	MinionAttackEvent:FireServer("Release")

	-- Start cooldown
	startCooldown()
end

-- Check if input is an attack input
local function isAttackInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or
		input.KeyCode == Enum.KeyCode.F or
		input.KeyCode == Enum.KeyCode.ButtonR2
end

-- Auto-release after max hold time
local function checkAutoRelease()
	if holdingAttack and tick() - attackStartTime >= ATTACK_HOLD_MAX then
		debugPrint("Auto-releasing attack after max hold time")
		releaseAttack()
	end
end

-- Monitor character state
local function setupCharacterStateMonitoring()
	-- Check if character is stunned or dead and reset attack if needed
	local statusCheckConnection = nil

	statusCheckConnection = RunService.Heartbeat:Connect(function()
		-- Skip frequent checks to save performance
		task.wait(0.5)

		if not char or not humanoid then
			if statusCheckConnection then
				statusCheckConnection:Disconnect()
			end
			return
		end

		-- Reset attack if character is stunned
		if char:GetAttribute("Stunned") and (isAttacking or holdingAttack or onCooldown) then
			debugPrint("Character stunned - resetting attack")
			resetAttackSystem()
		end

		-- Reset attack if character is dead
		if humanoid.Health <= 0 and (isAttacking or holdingAttack or onCooldown) then
			debugPrint("Character died - resetting attack")
			resetAttackSystem()
		end

		-- Reset attack if character becomes invisible
		if char:GetAttribute("Invisible") and (isAttacking or holdingAttack) then
			debugPrint("Character invisible - resetting attack")
			resetAttackSystem()
		end
	end)

	return statusCheckConnection
end

-- Handle character respawn
local function setupCharacterHandling()
	local stateConnection = nil

	player.CharacterAdded:Connect(function(newChar)
		-- Clean up existing connections
		if stateConnection then
			stateConnection:Disconnect()
			stateConnection = nil
		end

		char = newChar
		humanoid = char:WaitForChild("Humanoid")

		-- Reset attack system on character change
		resetAttackSystem()

		-- Reattach sounds
		swingSound.Parent = char:WaitForChild("HumanoidRootPart")

		-- Setup new monitoring
		stateConnection = setupCharacterStateMonitoring()

		debugPrint("Character respawned - attack system reset")
	end)

	-- Setup initial monitoring
	stateConnection = setupCharacterStateMonitoring()

	-- Setup death handling
	if humanoid then
		humanoid.Died:Connect(function()
			debugPrint("Character died")
			resetAttackSystem()
		end)
	end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Check for attack inputs (Mouse1, F key, or R2 button for controllers)
	if isAttackInput(input) then
		debugPrint("Attack input detected: " .. tostring(input.KeyCode))
		startAttack()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Check for attack inputs
	if isAttackInput(input) then
		releaseAttack()
	end
end)

-- Connect auto-release checker to heartbeat
RunService.Heartbeat:Connect(checkAutoRelease)

-- Initialize all the needed monitoring systems
setupCharacterHandling()

-- Reset attack system on script load
resetAttackSystem()

-- Enable gamepad input
UserInputService.GamepadEnabled = true

print("Minion Attack Script loaded! This is a simplified version with no chase music functionality.")