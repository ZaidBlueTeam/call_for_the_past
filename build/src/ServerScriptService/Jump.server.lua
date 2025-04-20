local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jumpEvent = ReplicatedStorage:FindFirstChild("JumpEvent")

if not jumpEvent then
	jumpEvent = Instance.new("RemoteEvent")
	jumpEvent.Name = "JumpEvent"
	jumpEvent.Parent = ReplicatedStorage
end

jumpEvent.OnServerEvent:Connect(function(player)
	local character = player.Character
	if character then
		local jumpSound = character:FindFirstChild("Jump")
		if jumpSound then
			-- Play for nearby players with 3D spatial sound
			for _, otherPlayer in pairs(game.Players:GetPlayers()) do
				if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local otherRoot = otherPlayer.Character.HumanoidRootPart
					local playerRoot = character.HumanoidRootPart
					local distance = (playerRoot.Position - otherRoot.Position).Magnitude

					if distance <= 50 then -- Set max hearing range
						jumpSound:Play()
					end
				end
			end
		end
	end
end)