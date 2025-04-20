-- Fixed Attack Local Script
-- Resolves issue where attacks stop working after first hit

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Get or create RemoteEvents
local AttackEvent = ReplicatedStorage:FindFirstChild("AttackEvent")
if not AttackEvent then
	AttackEvent = Instance.new("RemoteEvent")
	AttackEvent.Name = "AttackEvent"
	AttackEvent.Parent = ReplicatedStorage
end

-- Create reset event
local AttackResetEvent = ReplicatedStorage:FindFirstChild("AttackResetEvent")
if not AttackResetEvent then
	AttackResetEvent = Instance.new("RemoteEvent")
	AttackResetEvent.Name = "AttackResetEvent"
	AttackResetEvent.Parent = ReplicatedStorage
end

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

-- Configuration
local ATTACK_HOLD_MAX = 1.5     -- Max time you can hold attack
local ATTACK_COOLDOWN = 1.2     -- Cooldown between attacks
local LUNGE_SPEED_BOOST = 10    -- Speed boost during lunge
local LUNGE_DURATION = 0.5      -- How long the lunge lasts
local FREEZE_TIME_POSITION = 0.3 -- Time position when animation freezes
local CHASE_MUSIC_VOLUME = 0.7  -- Volume for chase music
local MUSIC_FADE_TIME = 1.5     -- Seconds for music fades
local DEBUG_MODE = true         -- Enable debug messages

-- Attack animation
local attackAnim = Instance.new("Animation")
attackAnim.AnimationId = "rbxassetid://84829499445604" -- EXE attack animation

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
		print("[ATTACK SYSTEM] " .. message)
	end
end

-- Chase music state variables
local isChaseActive = false
local chaseMusic = nil
local originalBackgroundVolumes = {}
local currentTweens = {}

-- Setup chase music container
local function setupChaseMusicSystem()
	local soundFolder = player:FindFirstChild("ChaseMusicSystem")
	if not soundFolder then
		soundFolder = Instance.new("Folder")
		soundFolder.Name = "ChaseMusicSystem"
		soundFolder.Parent = player
	end
	return soundFolder
end

local soundFolder = setupChaseMusicSystem()

-- Find background music sounds
local function findBackgroundMusic()
	local backgroundSounds = {}

	-- Check SoundService for background music
	for _, sound in pairs(SoundService:GetDescendants()) do
		if sound:IsA("Sound") and 
			sound.Name:match("Music") and
			sound ~= chaseMusic and
			sound.Playing then
			table.insert(backgroundSounds, sound)
		end
	end

	-- Check workspace for music
	for _, sound in pairs(workspace:GetDescendants()) do
		if sound:IsA("Sound") and 
			sound.Name:match("Music") and
			sound ~= chaseMusic and
			sound.Playing then
			table.insert(backgroundSounds, sound)
		end
	end

	return backgroundSounds
end

-- Cancel sound tweens
local function cancelSoundTweens(sound)
	if currentTweens[sound] then
		currentTweens[sound]:Cancel()
		currentTweens[sound] = nil
	end
end

-- Fade background music down
local function fadeBackgroundMusic()
	local backgroundSounds = findBackgroundMusic()

	for _, sound in ipairs(backgroundSounds) do
		-- Save original volume
		if not originalBackgroundVolumes[sound] then
			originalBackgroundVolumes[sound] = sound.Volume
		end

		-- Cancel existing tweens
		cancelSoundTweens(sound)

		-- Create tween to fade down
		local tween = TweenService:Create(
			sound,
			TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Quad),
			{Volume = 0}
		)

		currentTweens[sound] = tween
		tween:Play()
	end
end

-- Restore background music
local function restoreBackgroundMusic()
	for sound, originalVolume in pairs(originalBackgroundVolumes) do
		if sound and sound.Parent then
			-- Cancel existing tweens
			cancelSoundTweens(sound)

			-- Create tween to restore volume
			local tween = TweenService:Create(
				sound,
				TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Quad),
				{Volume = originalVolume}
			)

			currentTweens[sound] = tween
			tween:Play()
		end
	end

	originalBackgroundVolumes = {}
end

-- Forward declare stopChaseMusic for use in startChaseMusic
local stopChaseMusic

-- Start chase music
local function startChaseMusic(musicId)
	-- If no music ID is provided, use a default
	if not musicId then 
		musicId = "rbxassetid://1841667761" -- Default chase music
	end

	-- If chase music is already playing with the same ID, don't restart it
	if isChaseActive and chaseMusic and chaseMusic.IsPlaying and chaseMusic.SoundId == musicId then
		debugPrint("Chase music already playing - not restarting")
		return
	end

	-- Stop any existing chase music if it's different
	if isChaseActive and chaseMusic then
		-- If it's the same music ID, just make sure it's still playing
		if chaseMusic.SoundId == musicId then
			if not chaseMusic.IsPlaying then
				chaseMusic:Play()
			end
			return
		end

		-- Different music, stop the current one
		chaseMusic:Stop()
		chaseMusic:Destroy()
		chaseMusic = nil
	end

	debugPrint("Starting chase music: " .. musicId)
	isChaseActive = true

	-- Create chase music sound
	chaseMusic = Instance.new("Sound")
	chaseMusic.Name = "ChaseMusic"
	chaseMusic.SoundId = musicId
	chaseMusic.Volume = 0
	chaseMusic.Looped = true
	chaseMusic.Parent = soundFolder

	-- Fade background music
	fadeBackgroundMusic()

	-- Fade in chase music
	chaseMusic:Play()

	local tween = TweenService:Create(
		chaseMusic,
		TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Quad),
		{Volume = CHASE_MUSIC_VOLUME}
	)

	currentTweens[chaseMusic] = tween
	tween:Play()
end

-- Stop chase music function implementation
stopChaseMusic = function()
	if not isChaseActive then return end
	isChaseActive = false

	-- Restore background music
	restoreBackgroundMusic()

	-- Fade out chase music
	if chaseMusic then
		cancelSoundTweens(chaseMusic)

		local tween = TweenService:Create(
			chaseMusic,
			TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Quad),
			{Volume = 0}
		)

		tween.Completed:Connect(function()
			if chaseMusic and chaseMusic.Volume <= 0.05 then
				chaseMusic:Stop()
				chaseMusic:Destroy()
				chaseMusic = nil
			end
		end)

		currentTweens[chaseMusic] = tween
		tween:Play()
	end

	debugPrint("Stopped chase music")
end

-- IMPROVED: COMPLETE function to reset the attack system (preserves chase music)
local function resetAttackSystem(preserveChase)
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

	-- Stop chase music only if not preserving it
	if not preserveChase and isChaseActive then
		stopChaseMusic()
	end

	-- Request reset from server
	if not resetRequested then
		resetRequested = true
		AttackEvent:FireServer("RequestReset")

		-- Reset flag after delay to prevent spam
		task.delay(0.2, function()
			resetRequested = false
		end)
	end

	debugPrint("ATTACK SYSTEM RESET " .. (preserveChase and "(Chase music preserved)" or "(including chase music)"))
end

-- Handle invincibility clearing
AttackResetEvent.OnClientEvent:Connect(function(action)
	if action == "ClearInvincibility" and player.Character then
		-- Make sure we have no invincibility in case server missed it
		player.Character:SetAttribute("Invincible", false)

		-- Remove any invincibility object
		local tempInvincibility = player.Character:FindFirstChild("TempInvincibility")
		if tempInvincibility then
			tempInvincibility:Destroy()
		end

		debugPrint("Invincibility cleared by server")
	end
end)

-- Function to handle response from server
local function handleServerResponse(responseType, musicId)
	if responseType == "Hit" then
		-- Play hit sound
		local hitSound = Instance.new("Sound")
		hitSound.SoundId = "rbxassetid://6361963422" -- Hit sound
		hitSound.Volume = 1
		hitSound.Parent = char:WaitForChild("HumanoidRootPart")
		hitSound:Play()
		game.Debris:AddItem(hitSound, 2)

		-- Start chase music if EXE
		if player.Team and player.Team.Name == "EXE" and musicId then
			startChaseMusic(musicId)
		end

	elseif responseType == "Swing" then
		-- Play swing sound
		if swingSound then
			swingSound:Play()
		end

	elseif responseType == "StartChase" then
		-- Start chase music with provided ID
		startChaseMusic(musicId)

	elseif responseType == "StopChase" then
		stopChaseMusic()

	elseif responseType == "AttackReset" then
		-- Server confirms our attack has been reset
		debugPrint("Server confirmed attack reset")

		-- Only reset attacking state but preserve chase music
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
AttackEvent.OnClientEvent:Connect(handleServerResponse)

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
	cooldownIndicator.Name = "AttackCooldown"

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
			-- Reset only the attack system at end of cooldown, preserving chase music
			resetAttackSystem(true) -- true = preserve chase music

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

-- In the isAttackInput function, add cooldown check
local function isAttackInput(input)
	-- Block all attack inputs if onCooldown
	if onCooldown then
		return false
	end

	return input.UserInputType == Enum.UserInputType.MouseButton1 or
		input.KeyCode == Enum.KeyCode.F or
		input.KeyCode == Enum.KeyCode.ButtonR2
end

-- Update startAttack to double-check cooldown
local function startAttack()
	-- Double check cooldown status
	if onCooldown then
		debugPrint("Attack blocked - on cooldown")
		return
	end

	-- Don't allow attack if already attacking
	if isAttacking then 
		debugPrint("Attack blocked - already attacking")
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
	AttackEvent:FireServer("Start")
end

-- Release attack function - IMPROVED VERSION
local function releaseAttack()
	if not holdingAttack then return end
	holdingAttack = false

	debugPrint("Attack released")

	-- Resume animation if it was frozen
	if animTrack and animTrack.IsPlaying then
		animTrack:AdjustSpeed(1)
	end

	-- Fire attack event to server
	AttackEvent:FireServer("Release")

	-- Start cooldown
	startCooldown()
end

-- Auto-release after max hold time
local function checkAutoRelease()
	if holdingAttack and tick() - attackStartTime >= ATTACK_HOLD_MAX then
		debugPrint("Auto-releasing attack after max hold time")
		releaseAttack()
	end
end

-- IMPROVED: Team change monitoring to reset attack state
local function setupTeamChangeHandling()
	-- Function to handle team change
	local function onTeamChanged()
		if player.Team and player.Team.Name ~= "EXE" then
			-- If we're no longer EXE, reset everything including chase music
			resetAttackSystem(false) -- false = don't preserve chase music
		end
	end

	-- Connect to team change signal
	player:GetPropertyChangedSignal("Team"):Connect(onTeamChanged)

	-- Also check when the script loads
	if player.Team and player.Team.Name ~= "EXE" then
		stopChaseMusic()
	end
end

-- IMPROVED: Round reset detection
local function setupRoundResetDetection()
	local roundStatsEvent = ReplicatedStorage:FindFirstChild("RoundStats")
	if roundStatsEvent then
		roundStatsEvent.OnClientEvent:Connect(function(data)
			if typeof(data) == "table" and data.status then
				local statusText = data.status

				-- If a round reset message is detected
				if statusText:find("won the round") or 
					statusText:find("Round resetting") or
					statusText:find("reset") then
					debugPrint("Round reset detected: " .. statusText)

					-- Full reset including chase music
					resetAttackSystem(false) -- false = don't preserve chase music
				end
			end
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
			resetAttackSystem(true) -- Preserve chase music
		end

		-- Reset attack if character is dead
		if humanoid.Health <= 0 and (isAttacking or holdingAttack or onCooldown) then
			debugPrint("Character died - resetting attack")
			resetAttackSystem(false) -- Don't preserve chase music when dead
		end

		-- Reset attack if character becomes invisible
		if char:GetAttribute("Invisible") and (isAttacking or holdingAttack) then
			debugPrint("Character invisible - resetting attack")
			resetAttackSystem(true) -- Preserve chase music
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

		-- Reset attack system on character change, preserve chase music if possible
		resetAttackSystem(true)

		-- Reattach sounds
		swingSound.Parent = char:WaitForChild("HumanoidRootPart")

		-- Setup new monitoring
		stateConnection = setupCharacterStateMonitoring()

		debugPrint("Character respawned - attack system reset (chase preserved)")
	end)

	-- Setup initial monitoring
	stateConnection = setupCharacterStateMonitoring()

	-- Setup death handling
	if humanoid then
		humanoid.Died:Connect(function()
			debugPrint("Character died")
			resetAttackSystem(false) -- Don't preserve chase music when dead
		end)
	end
end

-- Initialize all the needed monitoring systems
setupTeamChangeHandling()
setupRoundResetDetection()
setupCharacterHandling()

-- Add emergency chase music stop on character death
if humanoid then
	humanoid.Died:Connect(function()
		debugPrint("Character died - stopping chase music")
		stopChaseMusic()
	end)
end

-- Add safety monitor for stuck chase music
spawn(function()
	while wait(10) do -- Check every 10 seconds
		if isChaseActive and player.Team then
			-- If we're not on a gameplay team but music is still playing
			if player.Team.Name ~= "EXE" and player.Team.Name ~= "Survivor" then
				debugPrint("Safety check: Not on gameplay team but chase music playing - stopping")
				stopChaseMusic()
			end

			-- If we're a dead EXE or Survivor but music is still playing
			if humanoid and humanoid.Health <= 0 then
				debugPrint("Safety check: Player dead but chase music playing - stopping")
				stopChaseMusic()
			end
		end
	end
end)

-- Reset attack system on script load
resetAttackSystem(true)

-- Enable gamepad input
UserInputService.GamepadEnabled = true

print("Fixed Attack Script loaded! You can now attack consistently and chase music will properly start and stop.")