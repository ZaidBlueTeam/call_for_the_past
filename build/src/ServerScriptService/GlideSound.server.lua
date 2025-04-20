local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playGlideSoundEvent = ReplicatedStorage:WaitForChild("PlayGlideSoundEvent")

-- Function to play the glide sound for all players
local function playGlideSoundForAllPlayers()
	for _, player in ipairs(game.Players:GetPlayers()) do
		local character = player.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				-- Create a sound in the player's character and play it
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://3751111850"  -- Replace with your glide sound's ID
				sound.Parent = hrp
				sound:Play()
				sound.Destroyed:Connect(function() sound:Destroy() end)  -- Clean up sound after it's done
			end
		end
	end
end

-- Connect to the event
playGlideSoundEvent.OnServerEvent:Connect(playGlideSoundForAllPlayers)
