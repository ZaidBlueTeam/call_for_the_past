script.Parent.CannonEvent.OnServerEvent:Connect(function(player, mouseaim)
	local leftDag = game.ReplicatedStorage.ItemStorage.particlesPart:Clone()
	local hrp = player.Character.HumanoidRootPart
	local sound = script.Parent.Parent.shoot:Clone()
	sound.Parent = hrp
	sound:Play()
	leftDag.Parent = workspace
	leftDag.CFrame = CFrame.new(mouseaim)
	leftDag.Transparency = 1
	local rayon = Instance.new("Part")
	rayon.Name = "Rayon"
	rayon.Anchored = true
	rayon.CanCollide = false
	rayon.Transparency = 0.5
	rayon.BrickColor = BrickColor.new("New Yeller")
	rayon.Size = Vector3.new(0.7, 0.7, (leftDag.Position - hrp.Position).Magnitude)
	rayon.CFrame = CFrame.new((leftDag.Position + hrp.Position) / 2, hrp.Position)
	rayon.Parent = workspace
	rayon.Material = Enum.Material.Neon
	task.wait(0.01)
	leftDag.sfx:Play()
	local hitbox = rayon
	local Hits = {}
	hitbox.Touched:Connect(function(Hit)
		if Hit.Parent:FindFirstChild("PlrValue").Other.Values.character.Value == "dummy" then
			Hit.Parent:FindFirstChild("PlrValue").Other.Values.Stun.Value = true
			task.wait(4)
			Hit.Parent:FindFirstChild("PlrValue").Other.Values.Stun.Value = false
		end
	end)
	leftDag.one.Enabled = true
	leftDag.two.Enabled = true
	task.wait(0.3)
	leftDag.one.Enabled = false
	leftDag.two.Enabled = false
	game.Debris:AddItem(sound, 5)
	game.Debris:AddItem(leftDag, 1.3)
	rayon.Transparency = 0.1
	task.wait(0.01)
	rayon.Transparency = 0.2
	task.wait(0.01)
	rayon.Transparency = 0.3
	task.wait(0.01)
	rayon.Transparency = 0.4
	task.wait(0.01)
	rayon.Transparency = 0.5
	task.wait(0.01)
	rayon.Transparency = 0.6
	task.wait(0.01)
	rayon.Transparency = 0.7
	task.wait(0.01)
	rayon.Transparency = 0.8
	task.wait(0.01)
	rayon.Transparency = 0.9
	task.wait(0.01)
	rayon.Transparency = 1
	task.wait(0.01)
	game.Debris:AddItem(rayon, 0.2)
end)
