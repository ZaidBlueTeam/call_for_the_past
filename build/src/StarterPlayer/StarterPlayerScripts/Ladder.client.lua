local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Function to update ladder visibility
local function updateLadderVisibility()
	local teamName = player.Team and player.Team.Name

	for _, ladder in CollectionService:GetTagged("Ladder") do
		if ladder:IsA("Model") then
			for _, part in ladder:GetDescendants() do
				if part:IsA("BasePart") then
					if teamName == "EXE" then
						part.Transparency = 0.8 -- Fully visible to EXE team
						part.CanCollide = true
					else
						part.Transparency = 1 -- Invisible to Survivors
						part.CanCollide = false
					end
				end
			end
		elseif ladder:IsA("BasePart") then
			if teamName == "EXE" then
				ladder.Transparency = 0 -- Fully visible to EXE team
				ladder.CanCollide = true
			else
				ladder.Transparency = 0.8 -- Invisible to Survivors
				ladder.CanCollide = false
			end
		end
	end
end

-- Update visibility when the player's team changes
player:GetPropertyChangedSignal("Team"):Connect(updateLadderVisibility)

-- Run the update function once when the game starts
updateLadderVisibility()
