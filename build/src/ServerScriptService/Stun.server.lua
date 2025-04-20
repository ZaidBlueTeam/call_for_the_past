local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create the RemoteEvent if it doesn't exist
local MeleeStunEvent = ReplicatedStorage:FindFirstChild("MeleeStunEvent")
if not MeleeStunEvent then
	MeleeStunEvent = Instance.new("RemoteEvent")
	MeleeStunEvent.Name = "MeleeStunEvent"
	MeleeStunEvent.Parent = ReplicatedStorage
end

-- Create sound event if it doesn't exist
local PunchSoundEvent = ReplicatedStorage:FindFirstChild("PunchSoundEvent")
if not PunchSoundEvent then
	PunchSoundEvent = Instance.new("RemoteEvent")
	PunchSoundEvent.Name = "PunchSoundEvent"
	PunchSoundEvent.Parent = ReplicatedStorage
end

-- Create a remote event to notify client about stun state
local StunNotifyEvent = ReplicatedStorage:FindFirstChild("StunNotifyEvent")
if not StunNotifyEvent then
	StunNotifyEvent = Instance.new("RemoteEvent")
	StunNotifyEvent.Name = "StunNotifyEvent"
	StunNotifyEvent.Parent = ReplicatedStorage
end

-- Configuration
local STUN_DURATION = 3       -- How long the EXE stays stunned
local INVINCIBILITY_TIME = 2  -- Temporary invincibility after stun
local STUN_EFFECT_ID = 12057293434  -- ID for stun particle effect
local STUN_SOUND_ID = "rbxassetid://4658308134"  -- Stun sound ID

-- Tables to track stunned players and their bodyvelocities
local stunnedPlayers = {}
local bodyVelocities = {}
local animTracks = {}

-- Function to create stun effect
local function createStunEffect(character)
	-- Create visual stun effect
	local head = character:FindFirstChild("Head") or character:FindFirstChild("head")
	if not head then return end

	-- Stars effect around head
	local stunEffect = Instance.new("ParticleEmitter")
	stunEffect.Texture = "rbxassetid://" .. STUN_EFFECT_ID
	stunEffect.LightEmission = 1
	stunEffect.Size = NumberSequence.new(0.5)
	stunEffect.Lifetime = NumberRange.new(1, 2)
	stunEffect.Rate = 5
	stunEffect.Speed = NumberRange.new(1, 3)
	stunEffect.SpreadAngle = Vector2.new(180, 180)
	stunEffect.Parent = head

	-- Stun sound
	local stunSound = Instance.new("Sound")
	stunSound.SoundId = STUN_SOUND_ID
	stunSound.Volume = 1
	stunSound.Parent = head
	stunSound:Play()

	return stunEffect
end

-- Function to play stun animations
local function playStunAnimations(humanoid)
	-- First stop ALL current animations to prevent conflicts
	for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
		track:Stop()
	end

	-- Play hit reaction animation first
	local hitReactionAnim = Instance.new("Animation")
	hitReactionAnim.AnimationId = "rbxassetid://134319170245964" -- Replace with actual hit animation ID
	local hitAnimTrack = humanoid:LoadAnimation(hitReactionAnim)
	hitAnimTrack:Play()

	-- Store the animation track for later cleanup
	local character = humanoid.Parent
	if character then
		if animTracks[character] then
			-- Stop and clean up any existing tracks
			for _, track in pairs(animTracks[character]) do
				if track and track.IsPlaying then
					track:Stop()
				end
			end
		end

		animTracks[character] = {hitAnimTrack}
	end

	-- Wait for the hit reaction animation to finish or for 0.5 seconds
	task.spawn(function()
		task.wait(math.min(hitAnimTrack.Length, 0.5))

		-- Only proceed if character is still stunned
		if character and character:GetAttribute("Stunned") then
			-- Play stun animation (looped)
			local stunAnim = Instance.new("Animation")
			stunAnim.AnimationId = "rbxassetid://112178683548703" -- Replace with actual stun animation ID
			local stunAnimTrack = humanoid:LoadAnimation(stunAnim)
			stunAnimTrack.Looped = true
			stunAnimTrack:Play()

			-- Add to tracked animations
			if animTracks[character] then
				table.insert(animTracks[character], stunAnimTrack)
			else
				animTracks[character] = {stunAnimTrack}
			end
		end
	end)
end

-- Function to completely freeze a character's movement
local function freezeCharacter(character)
	-- Get the root part
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Set up BodyVelocity to freeze position
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.P = 1000
	bv.Parent = rootPart

	-- Store the BodyVelocity for removal later
	bodyVelocities[character] = bv

	-- Disable any movement scripts
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Disable jumping and set walk speed to 0
		humanoid.JumpPower = 0
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false

		-- Notify client about stun state
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			StunNotifyEvent:FireClient(player, true, STUN_DURATION)
		end
	end

	-- Disable tools
	for _, tool in pairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Enabled = false
		end
	end
end

-- Function to unfreeze a character
local function unfreezeCharacter(character)
	-- Remove BodyVelocity
	if bodyVelocities[character] then
		bodyVelocities[character]:Destroy()
		bodyVelocities[character] = nil
	end

	-- Reset humanoid properties
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Restore original properties
		local originalWalkSpeed = humanoid:GetAttribute("OriginalWalkSpeed") or 16
		local originalJumpPower = humanoid:GetAttribute("OriginalJumpPower") or 50

		humanoid.WalkSpeed = originalWalkSpeed
		humanoid.JumpPower = originalJumpPower
		humanoid.AutoRotate = true

		-- Clear attributes
		humanoid:SetAttribute("OriginalWalkSpeed", nil)
		humanoid:SetAttribute("OriginalJumpPower", nil)

		-- Notify client about stun ending
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			StunNotifyEvent:FireClient(player, false)
		end
	end

	-- Re-enable tools
	for _, tool in pairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Enabled = true
		end
	end

	-- Stop all stun animations
	if animTracks[character] then
		for _, track in pairs(animTracks[character]) do
			if track and track.IsPlaying then
				track:Stop()
			end
		end
		animTracks[character] = nil
	end
end

-- Function to apply stun effect to a character
local function stunCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Skip if already stunned or invincible
	if character:GetAttribute("Stunned") or character:GetAttribute("Invincible") then
		return
	end

	-- Skip if character is invisible
	if humanoid:GetAttribute("Invisible") then
		return
	end

	-- Apply stun
	character:SetAttribute("Stunned", true)
	character:SetAttribute("Invincible", true)
	stunnedPlayers[character] = true

	-- Store original properties
	humanoid:SetAttribute("OriginalWalkSpeed", humanoid.WalkSpeed)
	humanoid:SetAttribute("OriginalJumpPower", humanoid.JumpPower)

	-- Completely freeze the character
	freezeCharacter(character)

	-- Play stun animation
	playStunAnimations(humanoid)

	-- Create visual stun effect
	local stunEffect = createStunEffect(character)

	-- Remove stun after duration
	task.delay(STUN_DURATION, function()
		-- Remove stun if character still exists
		if character and character:GetAttribute("Stunned") then
			-- Unfreeze the character
			unfreezeCharacter(character)

			-- Remove stun effect
			if stunEffect then
				stunEffect:Destroy()
			end

			-- Clear stunned attribute but keep temporary invincibility
			character:SetAttribute("Stunned", false)
			stunnedPlayers[character] = nil

			-- Remove invincibility after delay
			task.delay(INVINCIBILITY_TIME, function()
				if character then
					character:SetAttribute("Invincible", false)
				end
			end)
		end
	end)
end

-- Handle melee stun events from clients
MeleeStunEvent.OnServerEvent:Connect(function(player, targetPlayer)
	-- Validate player and target
	if not player or not targetPlayer then return end
	if not player.Character or not targetPlayer.Character then return end

	-- Make sure target is an EXE
	if targetPlayer.Team and targetPlayer.Team.Name == "EXE" then
		stunCharacter(targetPlayer.Character)
	end
end)

-- Handle punch sound events
PunchSoundEvent.OnServerEvent:Connect(function(player, character, soundType)
	if not character then return end

	-- Play the appropriate sound
	local soundId = (soundType == "Hit") and "rbxassetid://6760544639" or "rbxassetid://6760544188"
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 1
	sound.Parent = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
	sound:Play()

	-- Clean up sound after playing
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end)

-- Function to clean up all stun-related effects on a character
local function cleanupStunEffects(character)
	if character then
		-- Remove stunned state
		character:SetAttribute("Stunned", false)
		character:SetAttribute("Invincible", false)
		stunnedPlayers[character] = nil

		-- Unfreeze if necessary
		if bodyVelocities[character] then
			unfreezeCharacter(character)
		end

		-- Stop any animations
		if animTracks[character] then
			for _, track in pairs(animTracks[character]) do
				if track and track.IsPlaying then
					track:Stop()
				end
			end
			animTracks[character] = nil
		end
	end
end

-- Handle character respawn and cleanup
local function onCharacterAdded(player, character)
	-- Clean up old character if it exists
	if player.Character and player.Character ~= character then
		cleanupStunEffects(player.Character)
	end

	-- Set up new character
	character:SetAttribute("Stunned", false)
	character:SetAttribute("Invincible", false)
	stunnedPlayers[character] = nil

	-- Handle death to clean up stun effects
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		cleanupStunEffects(character)
	end)
end

-- Connect player events
for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		onCharacterAdded(player, player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		cleanupStunEffects(player.Character)
	end
end)

print("Stun Server Script loaded successfully!")