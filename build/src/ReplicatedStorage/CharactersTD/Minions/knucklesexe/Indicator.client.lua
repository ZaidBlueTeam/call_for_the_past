-- Survivor Team Indicator Script
-- This script allows players to press R to highlight all players on the "Survivor" team
-- Includes cooldown functionality and indicator duration timer

-- Configuration
local INDICATOR_KEY = Enum.KeyCode.R -- Key to activate the indicator
local INDICATOR_DURATION = 10 -- How long the indicator stays active (in seconds)
local COOLDOWN_DURATION = 15 -- Cooldown between uses (in seconds)

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local cooldownActive = false
local indicatorActive = false
local highlightInstances = {}

-- Function to create a highlight
local function createHighlight(targetCharacter)
	local highlight = Instance.new("Highlight")
	highlight.OutlineColor = Color3.fromRGB(255, 217, 0)
	highlight.OutlineTransparency = 0
	highlight.Adornee = targetCharacter
	highlight.Parent = targetCharacter

	return highlight
end

-- Function to find survivors and highlight them
local function highlightSurvivors()
	-- Clear any existing highlights
	for _, highlight in pairs(highlightInstances) do
		if highlight and highlight.Parent then
			highlight:Destroy()
		end
	end
	highlightInstances = {}

	-- Find the Survivor team
	local survivorTeam = nil
	for _, team in pairs(Teams:GetTeams()) do
		if team.Name == "Survivor" then
			survivorTeam = team
			break
		end
	end

	if not survivorTeam then
		print("Survivor team not found!")
		return
	end

	-- Highlight all players on the Survivor team
	for _, targetPlayer in pairs(Players:GetPlayers()) do
		if targetPlayer ~= player and targetPlayer.Team == survivorTeam then
			if targetPlayer.Character then
				local highlight = createHighlight(targetPlayer.Character)
				table.insert(highlightInstances, highlight)
			end
		end
	end
end

-- Function to activate the indicator
local function activateIndicator()
	-- Early return if cooldown or indicator is active
	if cooldownActive or indicatorActive then
		-- Provide feedback that ability is on cooldown
		if player.PlayerGui:FindFirstChild("CooldownNotice") then return end

		local notice = Instance.new("ScreenGui")
		notice.Name = "CooldownNotice"

		local noticeText = Instance.new("TextLabel")
		noticeText.Size = UDim2.new(0, 250, 0, 50)
		noticeText.Position = UDim2.new(0.5, -125, 0.2, 0)
		noticeText.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		noticeText.BackgroundTransparency = 0.3
		noticeText.TextColor3 = Color3.fromRGB(255, 255, 255)
		noticeText.Font = Enum.Font.GothamBold
		noticeText.TextSize = 18
		noticeText.Text = "Ability on cooldown!"
		noticeText.Parent = notice

		notice.Parent = player.PlayerGui

		-- Remove notice after 1 second
		task.delay(1, function()
			if notice and notice.Parent then
				notice:Destroy()
			end
		end)

		return
	end

	-- Start cooldown
	cooldownActive = true
	indicatorActive = true

	-- Create GUI for indicator and cooldown
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IndicatorGui"
	screenGui.ResetOnSpawn = false

	local indicatorFrame = Instance.new("Frame")
	indicatorFrame.Size = UDim2.new(0, 200, 0, 50)
	indicatorFrame.Position = UDim2.new(0.5, -100, 0.1, 0)
	indicatorFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	indicatorFrame.BackgroundTransparency = 0.5
	indicatorFrame.BorderSizePixel = 2
	indicatorFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
	indicatorFrame.Parent = screenGui

	local indicatorText = Instance.new("TextLabel")
	indicatorText.Size = UDim2.new(1, 0, 1, 0)
	indicatorText.BackgroundTransparency = 1
	indicatorText.TextColor3 = Color3.fromRGB(255, 255, 255)
	indicatorText.Font = Enum.Font.GothamBold
	indicatorText.TextSize = 18
	indicatorText.Text = "Survivor Indicator: Active"
	indicatorText.Parent = indicatorFrame

	screenGui.Parent = player.PlayerGui

	-- Highlight survivors
	highlightSurvivors()

	-- Timer for indicator duration
	local indicatorTimeLeft = INDICATOR_DURATION
	local cooldownTimeLeft = COOLDOWN_DURATION

	-- Create timer loop
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if indicatorActive then
			indicatorTimeLeft = indicatorTimeLeft - deltaTime
			indicatorText.Text = "Survivor Indicator: " .. math.ceil(indicatorTimeLeft) .. "s"

			if indicatorTimeLeft <= 0 then
				indicatorActive = false

				-- Remove highlights
				for _, highlight in pairs(highlightInstances) do
					if highlight and highlight.Parent then
						highlight:Destroy()
					end
				end
				highlightInstances = {}

				indicatorText.Text = "Cooldown: " .. math.ceil(cooldownTimeLeft) .. "s"
			end
		else
			cooldownTimeLeft = cooldownTimeLeft - deltaTime

			-- Prevent timer from going negative
			local displayTime = math.max(0, math.ceil(cooldownTimeLeft))
			indicatorText.Text = "Cooldown: " .. displayTime .. "s"

			if cooldownTimeLeft <= 0 then
				cooldownActive = false
				if connection then -- Check if connection exists before disconnecting
					connection:Disconnect()
				end
				if screenGui and screenGui.Parent then
					screenGui:Destroy()
				end
			end
		end
	end)
end

-- Connect input detection
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == INDICATOR_KEY then
		activateIndicator()
	end
end)

-- Handle character respawning
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
end)

-- Player team change handling for dynamic updates during active indicator
local function onPlayerTeamChanged(changedPlayer)
	if indicatorActive then
		-- Refresh the highlights when any player changes team
		highlightSurvivors()
	end
end

-- Connect team change events
Players.PlayerAdded:Connect(function(newPlayer)
	newPlayer:GetPropertyChangedSignal("Team"):Connect(function()
		onPlayerTeamChanged(newPlayer)
	end)
end)

for _, existingPlayer in pairs(Players:GetPlayers()) do
	existingPlayer:GetPropertyChangedSignal("Team"):Connect(function()
		onPlayerTeamChanged(existingPlayer)
	end)
end

print("Survivor Indicator Script Loaded! Press R to activate.")

-- Controller support for Indicator
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.ButtonB then -- B button
		activateIndicator() -- Trigger the existing function
	end
end)