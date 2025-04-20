-- Place this script in a LocalScript under `StarterPlayer -> StarterPlayerScripts`.

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerCharacter = player.Character or player.CharacterAdded:Wait()

-- Function to refresh the camera after transformation/reset
local function refreshCameraOnce()
	-- Wait until the character is fully loaded
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")

		-- Set the camera's subject to follow the player's humanoid
		camera.CameraSubject = player.Character.Humanoid

		-- Set the camera's CFrame to follow the player's HumanoidRootPart with an offset
		camera.CFrame = CFrame.new(humanoidRootPart.Position + Vector3.new(0, 5, -10), humanoidRootPart.Position)
	end
end

-- Trigger the camera refresh only when the character is added or reset
player.CharacterAdded:Connect(function(character)
	playerCharacter = character -- Update the character reference
	wait(0.5) -- Optional: Allow a short delay to ensure everything is fully loaded
	refreshCameraOnce() -- Refresh camera once after character reset or transformation
end)

-- Function to refresh camera after character reset (on respawn, morph, etc.)
local function onCharacterReset()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		refreshCameraOnce() -- Refresh camera after transformation/reset
	end
end

-- Trigger the camera refresh after the character is reset
player.CharacterAdded:Connect(onCharacterReset)

-- Optional: Refresh the camera after respawn if needed
game:GetService("RunService").Heartbeat:Connect(function()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		-- No need to update every frame, just once per transformation/reset
	end
end)