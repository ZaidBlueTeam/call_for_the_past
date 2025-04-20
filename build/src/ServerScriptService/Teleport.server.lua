-- Teleport Sound Server Script
-- This script handles playing teleport sounds for all players

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create RemoteEvent for clients to request sound playback
local teleportSoundEvent = Instance.new("RemoteEvent")
teleportSoundEvent.Name = "TeleportSoundEvent"
teleportSoundEvent.Parent = ReplicatedStorage

-- Sound configuration
local SOUND_ID = "rbxassetid://4844057081" -- Teleport whoosh sound
local SOUND_VOLUME = 1.0
local SOUND_RADIUS = 30 -- How far the teleport sound can be heard (in studs)

-- Function to play sound at a position
teleportSoundEvent.OnServerEvent:Connect(function(player, position)
	-- Create the sound
	local sound = Instance.new("Sound")
	sound.SoundId = SOUND_ID
	sound.Volume = SOUND_VOLUME
	sound.RollOffMinDistance = 5
	sound.RollOffMaxDistance = SOUND_RADIUS
	sound.RollOffMode = Enum.RollOffMode.LinearSquare

	-- Create a temporary part to play the sound from
	local soundPart = Instance.new("Part")
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.Transparency = 1
	soundPart.Position = position
	soundPart.Parent = workspace

	-- Parent and play the sound
	sound.Parent = soundPart
	sound:Play()

	-- Clean up after sound is done
	sound.Ended:Connect(function()
		soundPart:Destroy()
	end)

	-- Failsafe cleanup in case sound doesn't play properly
	task.delay(5, function()
		if soundPart and soundPart.Parent then
			soundPart:Destroy()
		end
	end)
end)

print("Teleport Sound Server Script loaded!")