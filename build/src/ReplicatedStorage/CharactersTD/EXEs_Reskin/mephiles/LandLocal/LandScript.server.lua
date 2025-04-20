local humanoid = script.Parent.Parent:WaitForChild("Humanoid")
local rootPart = script.Parent.Parent:WaitForChild("HumanoidRootPart")

local floorMaterials = {
	[Enum.Material.Grass] = "Grass",
	[Enum.Material.Cobblestone] = "Stone",
	[Enum.Material.Plastic] = "Plastic",
	[Enum.Material.SmoothPlastic] = "SmoothPlastic",
	[Enum.Material.Pavement] = "Pavement",
	[Enum.Material.Brick] = "Brick",
	[Enum.Material.Concrete] = "Concrete",
	[Enum.Material.Wood] = "Wood",
	[Enum.Material.WoodPlanks] = "WoodPlanks",
	[Enum.Material.LeafyGrass] = "LeafyGrass",
	[Enum.Material.Metal] = "Metal",
	[Enum.Material.DiamondPlate] = "DiamondPlate",
	[Enum.Material.Glass] = "Blood",
}

local function playLandingSound(floorMaterial)
	local landingSoundFolder = script:FindFirstChild("LandingSoundFolder")

	if not landingSoundFolder then
		warn("⚠️ LandingSoundFolder is missing!")
		return
	end

	if floorMaterial == Enum.Material.Air then
		return
	end

	local soundName = floorMaterials[floorMaterial]

	if soundName then
		local landingSound = landingSoundFolder:FindFirstChild(soundName)

		if landingSound then
			print("✅ Playing sound for material:", soundName)
			local soundClone = landingSound:Clone()
			soundClone.Parent = rootPart
			soundClone:Play()
			task.wait(soundClone.TimeLength)
			soundClone:Destroy()
		else
			warn("⚠️ No sound found for material:", soundName)
		end
	else
		warn("⚠️ No matching material found for:", tostring(floorMaterial))
	end
end

local function detectLandingMaterial()
	local rayOrigin = rootPart.Position
	local rayDirection = Vector3.new(0, -5, 0) -- Scan below the character
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {script.Parent.Parent} -- Ignore the character itself
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if raycastResult and raycastResult.Instance then
		local hitPart = raycastResult.Instance
		local parentModel = hitPart.Parent

		-- **Check if it's a player character and ignore it**
		if parentModel and game.Players:GetPlayerFromCharacter(parentModel) then
			print("⚠️ Ignored: Landed on another player/morph")
			return Enum.Material.Air
		end

		print("✅ Landed on:", hitPart.Name, "| Material:", raycastResult.Material)
		return raycastResult.Material
	else
		print("⚠️ No ground detected - Landed on Air")
		return Enum.Material.Air
	end
end

humanoid.StateChanged:Connect(function(oldState, newState)
	if oldState == Enum.HumanoidStateType.Freefall and (newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics) then
		local landingMaterial = detectLandingMaterial()
		playLandingSound(landingMaterial)
	end
end)
