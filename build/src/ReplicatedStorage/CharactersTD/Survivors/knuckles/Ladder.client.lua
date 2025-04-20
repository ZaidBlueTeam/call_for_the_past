-- Ladder Visibility System (LocalScript)
-- Place this in StarterPlayerScripts

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local ladders = {}

-- Function to update ladder visibility based on player's team
local function updateLadderVisibility()
	local isEXE = player.Team and player.Team.Name == "EXE"

	-- Loop through all ladders and update their visibility
	for _, ladder in ipairs(ladders) do
		-- Check if ladder still exists
		if ladder and ladder.Parent then
			-- Handle both model ladders and single-part ladders
			if ladder:IsA("Model") then
				for _, part in ipairs(ladder:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = isEXE and 0 or 1
					end
				end
			elseif ladder:IsA("BasePart") then
				ladder.Transparency = isEXE and 0 or 1
			end
		end
	end
end

-- Collect all ladders in the game
local function collectLadders()
	ladders = CollectionService:GetTagged("Ladder")
	updateLadderVisibility()

	-- Listen for new ladders being added
	CollectionService:GetInstanceAddedSignal("Ladder"):Connect(function(newLadder)
		table.insert(ladders, newLadder)
		updateLadderVisibility()
	end)

	-- Clean up when ladders are removed
	CollectionService:GetInstanceRemovedSignal("Ladder"):Connect(function(oldLadder)
		for i, ladder in ipairs(ladders) do
			if ladder == oldLadder then
				table.remove(ladders, i)
				break
			end
		end
	end)
end

-- Update ladder visibility when player's team changes
local function onTeamChanged()
	updateLadderVisibility()
end

-- Initialize
local function init()
	-- Initial setup
	collectLadders()

	-- Listen for team changes
	player:GetPropertyChangedSignal("Team"):Connect(onTeamChanged)

	-- When player's character is added
	player.CharacterAdded:Connect(function()
		-- Update visibility when character loads
		updateLadderVisibility()
	end)

	-- For robustness, check every few seconds in case we missed something
	RunService.Heartbeat:Connect(function()
		-- Only update periodically to save performance
		if tick() % 5 < 0.1 then  -- Update approximately every 5 seconds
			updateLadderVisibility()
		end
	end)

	print("Ladder visibility system initialized!")
end

-- Start the system
init()