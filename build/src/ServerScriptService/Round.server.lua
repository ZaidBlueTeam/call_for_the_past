local replicatedStorage = game:GetService("ReplicatedStorage")
local teams = game:GetService("Teams")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local StarterPlayer = game:GetService("StarterPlayer")

-- Team Variables
local EXETeam = teams:WaitForChild("EXE")
local SurvivorTeam = teams:WaitForChild("Survivor")
local LobbyTeam = teams:WaitForChild("Lobby")

-- Spawn Locations
local MorphingRoom = workspace:WaitForChild("MorphingRoom").box.morphspawn
local EXESpawn = workspace:WaitForChild("EXESpawn")
local SurvivorSpawn = workspace:WaitForChild("SurvivorSpawn")
local LobbySpawn = workspace:WaitForChild("LobbySpawn")

-- Character Storage
local charactersTD = replicatedStorage:WaitForChild("CharactersTD")

-- ===== MUSIC SYSTEM =====
-- Create a remote event for music control
local musicEvent = replicatedStorage:FindFirstChild("MusicEvent") or Instance.new("RemoteEvent")
musicEvent.Name = "MusicEvent"
musicEvent.Parent = replicatedStorage

-- Music IDs for each phase (3 distinct tracks)
local MUSIC_IDS = {
	LOBBY = "rbxassetid://82979854300164",         -- Peaceful lobby music
	CHARACTER_SELECT = "rbxassetid://75256941531907", -- Character selection theme
	ROUND = "rbxassetid://127056162984631"         -- Intense round music
}

-- Sound configuration
local DEFAULT_VOLUME = 0.4
local FADE_DURATION = 1.5

-- Create a sound group for organization and volume control
local musicGroup = SoundService:FindFirstChild("GameMusic") or Instance.new("SoundGroup")
musicGroup.Name = "GameMusic"
musicGroup.Parent = SoundService

-- Create the music tracks
local function createMusicTracks()
	local tracks = {}

	for phase, id in pairs(MUSIC_IDS) do
		local sound = Instance.new("Sound")
		sound.SoundId = id
		sound.Volume = DEFAULT_VOLUME
		sound.Looped = true
		sound.Name = "Music_" .. phase
		sound.SoundGroup = musicGroup
		sound.Parent = SoundService

		tracks[phase] = sound
	end

	return tracks
end

local musicTracks = createMusicTracks()

-- Current phase
local currentPhase = "LOBBY"

-- Function to change music for all players
local function changeMusicGlobal(phase)
	-- Stop current music
	if musicTracks[currentPhase] and musicTracks[currentPhase].IsPlaying then
		musicTracks[currentPhase]:Stop()
	end

	-- Set new music
	currentPhase = phase

	-- Start new music
	if musicTracks[currentPhase] then
		musicTracks[currentPhase]:Play()

		-- Tell all clients about the music change
		musicEvent:FireAllClients(phase)
	end
end

-- Start with lobby music
changeMusicGlobal("LOBBY")

-- ===== END MUSIC SYSTEM =====

-- ===== RANDOM SPAWN SYSTEM =====
-- Function to get all spawn points with a specific name
local function getAllSpawnPoints(name)
	local spawnPoints = {}

	-- Search in workspace
	for _, child in pairs(workspace:GetDescendants()) do
		if child.Name == name and (child:IsA("BasePart") or child:IsA("SpawnLocation")) then
			table.insert(spawnPoints, child)
		end
	end

	if #spawnPoints == 0 then
		warn("No spawn points found with name: " .. name)
	else
		print("Found " .. #spawnPoints .. " spawn points with name: " .. name)
	end

	return spawnPoints
end

-- Get a random spawn from the list with a specific name
local function getRandomSpawn(name)
	local spawns = getAllSpawnPoints(name)

	if #spawns > 0 then
		return spawns[math.random(1, #spawns)]
	else
		-- Fallback spawn point if none found
		warn("No spawn points found with name: " .. name .. ". Using fallback.")
		return workspace:FindFirstChild(name) or workspace.SpawnLocation
	end
end
-- ===== END RANDOM SPAWN SYSTEM =====

-- Remote Events
local assignTeamEvent = replicatedStorage:FindFirstChild("AssignTeam") or Instance.new("RemoteEvent", replicatedStorage)
assignTeamEvent.Name = "AssignTeam"

local characterSelectedEvent = replicatedStorage:FindFirstChild("CharacterSelected") or Instance.new("RemoteEvent", replicatedStorage)
characterSelectedEvent.Name = "CharacterSelected"

local startRoundEvent = replicatedStorage:FindFirstChild("StartRound") or Instance.new("RemoteEvent", replicatedStorage)
startRoundEvent.Name = "StartRound"

local roundStatsEvent = replicatedStorage:FindFirstChild("RoundStats") or Instance.new("RemoteEvent", replicatedStorage)
roundStatsEvent.Name = "RoundStats"

-- Game State Variables
local intermissionTime = 15
local selectionTime = 30
local baseRoundTime = 180  -- Base time for 1 survivor (3 minutes)
local additionalTimePerSurvivor = 60  -- Additional time per extra survivor (1 minute)
local selectedCharacters = {}
local readyPlayers = {}
local exeQueue = {}  -- Queue for EXE rotation (will be initialized with players)
local lastEXEUserId = nil -- Tracks the last player who was EXE
local roundInProgress = false  -- Track if the round is currently in progress
local characterSelectionInProgress = false -- Track if character selection is in progress
local gamePhase = "waiting" -- Current game phase: "waiting", "intermission", "selection", "starting", "round"
local ignoreDeathEvents = false -- Global flag to ignore death events during sensitive phases

-- Initialize the EXE queue with current players
local function initializeExeQueue()
	exeQueue = {}
	for _, player in pairs(players:GetPlayers()) do
		table.insert(exeQueue, player.UserId)
	end
	print("EXE Queue initialized with " .. #exeQueue .. " players")
end

-- Add new player to the EXE queue when they join
local function addPlayerToQueue(player)
	-- Only add if not already in queue
	for _, userId in ipairs(exeQueue) do
		if userId == player.UserId then
			return
		end
	end

	table.insert(exeQueue, player.UserId)
	print("Added " .. player.Name .. " to EXE queue at position " .. #exeQueue)
end

-- Remove player from the EXE queue when they leave
local function removePlayerFromQueue(player)
	for i, userId in ipairs(exeQueue) do
		if userId == player.UserId then
			table.remove(exeQueue, i)
			print("Removed " .. player.Name .. " from EXE queue")
			break
		end
	end
end

-- Rotate the EXE queue to get the next EXE
local function rotateExeQueue()
	if #exeQueue == 0 then
		initializeExeQueue()
		return
	end

	-- If we had an EXE last round, find them and rotate
	if lastEXEUserId then
		-- Find index of last EXE
		local lastIndex = nil
		for i, userId in ipairs(exeQueue) do
			if userId == lastEXEUserId then
				lastIndex = i
				break
			end
		end

		-- If found, rotate the queue to position the next player at the front
		if lastIndex then
			-- Move the previous EXE to the end
			table.insert(exeQueue, table.remove(exeQueue, lastIndex))
		end
	end

	-- Now the queue is rotated and the next player will be at position 1
	print("Rotated EXE queue. New order: ")
	for i, userId in ipairs(exeQueue) do
		local playerName = "Unknown"
		for _, p in pairs(players:GetPlayers()) do
			if p.UserId == userId then
				playerName = p.Name
				break
			end
		end
		print(i .. ": " .. playerName)
	end
end

-- Reset all players to the lobby
local function resetPlayers()
	for _, player in pairs(players:GetPlayers()) do
		if player.Character then
			player.Character:Destroy()
		end
		player.Team = LobbyTeam
		player:LoadCharacter()
		local humanoidRootPart = player.Character:WaitForChild("HumanoidRootPart", 5)
		if humanoidRootPart then
			if #getAllSpawnPoints("LobbySpawn") > 1 then
				-- If multiple spawn points, use random one
				local randomSpawn = getRandomSpawn("LobbySpawn")
				humanoidRootPart.CFrame = randomSpawn.CFrame
			else
				-- Otherwise use the original spawn point
				humanoidRootPart.CFrame = LobbySpawn.CFrame
			end
		end
		selectedCharacters[player] = nil
		readyPlayers[player] = false
	end

	-- Make sure lobby music is playing
	changeMusicGlobal("LOBBY")
end

-- Calculate round time based on number of survivors
local function calculateRoundTime(survivorCount)
	if survivorCount <= 0 then
		return baseRoundTime -- Default to base time if something's wrong
	end

	-- First survivor gets base time, each additional survivor adds extra time
	local totalTime = baseRoundTime
	if survivorCount > 1 then
		totalTime = totalTime + (survivorCount - 1) * additionalTimePerSurvivor
	end

	return totalTime
end

-- Assign teams based on the rotated EXE queue
local function assignTeams()
	local allPlayers = players:GetPlayers()
	if #allPlayers < 2 then 
		print("Not enough players to start the round.")
		roundStatsEvent:FireAllClients({ status = "Not enough players!" })
		return false 
	end

	-- Rotate the EXE queue to get the next EXE player
	rotateExeQueue()

	-- Track if we assigned an EXE
	local exeAssigned = false

	-- First, try to assign EXE based on the queue
	for _, userId in ipairs(exeQueue) do
		-- Find this player in the current player list
		for _, player in ipairs(allPlayers) do
			if player.UserId == userId then
				-- Assign as EXE
				player.Team = EXETeam
				assignTeamEvent:FireClient(player, "EXEs")
				lastEXEUserId = player.UserId  -- Remember who was EXE
				exeAssigned = true
				print(player.Name .. " assigned as EXE based on queue rotation")
				break
			end
		end

		if exeAssigned then
			break  -- We found our EXE, stop looking
		end
	end

	-- If we couldn't assign an EXE (e.g., queue was empty or players left),
	-- fall back to assigning the first player
	if not exeAssigned and #allPlayers > 0 then
		allPlayers[1].Team = EXETeam
		assignTeamEvent:FireClient(allPlayers[1], "EXEs")
		lastEXEUserId = allPlayers[1].UserId
		print(allPlayers[1].Name .. " assigned as EXE (fallback method)")
	end

	-- Assign everyone else as Survivors
	for _, player in ipairs(allPlayers) do
		if player.Team ~= EXETeam then
			player.Team = SurvivorTeam
			assignTeamEvent:FireClient(player, "Survivors")
		end
	end

	return true
end

-- Morph player into selected character
local function changePlayerCharacter(player, chosenCharacter)
	-- Set flag to ignore death events during character change
	ignoreDeathEvents = true

	local charsFolder = player.Team == EXETeam and charactersTD:WaitForChild("EXEs") or charactersTD:WaitForChild("Survivors")

	if charsFolder:FindFirstChild(chosenCharacter) then
		local newChar = charsFolder:FindFirstChild(chosenCharacter):Clone()

		if player.Character then
			player.Character:Destroy()
		end

		newChar.Name = player.Name
		newChar.Parent = workspace
		player.Character = newChar

		-- Wait for the new character to load properly
		local humanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 1)
		if humanoidRootPart then
			humanoidRootPart.CFrame = MorphingRoom.CFrame
		else
			warn(player.Name .. "'s new character does not have a HumanoidRootPart!")
		end

		-- Reattach scripts so animations & logic work
		for _, obj in pairs(newChar:GetDescendants()) do
			if obj:IsA("Script") or obj:IsA("LocalScript") then
				local newScript = obj:Clone()
				newScript.Parent = obj.Parent
				obj:Destroy()
			end
		end
	else
		warn("Character does not exist or something went wrong.")
	end

	-- Reset death event flag after a short delay to ensure all events have processed
	task.delay(0.5, function()
		ignoreDeathEvents = false
	end)
end

-- Event listener for character selection
characterSelectedEvent.OnServerEvent:Connect(function(player, chosenCharacter)
	print(player.Name .. " selected character: " .. chosenCharacter)
	selectedCharacters[player] = chosenCharacter
	changePlayerCharacter(player, chosenCharacter)
	readyPlayers[player] = true

	-- Log the ready state
	local readyCount = 0
	local teamPlayerCount = 0
	for _, p in pairs(players:GetPlayers()) do
		if p.Team == EXETeam or p.Team == SurvivorTeam then
			teamPlayerCount = teamPlayerCount + 1
			if readyPlayers[p] then
				readyCount = readyCount + 1
			end
		end
	end

	print("Ready players: " .. readyCount .. "/" .. teamPlayerCount)
end)

-- Check if all players have picked their characters
local function allPlayersPicked()
	local allTeamPlayers = {}

	-- Only count players who are actually on EXE or Survivor team
	for _, player in pairs(players:GetPlayers()) do
		if player.Team == EXETeam or player.Team == SurvivorTeam then
			table.insert(allTeamPlayers, player)
		end
	end

	-- If no players on teams, can't proceed
	if #allTeamPlayers == 0 then
		return false
	end

	-- Check if all team players have selected characters
	for _, player in ipairs(allTeamPlayers) do
		if not selectedCharacters[player] or not readyPlayers[player] then
			return false
		end
	end

	print("All players have selected characters: " .. #allTeamPlayers .. " players ready")
	return true
end

-- Count surviving players on a team
local function countSurvivingPlayers(team)
	local count = 0
	for _, player in pairs(players:GetPlayers()) do
		if player.Team == team and player.Character and
			player.Character:FindFirstChild("Humanoid") and
			player.Character.Humanoid.Health > 0 then
			count = count + 1
		end
	end
	return count
end

-- Check for win conditions
local function checkWinCondition()
	local exeAlive = false
	local survivorsAlive = false

	for _, player in pairs(players:GetPlayers()) do
		if player.Team == EXETeam and player.Character and
			player.Character:FindFirstChild("Humanoid") and
			player.Character.Humanoid.Health > 0 then
			exeAlive = true
		elseif player.Team == SurvivorTeam and player.Character and
			player.Character:FindFirstChild("Humanoid") and 
			player.Character.Humanoid.Health > 0 then
			survivorsAlive = true
		end
	end

	if not survivorsAlive then
		return "EXE"
	elseif not exeAlive then
		return "Survivors"
	end
	return nil
end

-- Set up death handling
local function setupDeathHandling(player)
	player.CharacterAdded:Connect(function(character)
		-- When a character is added, create a new Died event connection
		local humanoid = character:WaitForChild("Humanoid")

		-- We need to store the connection so we can disconnect it during character changes
		local diedConnection
		diedConnection = humanoid.Died:Connect(function()
			print("Death detected for " .. player.Name .. " in phase: " .. gamePhase)

			-- Skip death handling during non-round phases or when explicitly told to ignore
			if gamePhase ~= "round" or ignoreDeathEvents then
				print("Ignoring death event for " .. player.Name .. " (not in round phase or ignoring events)")
				return
			end

			-- Only handle actual EXE deaths during the round
			if roundInProgress and player.Team == EXETeam then
				-- Verify this is a legitimate death, not just a character switch
				-- Check if the player still has a character assigned
				if not player.Character or player.Character ~= character then
					print("False death detection for " .. player.Name .. " - character switch detected")
					return
				end

				-- This appears to be a legitimate EXE death
				print("LEGITIMATE EXE PLAYER DEATH DETECTED for " .. player.Name)
				roundStatsEvent:FireAllClients({ status = "EXE player died! Round ending..." })

				-- Short delay before reset to let players see what happened
				task.delay(3, function()
					resetPlayers()
					roundInProgress = false
					gamePhase = "waiting"
				end)
			elseif roundInProgress and player.Team == SurvivorTeam then
				-- If survivor dies, just move them to lobby
				player.Team = LobbyTeam

				-- Play lobby music for the dead player only
				musicEvent:FireClient(player, "LOBBY")

				-- Ensure their character gets reset and moved to the lobby spawn
				local humanoidRootPart = player.Character:WaitForChild("HumanoidRootPart", 5)
				if humanoidRootPart then
					humanoidRootPart.CFrame = LobbySpawn.CFrame
				end
				selectedCharacters[player] = nil
				readyPlayers[player] = false
				roundStatsEvent:FireAllClients({ status = player.Name .. " has died and is now in the lobby." })

				-- Check if this was the last survivor
				local survivorsLeft = countSurvivingPlayers(SurvivorTeam)

				if survivorsLeft == 0 then
					-- All survivors eliminated, EXE wins
					roundStatsEvent:FireAllClients({ status = "All survivors eliminated! EXE wins!" })
					task.delay(3, function()
						resetPlayers()
						roundInProgress = false
						gamePhase = "waiting"
					end)
				elseif survivorsLeft == 1 then
					-- Special case: Only one survivor left - highlight them for the EXE
					local lastSurvivor = nil
					for _, p in pairs(players:GetPlayers()) do
						if p.Team == SurvivorTeam and p.Character and 
							p.Character:FindFirstChild("Humanoid") and 
							p.Character.Humanoid.Health > 0 then
							lastSurvivor = p
							break
						end
					end

					if lastSurvivor then
						roundStatsEvent:FireAllClients({ status = "Only one survivor left: " .. lastSurvivor.Name })
					end
				end
			end
		end)

		-- Store the connection on the character for later cleanup
		character:SetAttribute("DiedConnection", true) -- We can't store the actual connection, but we can mark it
	end)
end

-- Handle player adding
local function onPlayerAdded(player)
	-- Add this player to the queue
	addPlayerToQueue(player)

	-- Set up death handling
	setupDeathHandling(player)

	-- Play lobby music for the new player
	task.delay(2, function() -- Give time for client to load
		musicEvent:FireClient(player, "LOBBY")
	end)
end

-- Handle player removal
local function onPlayerRemoving(player)
	-- Remove player from the EXE queue
	removePlayerFromQueue(player)

	-- If the player is part of the current round, consider resetting
	if roundInProgress and (player.Team == EXETeam or player.Team == SurvivorTeam) then
		resetPlayers()
		roundStatsEvent:FireAllClients({ status = "A player left or reset. Round resetting..." })
	end
end

-- Connect player events
for _, player in pairs(players:GetPlayers()) do
	onPlayerAdded(player)  -- Set up existing players
end

players.PlayerAdded:Connect(onPlayerAdded)
players.PlayerRemoving:Connect(onPlayerRemoving)

-- Initialize the EXE queue with current players at startup
initializeExeQueue()

-- Main game loop
local function roundSystem()
	-- Seed the random number generator for spawn point selection
	math.randomseed(tick())

	while true do
		-- Waiting phase
		gamePhase = "waiting"

		-- Make sure lobby music is playing during waiting
		changeMusicGlobal("LOBBY")

		while #players:GetPlayers() < 2 do
			wait(1)
			roundStatsEvent:FireAllClients({ status = "Not enough players to start the round!" })
		end

		-- Intermission phase
		gamePhase = "intermission"
		ignoreDeathEvents = true  -- Ignore death events during intermission

		-- Keep lobby music playing during intermission
		-- We'll only change music when character selection starts

		for i = intermissionTime, 0, -1 do
			roundStatsEvent:FireAllClients({ status = "Intermission: " .. i .. "s" })
			wait(1)
		end

		if not assignTeams() then
			wait(5)
			resetPlayers()
			ignoreDeathEvents = false
			wait(5)  -- Wait before starting next round
			-- Just let the loop continue to the next iteration
		else
			-- Character selection phase
			gamePhase = "selection"
			print("Starting character selection phase")
			ignoreDeathEvents = true  -- Continue ignoring death events
			characterSelectionInProgress = true

			-- Switch to character selection music
			changeMusicGlobal("CHARACTER_SELECT")

			-- Teleport players to the morphing room
			for _, player in pairs(players:GetPlayers()) do
				if player.Character then
					local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
					if humanoidRootPart then
						humanoidRootPart.CFrame = MorphingRoom.CFrame
					end
				end
				readyPlayers[player] = false
				selectedCharacters[player] = nil
			end

			-- Character selection countdown
			local selectionTimeLeft = selectionTime
			local selectionComplete = false

			while selectionTimeLeft > 0 do
				roundStatsEvent:FireAllClients({ status = "Character Selection: " .. selectionTimeLeft .. "s" })
				wait(1)
				selectionTimeLeft = selectionTimeLeft - 1

				if allPlayersPicked() then
					selectionComplete = true
					print("All players have selected characters, proceeding to round")
					break
				end
			end

			-- Clear character selection flag
			characterSelectionInProgress = false

			if not allPlayersPicked() then
				roundStatsEvent:FireAllClients({ status = "Not all players selected. Resetting..." })
				resetPlayers()
				ignoreDeathEvents = false
				wait(5)  -- Wait before starting next round
				-- Just let the loop continue to the next iteration
			else
				-- Round starting phase - critical transition!
				gamePhase = "starting"
				print("Round starting...")
				startRoundEvent:FireAllClients()

				-- Switch to round music
				changeMusicGlobal("ROUND")

				-- Teleport players to their spawn points
				for _, player in pairs(players:GetPlayers()) do
					if player.Character then
						local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
						if humanoidRootPart then
							if player.Team == EXETeam then
								if #getAllSpawnPoints("EXESpawn") > 1 then
									-- If multiple spawn points, use random one
									local randomSpawn = getRandomSpawn("EXESpawn")
									humanoidRootPart.CFrame = randomSpawn.CFrame
								else
									-- Otherwise use the original spawn point
									humanoidRootPart.CFrame = EXESpawn.CFrame
								end
							elseif player.Team == SurvivorTeam then
								if #getAllSpawnPoints("SurvivorSpawn") > 1 then
									-- If multiple spawn points, use random one
									local randomSpawn = getRandomSpawn("SurvivorSpawn")
									humanoidRootPart.CFrame = randomSpawn.CFrame
								else
									-- Otherwise use the original spawn point
									humanoidRootPart.CFrame = SurvivorSpawn.CFrame
								end
							end
						end
					end
				end

				-- Short delay to ensure everyone is properly teleported
				wait(2)

				-- Now officially start the round
				gamePhase = "round"
				roundInProgress = true
				print("Round phase officially started!")

				-- Count survivors for dynamic round time
				local survivorCount = countSurvivingPlayers(SurvivorTeam)
				local dynamicRoundTime = calculateRoundTime(survivorCount)

				-- Announce round start with dynamic time
				roundStatsEvent:FireAllClients({ 
					status = "Round started! Time: " .. dynamicRoundTime .. "s (" .. 
						math.floor(dynamicRoundTime/60) .. ":" .. 
						string.format("%02d", dynamicRoundTime % 60) .. ")" 
				})

				-- Wait a bit longer before enabling death detection to avoid false positives
				task.delay(1, function()
					ignoreDeathEvents = false
					print("Death events are now being tracked")
				end)

				-- Round timer countdown with dynamic time
				local roundTimer = dynamicRoundTime
				local minutesDisplay, secondsDisplay

				while roundTimer > 0 and roundInProgress do
					local survivorsLeft = countSurvivingPlayers(SurvivorTeam)
					local exeAlive = countSurvivingPlayers(EXETeam) > 0
					local exePlayer = "Unknown"

					-- Format time as MM:SS
					minutesDisplay = math.floor(roundTimer / 60)
					secondsDisplay = roundTimer % 60
					local formattedTime = minutesDisplay .. ":" .. string.format("%02d", secondsDisplay)

					-- Find the EXE player name
					for _, player in pairs(players:GetPlayers()) do
						if player.Team == EXETeam then
							exePlayer = player.Name
							break
						end
					end

					-- If EXE is dead or there are no survivors left, end the round
					if not exeAlive and gamePhase == "round" then
						roundStatsEvent:FireAllClients({ status = "EXE has been eliminated! Survivors win!" })
						break
					elseif survivorsLeft == 0 and gamePhase == "round" then
						roundStatsEvent:FireAllClients({ status = "All survivors eliminated! EXE wins!" })
						break
					end

					roundStatsEvent:FireAllClients({ 
						status = "Timer: " .. formattedTime, 
						exePlayer = exePlayer, 
						survivorsLeft = survivorsLeft 
					})

					wait(1)
					roundTimer = roundTimer - 1
				end

				-- Reset players for the next round
				print("Round ended, resetting players")
				resetPlayers() -- This will handle random spawns and music
				roundInProgress = false
				gamePhase = "waiting"
				ignoreDeathEvents = false
				wait(5)
			end -- End of character selection completion check
		end -- End of team assignment check
	end -- End of the main while true loop in roundSystem()
end

spawn(roundSystem)

-- Create a LocalScript to handle music on the client side
local musicLocalScript = Instance.new("LocalScript")
musicLocalScript.Name = "MusicController"
musicLocalScript.Source = [[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local musicEvent = ReplicatedStorage:WaitForChild("MusicEvent")

local SoundService = game:GetService("SoundService")

-- Create a sound group for local music
local localMusicGroup = Instance.new("SoundGroup")
localMusicGroup.Name = "LocalMusicGroup"
localMusicGroup.Parent = SoundService

-- Create local music tracks
local localMusicTracks = {}

local MUSIC_IDS = {
    LOBBY = "rbxassetid://1848320500",
    CHARACTER_SELECT = "rbxassetid://1837453762",
    ROUND = "rbxassetid://1837393140"
}

-- Create the tracks
for name, id in pairs(MUSIC_IDS) do
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = id
    sound.Looped = true
    sound.Volume = 0.4
    sound.Parent = script
    
    localMusicTracks[name] = sound
end

-- Handle music changes
local currentTrack = nil

musicEvent.OnClientEvent:Connect(function(musicType)
    -- Stop current track if playing
    if currentTrack and currentTrack.IsPlaying then
        currentTrack:Stop()
    end
    
    -- If stop command, just stop
    if musicType == "STOP" then
        currentTrack = nil
        return
    end
    
    -- Play new track if valid
    if localMusicTracks[musicType] then
        currentTrack = localMusicTracks[musicType]
        currentTrack:Play()
    end
end)

print("Music controller initialized")
]]

-- Add the local script to StarterPlayerScripts
local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
if not StarterPlayerScripts:FindFirstChild("MusicController") then
	musicLocalScript:Clone().Parent = StarterPlayerScripts
end

print("Round system script initialized!")