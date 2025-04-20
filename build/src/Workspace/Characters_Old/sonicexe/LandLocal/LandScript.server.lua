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
	local landingSoundFolder = script:WaitForChild("LandingSoundFolder")

	if floorMaterial == Enum.Material.Air then
		return
	end

	local soundName = floorMaterials[floorMaterial]

	if soundName then
		local landingSound = landingSoundFolder:FindFirstChild(soundName)

		if landingSound then
			print("Sound found for the material : " .. soundName)
			local soundClone = landingSound:Clone()
			soundClone.Parent = rootPart
			soundClone:Play()
			task.wait(soundClone.TimeLength)
			soundClone:Destroy()
		else
			warn("bruh : " .. soundName)
		end
	else
		warn("bruh : " .. tostring(floorMaterial))
	end
end

local function detectLandingMaterial()
	local rayOrigin = rootPart.Position + Vector3.new(0, 5, 0)
	local rayDirection = Vector3.new(0, -20, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {script.Parent.Parent}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if raycastResult then
		return raycastResult.Material
	else
		return Enum.Material.Air
	end
end

local function waitForValidMaterial()
	while true do
		local landingMaterial = detectLandingMaterial()
		if landingMaterial ~= Enum.Material.Air then
			return landingMaterial
		end
		task.wait(0.1)
	end
end

humanoid.StateChanged:Connect(function(oldState, newState)
	if oldState == Enum.HumanoidStateType.Freefall and (newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics) then
		local landingMaterial = waitForValidMaterial()
		playLandingSound(landingMaterial)
	end
end)
