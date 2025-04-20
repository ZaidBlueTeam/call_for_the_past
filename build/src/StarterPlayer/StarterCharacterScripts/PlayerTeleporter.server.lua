game.ReplicatedStorage.TeleportPlayer.Event:Connect(function(Location)
	script.Parent.HumanoidRootPart.Position = Location.Position
end)