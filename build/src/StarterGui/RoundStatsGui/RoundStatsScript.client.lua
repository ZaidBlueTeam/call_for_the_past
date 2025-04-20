local replicatedStorage = game:GetService("ReplicatedStorage")
local roundStatsEvent = replicatedStorage:WaitForChild("RoundStats")

local player = game.Players.LocalPlayer
local gui = script.Parent
local roundStatsLabel = gui:WaitForChild("RoundStatsLabel")

-- Function to update the round stats GUI
local function updateRoundStats(data)
	if data.status then
		local displayText = data.status

		roundStatsLabel.Text = displayText
	end
end

-- Listen for round updates
roundStatsEvent.OnClientEvent:Connect(updateRoundStats)
