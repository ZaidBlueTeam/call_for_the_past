local player = game.Players.LocalPlayer
repeat wait() until player.Character and player.Character:FindFirstChild("Humanoid")

local character = player.Character
local humanoid = character:FindFirstChild("Humanoid")
local jumpSound = character:FindFirstChild("Jump")
local camera = game.Workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure the RemoteEvent exists
local jumpEvent = ReplicatedStorage:FindFirstChild("JumpEvent")
if not jumpEvent then
	jumpEvent = Instance.new("RemoteEvent")
	jumpEvent.Name = "JumpEvent"
	jumpEvent.Parent = ReplicatedStorage
end

-- Detect when the player jumps
humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Jumping then
		if jumpSound then
			jumpSound:Play() -- Play locally
		end
		jumpEvent:FireServer() -- Tell the server to play the sound for others
	end
end)

-- Adjust sound volume based on camera distance
game:GetService("RunService").Heartbeat:Connect(function()
	if jumpSound then
		local distance = (camera.CFrame.Position - character.HumanoidRootPart.Position).Magnitude
		local maxDistance = 50
		local minDistance = 10
		local volume = math.clamp(1 - (distance - minDistance) / (maxDistance - minDistance), 0, 1)
		jumpSound.Volume = volume
	end
end)