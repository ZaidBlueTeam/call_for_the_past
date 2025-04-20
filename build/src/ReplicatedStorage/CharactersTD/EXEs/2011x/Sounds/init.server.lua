-- Made by DevNulI, with help from Bouldy and Misha. Last updated on 11/18/22

-- Get services
local players = game:GetService("Players")

-- Set local variables
local player = players:GetPlayerFromCharacter(script.Parent)
local character = player.Character or player.CharacterAdded:wait()
local humanoid = character.Humanoid

local oldWalkSpeed

-- Create sound variables
local id
local volume
local playbackSpeed

-- Create material variables
local floorMaterial
local material

-- Create sound instance
local currentSound = Instance.new("Sound", character.HumanoidRootPart)
	  currentSound.Name = "CurrentSound"
	  currentSound.RollOffMode = Enum.RollOffMode.InverseTapered -- you can experiment with this value
	  currentSound.RollOffMinDistance = 10 -- When should the sound start fading out? (in studs)
	  currentSound.RollOffMaxDistance = 75 -- When should the sound stop being heard? (in studs)


-- Fetch the ID list
local IDList = require(script.IDList)

-- Get the current floor material.
local function getFloorMaterial()
	floorMaterial = humanoid.FloorMaterial
	material = string.split(tostring(floorMaterial), "Enum.Material.")[2]

	return material
end

-- Get the correct sound from our sound list.
local function getSoundProperties()
	for name, data in pairs(IDList) do
		if name == material then
			oldWalkSpeed = humanoid.WalkSpeed
			id = data.id
			volume = data.volume
			
			playbackSpeed = (humanoid.WalkSpeed / 16) * data.speed
			break
		end
	end
end

-- update the sound data
local function update()
	currentSound.SoundId = id
	currentSound.Volume = volume
	currentSound.PlaybackSpeed = playbackSpeed
end

-- Update the previous floor material, current floor material and sound data
humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()	
	getFloorMaterial()
	getSoundProperties()
	update()

	if humanoid.MoveDirection.Magnitude > 0 then 
		currentSound.Playing = true
	end
end)

-- check if the player is moving and not climbing
humanoid.Running:Connect(function(speed)
	if humanoid.MoveDirection.Magnitude > 0 and speed > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
		if oldWalkSpeed ~= humanoid.WalkSpeed then
			getSoundProperties()
			update()
		end
		currentSound.Playing = true
		currentSound.Looped = true
	else
		currentSound:Stop()
	end
end)

print("Walking sounds successfully loaded!")