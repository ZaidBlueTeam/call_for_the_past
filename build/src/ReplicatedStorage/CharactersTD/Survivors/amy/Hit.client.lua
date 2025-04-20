-- Fixed Survivor Hit Reaction Script
-- Ensures invincibility is properly cleared after hits

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Get RemoteEvents
local SurvivorHitEvent = ReplicatedStorage:FindFirstChild("SurvivorHitEvent")
if not SurvivorHitEvent then
	SurvivorHitEvent = Instance.new("RemoteEvent")
	SurvivorHitEvent.Name = "SurvivorHitEvent"
	SurvivorHitEvent.Parent = ReplicatedStorage
end

local AttackEvent = ReplicatedStorage:FindFirstChild("AttackEvent")
if not AttackEvent then
	AttackEvent = Instance.new("RemoteEvent")
	AttackEvent.Name = "AttackEvent"
	AttackEvent.Parent = ReplicatedStorage
end

local AttackResetEvent = ReplicatedStorage:FindFirstChild("AttackResetEvent")
if not AttackResetEvent then
	AttackResetEvent = Instance.new("RemoteEvent")
	AttackResetEvent.Name = "AttackResetEvent"
	AttackResetEvent.Parent = ReplicatedStorage
end

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator")

-- Debug mode
local DEBUG_MODE = true

-- Print debug messages
local function debugPrint(message)
	if DEBUG_MODE then
		print("[SURVIVOR HIT] " .. message)
	end
end

-- Hit reaction animation
local hitReactionAnim = Instance.new("Animation")
hitReactionAnim.AnimationId = "rbxassetid://134319170245964" -- Hit reaction animation

-- Chase music variables
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

	for _, sound in pairs(SoundService:GetDescendants()) do
		if sound:IsA("Sound") and 
			sound.Name:match("Music") and
			sound ~= chaseMusic and
			sound.Playing then
			table.insert(backgroundSounds, sound)
		end
	end

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
			TweenInfo.new(1.5, Enum.EasingStyle.Quad),
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
				TweenInfo.new(1.5, Enum.EasingStyle.Quad),
				{Volume = originalVolume}
			)

			currentTweens[sound] = tween
			tween:Play()
		end
	end

	originalBackgroundVolumes = {}
end

-- Forward declaration for stopChaseMusic
local stopChaseMusic

-- Start chase music directly
local function startChaseMusic(musicId)
	-- If no music ID is provided, don't play any chase music
	if not musicId then return end

	debugPrint("Starting chase music with ID: " .. musicId)

	-- If chase music is already playing, don't restart it
	if isChaseActive and chaseMusic and chaseMusic.IsPlaying then
		return
	end

	-- Stop any existing chase music
	if isChaseActive and chaseMusic then
		chaseMusic:Stop()
		chaseMusic:Destroy()
		chaseMusic = nil
	end

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
		TweenInfo.new(1.5, Enum.EasingStyle.Quad),
		{Volume = 0.7}
	)

	currentTweens[chaseMusic] = tween
	tween:Play()

	debugPrint("Chase music started!")
end

-- Stop chase music
stopChaseMusic = function()
	if not isChaseActive then return end
	isChaseActive = false

	debugPrint("Stopping chase music")

	-- Restore background music
	restoreBackgroundMusic()

	-- Fade out chase music
	if chaseMusic then
		-- Cancel existing tweens
		cancelSoundTweens(chaseMusic)

		local tween = TweenService:Create(
			chaseMusic,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad),
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
end

-- CRUCIAL: Function to ensure invincibility is properly cleared
local function ensureInvincibilityCleared()
	if not char then return end

	-- Force clear invincibility attribute
	char:SetAttribute("Invincible", false)

	-- Remove invincibility object if it exists
	local invincibilityObj = char:FindFirstChild("TempInvincibility")
	if invincibilityObj then
		invincibilityObj:Destroy()
	end

	debugPrint("Survivor invincibility forcefully cleared")
end

-- Monitor for stuck invincibility
local function startInvincibilityCheck()
	local checkConnection = RunService.Heartbeat:Connect(function()
		task.wait(1) -- Check every second

		-- Check if we have invincibility
		if char and char:GetAttribute("Invincible") then
			-- Look for the invincibility object
			local invincibilityObj = char:FindFirstChild("TempInvincibility")

			-- If no object but attribute is true, this might be stuck
			if not invincibilityObj then
				debugPrint("Found stuck invincibility! Clearing...")
				ensureInvincibilityCleared()
			end

			-- Enforce maximum invincibility time
			local stuckTime = invincibilityObj and invincibilityObj:GetAttribute("StuckTime") or 0
			if stuckTime > 2 then
				debugPrint("Invincibility lasted too long! Clearing...")
				ensureInvincibilityCleared()
			elseif invincibilityObj then
				invincibilityObj:SetAttribute("StuckTime", stuckTime + 1)
			end
		end
	end)

	-- Cleanup function for when character changes
	local function cleanup()
		if checkConnection then
			checkConnection:Disconnect()
			checkConnection = nil
		end
	end

	return cleanup
end

-- Start the check system
local cleanupFunc = startInvincibilityCheck()

-- Handle getting hit by an EXE
SurvivorHitEvent.OnClientEvent:Connect(function(exeId, chaseMusicId)
	debugPrint("Hit by EXE: " .. tostring(exeId) .. ", with music: " .. tostring(chaseMusicId))

	-- Play hit reaction animation
	if animator then
		local animTrack = animator:LoadAnimation(hitReactionAnim)
		animTrack:Play()
	end

	-- Create hit effect
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HitEffect"
	screenGui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	frame.BackgroundTransparency = 0.7
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	screenGui.Parent = player.PlayerGui

	-- Fade out the effect
	task.spawn(function()
		for i = 7, 10 do
			frame.BackgroundTransparency = i/10
			task.wait(0.05)
		end
		screenGui:Destroy()
	end)

	-- START CHASE MUSIC DIRECTLY in the hit event
	if chaseMusicId then
		startChaseMusic(chaseMusicId)
	end

	-- Schedule invincibility clearing with multiple redundant checks
	task.delay(0.6, ensureInvincibilityCleared)
	task.delay(0.7, ensureInvincibilityCleared) -- Backup check
	task.delay(1.0, ensureInvincibilityCleared) -- Final safety check
end)

-- Listen for invincibility clear request
AttackResetEvent.OnClientEvent:Connect(function(action)
	if action == "ClearInvincibility" then
		ensureInvincibilityCleared()
	end
end)

-- Connect directly to the AttackEvent for chase music commands
AttackEvent.OnClientEvent:Connect(function(action, musicId)
	if action == "StartChase" then
		startChaseMusic(musicId)
	elseif action == "StopChase" then
		stopChaseMusic()
	end
end)

-- Round reset detection
local function setupRoundResetDetection()
	local roundStatsEvent = ReplicatedStorage:FindFirstChild("RoundStats")
	if roundStatsEvent then
		roundStatsEvent.OnClientEvent:Connect(function(data)
			if typeof(data) == "table" and data.status then
				local statusText = data.status

				-- If round reset or round end is detected
				if statusText:find("won the round") or 
					statusText:find("Round resetting") or 
					statusText:find("reset") or
					statusText:find("Not enough players") then

					debugPrint("Round reset detected: " .. statusText)

					-- Stop chase music
					stopChaseMusic()

					-- Clear any invincibility
					ensureInvincibilityCleared()
				end
			end
		end)
	end
end

-- Handle character changes
local function setupCharacterHandling()
	player.CharacterAdded:Connect(function(newChar)
		-- Clean up old connections
		if cleanupFunc then
			cleanupFunc()
		end

		-- Update character reference
		char = newChar
		humanoid = newChar:WaitForChild("Humanoid")
		animator = humanoid:FindFirstChildOfClass("Animator")

		-- Ensure clean state
		ensureInvincibilityCleared()

		-- Set up new monitoring
		cleanupFunc = startInvincibilityCheck()

		debugPrint("Character changed - reset invincibility state")
	end)

	-- Handle death
	if humanoid then
		humanoid.Died:Connect(function()
			debugPrint("Character died")

			-- If we're a survivor, stop chase music when we die
			if player.Team and player.Team.Name == "Survivor" then
				stopChaseMusic()
			end

			-- Clear any invincibility
			ensureInvincibilityCleared()
		end)
	end
end

-- Handle team changes
local function setupTeamChangeHandling()
	player:GetPropertyChangedSignal("Team"):Connect(function()
		-- Clear invincibility on team change
		ensureInvincibilityCleared()

		-- If we're not a survivor anymore, stop chase music
		if player.Team and player.Team.Name ~= "Survivor" then
			stopChaseMusic()
		end
	end)
end

-- Initialize all the systems
setupRoundResetDetection()
setupCharacterHandling()
setupTeamChangeHandling()

-- Apply immediate fix on script load
ensureInvincibilityCleared()

print("Fixed Survivor Hit Reaction Script loaded! Invincibility will now clear properly and chase music will stop when needed.")