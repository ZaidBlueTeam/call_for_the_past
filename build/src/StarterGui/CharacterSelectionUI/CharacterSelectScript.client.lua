local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

local player = players.LocalPlayer
local gui = script.Parent
local selectionFrame = gui:FindFirstChild("SelectionFrame")
local teamLabel = selectionFrame:FindFirstChild("TeamLabel")
local leftArrow = selectionFrame:FindFirstChild("LeftArrow")
local rightArrow = selectionFrame:FindFirstChild("RightArrow")
local selectButton = selectionFrame:FindFirstChild("SelectButton")
local characterNameLabel = selectionFrame:FindFirstChild("CharacterName")

local charactersTD = replicatedStorage:WaitForChild("CharactersTD")

-- Remote Events
local assignTeamEvent = replicatedStorage:WaitForChild("AssignTeam")
local characterSelectedEvent = replicatedStorage:WaitForChild("CharacterSelected")
local startRoundEvent = replicatedStorage:WaitForChild("StartRound")

-- Hide GUI initially
gui.Enabled = false

-- Variables to track the characters
local characterButtons = {}
local currentIndex = 1

-- Function to update the character display
local function updateCharacterDisplay()
	if #characterButtons > 0 then
		for i, button in ipairs(characterButtons) do
			button.Visible = (i == currentIndex)
		end
		characterNameLabel.Text = characterButtons[currentIndex].Text
	end
end

-- Show character selection GUI when assigned a team
assignTeamEvent.OnClientEvent:Connect(function(teamName)
	gui.Enabled = true
	teamLabel.Text = "Team: " .. teamName

	-- Clear previous buttons
	for _, button in pairs(characterButtons) do
		button:Destroy()
	end

	characterButtons = {}
	currentIndex = 1

	local charactersFolder = charactersTD:FindFirstChild(teamName)
	if charactersFolder then
		for _, character in pairs(charactersFolder:GetChildren()) do
			if character:IsA("Model") then
				local button = Instance.new("TextButton")
				button.Size = UDim2.new(0, 200, 0, 50)
				button.Text = character.Name
				button.Parent = selectionFrame
				button.Visible = false
				table.insert(characterButtons, button)
			end
		end

		if #characterButtons > 0 then
			updateCharacterDisplay()
		end
	end
end)

-- Arrow selection
leftArrow.MouseButton1Click:Connect(function()
	if #characterButtons > 0 then
		currentIndex = (currentIndex - 2) % #characterButtons + 1
		updateCharacterDisplay()
	end
end)

rightArrow.MouseButton1Click:Connect(function()
	if #characterButtons > 0 then
		currentIndex = currentIndex % #characterButtons + 1
		updateCharacterDisplay()
	end
end)

-- Function to select a character
local function selectCharacter()
	if #characterButtons > 0 then
		local selectedCharacter = characterButtons[currentIndex].Text
		characterSelectedEvent:FireServer(selectedCharacter)
	else
		warn("No character is currently selected.")
	end
end

selectButton.MouseButton1Click:Connect(selectCharacter)
userInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if not gameProcessedEvent and input.KeyCode == Enum.KeyCode.E then
		selectCharacter()
	end
end)

-- Hide GUI when the round starts
startRoundEvent.OnClientEvent:Connect(function()
	gui.Enabled = false
end)

print("Character selection script loaded.")
