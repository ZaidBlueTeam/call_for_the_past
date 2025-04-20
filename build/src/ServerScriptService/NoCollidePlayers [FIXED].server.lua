local PhysService = game:GetService("PhysicsService")

-- Ensure the collision group exists
if not pcall(function() PhysService:CreateCollisionGroup("p") end) then
	warn("Collision Group 'p' already exists")
end

PhysService:CollisionGroupSetCollidable("p", "p", false)

-- Function to set collision group for all parts in a model
local function NoCollide(model)
	for _, v in ipairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			PhysService:SetPartCollisionGroup(v, "p")
		end
	end
end

-- Function to handle new characters
local function onCharacterAdded(char)
	-- Ensure the necessary parts exist
	char:WaitForChild("HumanoidRootPart", 5)
	char:WaitForChild("Head", 5)
	char:WaitForChild("Humanoid", 5)

	-- Apply no-collision settings
	NoCollide(char)

	-- Detect any new parts that are added later
	char.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			PhysService:SetPartCollisionGroup(descendant, "p")
		end
	end)
end

-- Apply the settings to players and their characters
game.Players.PlayerAdded:Connect(function(player)
	-- Apply no-collision to existing character if they have one
	if player.Character then
		onCharacterAdded(player.Character)
	end

	-- Listen for new character spawns
	player.CharacterAdded:Connect(onCharacterAdded)
end)
