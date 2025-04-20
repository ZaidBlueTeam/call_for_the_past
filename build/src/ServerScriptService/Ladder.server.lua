local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

-- Create collision groups
PhysicsService:CreateCollisionGroup("EXE")
PhysicsService:CreateCollisionGroup("Survivor")

-- Set collision rules
PhysicsService:CollisionGroupSetCollidable("EXE", "EXE", true)
PhysicsService:CollisionGroupSetCollidable("EXE", "Survivor", false)
PhysicsService:CollisionGroupSetCollidable("Survivor", "Survivor", true)

-- Set ladder initial state for all players
local function initializeLadderState()
	for _, ladder in CollectionService:GetTagged("Ladder") do
		if ladder:IsA("Model") then
			for _, part in ladder:GetDescendants() do
				if part:IsA("BasePart") then
					-- Set collision group (already works)
					PhysicsService:SetPartCollisionGroup(part, "EXE")

					-- Set initial visibility - visible by default
					-- Visibility will be handled client-side, but set transparency
					-- to 0 (fully visible) initially for EXE players
					part.Transparency = 0
				end
			end
		elseif ladder:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(ladder, "EXE")
			ladder.Transparency = 0
		end
	end
end

-- Assign collision groups to players based on their team
local function updatePlayerCollision(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local teamName = player.Team and player.Team.Name

	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			if teamName == "EXE" then
				PhysicsService:SetPartCollisionGroup(part, "EXE")
			else
				PhysicsService:SetPartCollisionGroup(part, "Survivor")
			end
		end
	end
end

-- Update players when they join or switch teams
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		updatePlayerCollision(player)
	end)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		updatePlayerCollision(player)
	end)
end)

-- Initialize ladder collisions and visibility when the game starts
initializeLadderState()

-- Add new ladders to the collection as they're created
CollectionService:GetInstanceAddedSignal("Ladder"):Connect(function(newLadder)
	if newLadder:IsA("Model") then
		for _, part in newLadder:GetDescendants() do
			if part:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(part, "EXE")
				part.Transparency = 0
			end
		end
	elseif newLadder:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(newLadder, "EXE")
		newLadder.Transparency = 0
	end
end)

print("Ladder collision and visibility system initialized!"