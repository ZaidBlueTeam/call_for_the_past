-- Place this script in StarterPlayerScripts or StarterGui
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration
local EXE_TEAM_NAME = "EXE" -- Team name to highlight
local OUTLINE_COLOR = Color3.fromRGB(255, 0, 0) -- White outline
local ESP_TRANSPARENCY = 0.3 -- More visible (less transparent)
local ESP_UPDATE_FREQUENCY = 1 -- How often to update ESP in seconds
local HIGHLIGHT_NAME = "EXEESP" -- Name of the highlight object

local player = Players.LocalPlayer
local exeHighlights = {} -- Store highlight objects by player UserId

-- Function to create or update ESP for a player
local function updateESPForPlayer(otherPlayer)
	-- Don't highlight yourself
	if otherPlayer == player then return end

	-- Check if player is on EXE team
	local isEXE = otherPlayer.Team and otherPlayer.Team.Name == EXE_TEAM_NAME

	-- If player has a highlight but isn't EXE, remove it
	if not isEXE and exeHighlights[otherPlayer.UserId] then
		if exeHighlights[otherPlayer.UserId].Parent then
			exeHighlights[otherPlayer.UserId]:Destroy()
		end
		exeHighlights[otherPlayer.UserId] = nil
		return
	end

	-- If player is EXE and has a character but no highlight, create one
	if isEXE and otherPlayer.Character and not exeHighlights[otherPlayer.UserId] then
		local highlight = Instance.new("Highlight")
		highlight.Name = HIGHLIGHT_NAME
		highlight.OutlineColor = OUTLINE_COLOR
		highlight.FillTransparency = ESP_TRANSPARENCY
		highlight.OutlineTransparency = 0.1
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Adornee = otherPlayer.Character
		highlight.Parent = otherPlayer.Character

		exeHighlights[otherPlayer.UserId] = highlight
		print("Added ESP to EXE player: " .. otherPlayer.Name)
	end

	-- If player is EXE and has a character but the highlight's adornee is wrong, update it
	if isEXE and otherPlayer.Character and exeHighlights[otherPlayer.UserId] and exeHighlights[otherPlayer.UserId].Adornee ~= otherPlayer.Character then
		exeHighlights[otherPlayer.UserId].Adornee = otherPlayer.Character
	end
end

-- Function to update ESP for all players
local function updateAllESP()
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		updateESPForPlayer(otherPlayer)
	end
end

-- Check for changes in player teams
local function onTeamChange(player)
	updateESPForPlayer(player)
end

-- When a player's character is added
local function onCharacterAdded(player, character)
	updateESPForPlayer(player)

	-- Also track when the character is removed (player died)
	character.AncestryChanged:Connect(function(_, parent)
		if parent == nil and exeHighlights[player.UserId] then
			exeHighlights[player.UserId]:Destroy()
			exeHighlights[player.UserId] = nil
		end
	end)
end

-- When a player is added to the game
local function onPlayerAdded(otherPlayer)
	-- Track team changes
	otherPlayer:GetPropertyChangedSignal("Team"):Connect(function()
		updateESPForPlayer(otherPlayer)
	end)

	-- Track character added
	otherPlayer.CharacterAdded:Connect(function(character)
		onCharacterAdded(otherPlayer, character)
	end)

	-- If the player already has a character, set up ESP now
	if otherPlayer.Character then
		onCharacterAdded(otherPlayer, otherPlayer.Character)
	end
end

-- When a player leaves
local function onPlayerRemoving(otherPlayer)
	if exeHighlights[otherPlayer.UserId] then
		exeHighlights[otherPlayer.UserId]:Destroy()
		exeHighlights[otherPlayer.UserId] = nil
	end
end

-- Set up connections for all current players
for _, otherPlayer in pairs(Players:GetPlayers()) do
	onPlayerAdded(otherPlayer)
end

-- Set up connections for future players
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Create a periodic update to catch any missed changes
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastUpdate >= ESP_UPDATE_FREQUENCY then
		lastUpdate = now
		updateAllESP()
	end
end)

print("EXE Team ESP script loaded!")