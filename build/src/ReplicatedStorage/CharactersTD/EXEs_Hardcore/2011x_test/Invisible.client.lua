-- Complete Invisibility System - LOCAL SCRIPT (FIXED)
-- Place this in a LocalScript in the player's character (or StarterCharacterScripts)

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

-- Configuration
local INVISIBILITY_DURATION = 20 -- Seconds
local COOLDOWN_TIME = 15 -- Seconds
local TEAM_SURVIVOR = "Survivor" -- Team name for survivors
local SILHOUETTE_TRANSPARENCY = 0.8 -- How transparent the silhouette is
local RUN_SPEED_THRESHOLD = 52-- Walkspeed above this plays run animation instead of walk

-- Keys to block during invisibility
local BLOCKED_INPUTS = {
	[Enum.KeyCode.Q] = "Q",
	[Enum.KeyCode.F] = "F",
	[Enum.UserInputType.MouseButton1] = "Left Click"
}
local ACTION_NAME = "BlockDuringInvisibility"

-- State variables
local isInvisible = false
local onCooldown = false
local originalTransparencies = {} -- Store original part transparencies
local silhouetteParts = {} -- Stores the silhouette parts
local movementConnection = nil -- Connection for handling movement animations
local currentAnimTrack = nil -- Current animation track playing
local animationTrackingConnection = nil -- Connection for tracking animation playback
local visibilityRestorationAttempted = false -- Track if visibility restoration was attempted
local countdownConnection = nil -- Store the countdown connection
local inputsBlocked = false -- Track if inputs are blocked
local notificationGui = nil -- GUI for blocked input notifications
local animateScript = nil -- Reference to Animate script
local originalAnimationTracks = {} -- Store original animation settings from Animate script

-- Animation IDs for invisible state
local INVISIBLE_ANIMATIONS = {
	idle = "rbxassetid://100334668149983", -- Replace with your invisible idle animation
	Mach1 = "rbxassetid://136359581349052", -- Replace with your invisible walk animation
	Mach2 = "rbxassetid://105643396986433" -- Replace with your invisible run animation
}

-- Animation tracks for invisible state
local invisibleTracks = {
	idle = nil,
	Mach1 = nil,
	Mach2 = nil
}
local appearAnimTrack = nil

-- Animation replacement pattern matching (for animator script)
local animationsToReplace = {
	idle = {"idle"},
	Mach1 = {"Mach1"},
	Mach2 = {"Mach2"}
}

-- Forward declarations to prevent orange lines
local activateInvisibility
local deactivateInvisibility
local forceVisibilityRestoration
local enableInputBlocking
local disableInputBlocking
local removeAllESP
local startCooldown

-- Create or get RemoteEvent for server communication
local invisibilityEvent = ReplicatedStorage:FindFirstChild("InvisibilityEvent")
if not invisibilityEvent then
	invisibilityEvent = Instance.new("RemoteEvent")
	invisibilityEvent.Name = "InvisibilityEvent"
	invisibilityEvent.Parent = ReplicatedStorage
end

-- Get path string for an instance (used for transparency restoration)
local function getInstancePath(instance)
	if not instance or not instance:IsDescendantOf(game) then return nil end

	local path = instance.Name
	local current = instance.Parent

	while current and current ~= game do
		path = current.Name .. "." .. path
		current = current.Parent
	end

	return path
end

-- Find the Animate script
local function findAnimateScript()
	-- First try direct child
	animateScript = character:FindFirstChild("Animate")

	-- If not found, search deeper
	if not animateScript then
		for _, child in pairs(character:GetDescendants()) do
			if (child:IsA("Script") or child:IsA("LocalScript")) and child.Name == "Animate" then
				animateScript = child
				break
			end
		end
	end

	if animateScript then
		print("Found Animate script: " .. animateScript:GetFullName())
	else
		warn("Animate script not found in character! Animation replacement may not work properly.")
	end

	return animateScript
end

-- Save original animation settings from Animate script
local function saveOriginalAnimationSettings()
	-- Reset storage
	originalAnimationTracks = {}

	if not animateScript then
		warn("No Animate script found to save animations from")
		return
	end

	-- Save all animation type properties from Animate script
	for _, animType in ipairs({"idle", "Mach1", "Mach2"}) do
		-- Find the animation folder
		local animFolder = animateScript:FindFirstChild(animType)
		if animFolder then
			originalAnimationTracks[animType] = {}

			-- Save each animation in the folder
			for _, anim in pairs(animFolder:GetChildren()) do
				if anim:IsA("Animation") then
					originalAnimationTracks[animType][anim.Name] = {
						id = anim.AnimationId,
						weight = anim:GetAttribute("Weight") or 1
					}
				end
			end

			-- Save the currently active animation in each folder
			local animObj = animateScript:FindFirstChild(animType .. "Anim")
			if animObj and animObj:IsA("StringValue") then
				originalAnimationTracks[animType].current = animObj.Value
			end
		end
	end

	print("Saved original animation settings from Animate script")
end

-- Load animations for invisible state
local function loadInvisibleAnimations()
	-- Clean up any existing animations
	for animType, track in pairs(invisibleTracks) do
		if track then
			track:Stop()
			track:Destroy()
			invisibleTracks[animType] = nil
		end
	end

	-- Load new animation tracks
	for animType, animId in pairs(INVISIBLE_ANIMATIONS) do
		local animation = Instance.new("Animation")
		animation.AnimationId = animId
		local track = humanoid:LoadAnimation(animation)
		track.Priority = Enum.AnimationPriority.Action
		track.Name = "Invisible" .. animType:sub(1,1):upper() .. animType:sub(2)
		invisibleTracks[animType] = track
	end

	-- Load appear animation
	local appearAnim = Instance.new("Animation")
	appearAnim.AnimationId = "rbxassetid://103055532252719" -- Your appear animation
	appearAnimTrack = humanoid:LoadAnimation(appearAnim)
	appearAnimTrack.Priority = Enum.AnimationPriority.Action

	print("Invisible animations loaded")
end

-- Override animations in Animate script
local function overrideAnimateScriptAnimations()
	if not animateScript then
		warn("No Animate script found to override animations")
		return
	end

	-- For each animation type we want to replace
	for animType, patterns in pairs(animationsToReplace) do
		-- Find the animation folder
		local animFolder = animateScript:FindFirstChild(animType)
		if animFolder then
			-- Create our replacement animation
			local invisAnim = Instance.new("Animation")
			invisAnim.Name = "InvisibleOverride"
			invisAnim.AnimationId = INVISIBLE_ANIMATIONS[animType]
			invisAnim.Parent = animFolder

			-- Set attributes to give it high priority
			invisAnim:SetAttribute("Weight", 10) -- Very high weight to ensure it's chosen

			-- Set this as the current animation
			local animObj = animateScript:FindFirstChild(animType .. "Anim")
			if animObj and animObj:IsA("StringValue") then
				-- Save current value if not already saved
				if not originalAnimationTracks[animType] or not originalAnimationTracks[animType].current then
					originalAnimationTracks[animType] = originalAnimationTracks[animType] or {}
					originalAnimationTracks[animType].current = animObj.Value
				end

				-- Set to our invisible animation
				animObj.Value = "InvisibleOverride"
			end
		end
	end

	print("Overrode animations in Animate script with invisible animations")

	-- Force a re-run of the animation setup in the Animate script
	local success, err = pcall(function()
		-- This is a trick to "restart" the animation system
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		task.wait(0.1)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)

	if not success then
		warn("Failed to restart animation system: " .. tostring(err))
	end
end

-- Restore original animations in Animate script
local function restoreAnimateScriptAnimations()
	if not animateScript then
		warn("No Animate script found to restore animations")
		return
	end

	if not originalAnimationTracks or not next(originalAnimationTracks) then
		warn("No original animation tracks saved to restore")
		return
	end

	-- For each animation type we want to restore
	for animType, origSettings in pairs(originalAnimationTracks) do
		-- Restore the current animation
		if origSettings.current then
			local animObj = animateScript:FindFirstChild(animType .. "Anim")
			if animObj and animObj:IsA("StringValue") then
				animObj.Value = origSettings.current
			end
		end

		-- Remove our custom invisible animation
		local animFolder = animateScript:FindFirstChild(animType)
		if animFolder then
			local invisAnim = animFolder:FindFirstChild("InvisibleOverride")
			if invisAnim then
				invisAnim:Destroy()
			end
		end
	end

	print("Restored original animations in Animate script")

	-- Force a re-run of the animation setup
	local success, err = pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		task.wait(0.1)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)

	if not success then
		warn("Failed to restart animation system: " .. tostring(err))
	end
end

-- Setup appear sound locally
local appearSound = Instance.new("Sound", character)
appearSound.SoundId = "rbxassetid://4844057081"
appearSound.Volume = 1
appearSound.Name = "AppearSound"

-- Function to create notification for blocked inputs
local function createInputBlockedNotification(inputName)
	-- Use pcall for everything in this function to ensure it can't break invisibility
	pcall(function()
		-- Remove existing notification if there is one
		if notificationGui and notificationGui.Parent then
			notificationGui:Destroy()
		end

		-- Create GUI
		notificationGui = Instance.new("ScreenGui")
		notificationGui.Name = "BlockedInputNotification"

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, 250, 0, 40)
		frame.Position = UDim2.new(0.5, -125, 0.8, 0)
		frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		frame.BackgroundTransparency = 0.3
		frame.BorderSizePixel = 0
		frame.Parent = notificationGui

		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, 6)
		uiCorner.Parent = frame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextSize = 14
		label.Font = Enum.Font.Gotham
		label.Text = "Cannot use " .. inputName .. " while invisible"
		label.Parent = frame

		notificationGui.Parent = player.PlayerGui

		-- Auto-remove after 1.5 seconds using spawn to isolate from main thread
		task.spawn(function()
			task.wait(1.5)
			if notificationGui and notificationGui.Parent then
				notificationGui:Destroy()
			end
		end)
	end)
end

-- Input handler function for blocked inputs
local function handleBlockedInput(_, inputState, inputObject)
	-- Only process when input begins
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	-- Get the name of the input for the notification
	local inputName = BLOCKED_INPUTS[inputObject.KeyCode] or BLOCKED_INPUTS[inputObject.UserInputType]

	-- Show notification
	if inputName then
		-- Use pcall to ensure notification creation can't break invisibility
		pcall(function()
			createInputBlockedNotification(inputName)
		end)
	end

	-- Important: Do nothing else that could affect invisibility state
	-- Just sink (block) the input and return
	return Enum.ContextActionResult.Sink
end

-- Enable input blocking
enableInputBlocking = function()
	if inputsBlocked then return end

	inputsBlocked = true

	-- Clear any existing action binding first to be safe
	pcall(function()
		ContextActionService:UnbindAction(ACTION_NAME)
	end)

	-- Create a table of inputs to block for ContextActionService
	local inputsToBlock = {}
	for input, _ in pairs(BLOCKED_INPUTS) do
		table.insert(inputsToBlock, input)
	end

	-- Use pcall to ensure binding action cannot break invisibility state
	pcall(function()
		-- Set up context action to block inputs
		ContextActionService:BindAction(
			ACTION_NAME,
			handleBlockedInput,
			false, -- Don't create touch button
			unpack(inputsToBlock) -- Unpack all inputs to block
		)
	end)

	print("Input blocking enabled during invisibility")
end

-- Disable input blocking
disableInputBlocking = function()
	if not inputsBlocked then return end

	inputsBlocked = false

	-- Use pcall to ensure unbinding action cannot break other systems
	pcall(function()
		-- Remove the context action
		ContextActionService:UnbindAction(ACTION_NAME)
	end)

	-- Clean up notification if it exists
	pcall(function()
		if notificationGui and notificationGui.Parent then
			notificationGui:Destroy()
			notificationGui = nil
		end
	end)

	print("Input blocking disabled - invisibility ended")
end

-- Save original transparency values of all parts
local function saveOriginalState()
	originalTransparencies = {}

	-- Traverse all descendants to save transparency values
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") or 
			part:IsA("Decal") or part:IsA("Texture") or 
			part:IsA("Shirt") or part:IsA("Pants") or 
			part:IsA("ShirtGraphic") then

			-- Get unique path for this part to help with restoration
			local path = getInstancePath(part)
			if path then
				-- Store the EXACT current transparency
				originalTransparencies[path] = part.Transparency
			end
		end
	end

	local transparencyCount = 0
	for _ in pairs(originalTransparencies) do
		transparencyCount = transparencyCount + 1
	end
	print("Saved original transparency state for " .. transparencyCount .. " parts")
end

-- Convert transparencies to a format that can be sent to the server
local function getTransparencyData()
	local data = {}
	for path, transparency in pairs(originalTransparencies) do
		data[path] = transparency
	end
	return data
end

-- Set character visibility
local function setCharacterVisibility(makeInvisible)
	-- Guard against errors
	if not originalTransparencies or not next(originalTransparencies) then
		warn("No transparency data saved, cannot change visibility properly")
		saveOriginalState() -- Try to save state now as fallback
	end

	-- Set visibilityRestorationAttempted flag if we're restoring visibility
	if not makeInvisible then
		visibilityRestorationAttempted = true
	end

	-- Find all character parts to set visibility
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") or 
			part:IsA("Decal") or part:IsA("Texture") or 
			part:IsA("Shirt") or part:IsA("Pants") or 
			part:IsA("ShirtGraphic") then

			-- Skip silhouette parts (important - this ensures silhouette stays visible)
			if part:IsDescendantOf(character:FindFirstChild("SilhouetteESP")) then
				continue
			end

			pcall(function()
				local path = getInstancePath(part)

				if makeInvisible then
					part.Transparency = 1
				else
					-- Use the EXACT original transparency if we have it
					if path and originalTransparencies[path] ~= nil then
						part.Transparency = originalTransparencies[path]
					else
						-- For parts we don't have data for (rare case), use default
						part.Transparency = part:GetAttribute("DefaultTransparency") or 0
					end
				end
			end)
		end
	end

	-- Notify server about visibility change and send original transparency data
	pcall(function()
		invisibilityEvent:FireServer(makeInvisible, getTransparencyData())
	end)

	print("Character visibility set to " .. (makeInvisible and "invisible" or "visible") .. " (silhouette still visible)")
end

-- Force visibility restoration in case normal methods fail
forceVisibilityRestoration = function()
	print("Forcing visibility restoration")

	-- Make sure all invisibility effects are gone
	isInvisible = false
	humanoid:SetAttribute("Invisible", false)

	-- Restore original animations
	pcall(function()
		restoreAnimateScriptAnimations()
	end)

	-- Restore original transparencies
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") or 
			part:IsA("Decal") or part:IsA("Texture") or 
			part:IsA("Shirt") or part:IsA("Pants") or 
			part:IsA("ShirtGraphic") then

			pcall(function()
				local path = getInstancePath(part)
				if path and originalTransparencies[path] ~= nil then
					part.Transparency = originalTransparencies[path]
				else
					part.Transparency = part:GetAttribute("DefaultTransparency") or 0
				end
			end)
		end
	end

	-- Tell server we're visible and send transparency data
	pcall(function()
		invisibilityEvent:FireServer(false, getTransparencyData())
	end)

	print("Force visibility restoration complete")

	-- Make sure to clean up other states
	disableInputBlocking()
	removeAllESP()
	silhouetteParts = {}

	-- Stop any countdown
	if countdownConnection then
		countdownConnection:Disconnect()
		countdownConnection = nil
	end

	-- Remove any remaining GUIs
	if player.PlayerGui:FindFirstChild("InvisibilityTimer") then
		player.PlayerGui.InvisibilityTimer:Destroy()
	end
	if player.PlayerGui:FindFirstChild("CooldownTimer") then
		player.PlayerGui.CooldownTimer:Destroy()
	end
end

-- Create silhouette parts that remember your shape when invisible
local function createSilhouette()
	-- First, clear any existing silhouette
	for _, part in pairs(silhouetteParts) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	silhouetteParts = {}

	-- Create a container to hold all silhouette parts
	local silhouetteFolder = Instance.new("Folder")
	silhouetteFolder.Name = "SilhouetteESP"
	silhouetteFolder.Parent = character

	-- Clone visible parts of the character to create the silhouette
	for _, part in pairs(character:GetDescendants()) do
		if (part:IsA("BasePart") or part:IsA("MeshPart")) and not part.Name:match("HumanoidRootPart") then
			local path = getInstancePath(part)
			local originalTransparency = path and originalTransparencies[path] or part.Transparency

			-- Only clone non-fully-transparent parts
			if originalTransparency < 0.95 then
				local silhouettePart = part:Clone()

				-- Remove any scripts or constraints
				for _, child in pairs(silhouettePart:GetDescendants()) do
					if child:IsA("Script") or child:IsA("LocalScript") or
						child:IsA("Constraint") or child:IsA("Weld") then
						child:Destroy()
					end
				end

				-- Make it translucent and non-collidable
				silhouettePart.Transparency = SILHOUETTE_TRANSPARENCY
				silhouettePart.CanCollide = false
				silhouettePart.Massless = true
				silhouettePart.CastShadow = false

				-- Make it brighter and more visible
				silhouettePart.Material = Enum.Material.Neon
				silhouettePart.Color = Color3.fromRGB(255, 0, 0) -- Red color

				-- Create a weld to keep it attached to the original part
				local weld = Instance.new("Weld")
				weld.Part0 = part
				weld.Part1 = silhouettePart
				weld.C0 = CFrame.new(0, 0, 0)
				weld.C1 = CFrame.new(0, 0, 0)
				weld.Parent = silhouettePart

				-- Add to silhouette folder
				silhouettePart.Parent = silhouetteFolder

				-- Keep track of it
				table.insert(silhouetteParts, silhouettePart)
			end
		end
	end

	-- Create a highlight for the whole character as well
	local highlight = Instance.new("Highlight")
	highlight.Name = "SilhouetteHighlight"
	highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Red
	highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
	highlight.FillTransparency = 0.8
	highlight.OutlineTransparency = 0.3
	highlight.Adornee = character
	highlight.Parent = silhouetteFolder

	table.insert(silhouetteParts, highlight)
	table.insert(silhouetteParts, silhouetteFolder)

	print("Created silhouette with " .. (#silhouetteParts - 2) .. " parts")

	return silhouetteFolder
end

-- Remove silhouette
local function removeSilhouette()
	for _, part in pairs(silhouetteParts) do
		if part and part.Parent then
			pcall(function() part:Destroy() end)
		end
	end
	silhouetteParts = {}

	-- Also remove the container if it exists
	local silhouetteFolder = character:FindFirstChild("SilhouetteESP")
	if silhouetteFolder then
		pcall(function() silhouetteFolder:Destroy() end)
	end

	print("Removed silhouette")
end

-- Create ESP for survivors
local function createSurvivorESP()
	-- Create ESP for all survivors
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character and
			otherPlayer.Team and otherPlayer.Team.Name == TEAM_SURVIVOR then
			local survivorHighlight = Instance.new("Highlight")
			survivorHighlight.Name = "SurvivorESP"
			survivorHighlight.OutlineColor = Color3.fromRGB(255, 217, 0)
			survivorHighlight.OutlineTransparency = 0.3
			survivorHighlight.Adornee = otherPlayer.Character
			survivorHighlight.Parent = otherPlayer.Character
		end
	end
end

-- Remove all ESP
removeAllESP = function()
	-- Remove silhouette
	removeSilhouette()

	-- Remove survivor ESP
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer.Character then
			for _, item in pairs(otherPlayer.Character:GetChildren()) do
				if item.Name == "SurvivorESP" then
					pcall(function() item:Destroy() end)
				end
			end
		end
	end
end

-- Create invisibility timer GUI
local function createInvisibilityTimerGUI(duration)
	-- Remove existing timer if any
	if player.PlayerGui:FindFirstChild("InvisibilityTimer") then
		player.PlayerGui.InvisibilityTimer:Destroy()
	end

	-- Create new timer
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InvisibilityTimer"
	screenGui.Parent = player.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 50)
	frame.Position = UDim2.new(0.5, -100, 0.1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 2
	frame.Parent = screenGui

	local label = Instance.new("TextLabel")
	label.Name = "CountdownLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = "Invisible: " .. duration .. "s"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = frame

	return screenGui, label
end

-- Create cooldown timer GUI
local function createCooldownTimerGUI(duration)
	-- Remove existing timer if any
	if player.PlayerGui:FindFirstChild("CooldownTimer") then
		player.PlayerGui.CooldownTimer:Destroy()
	end

	-- Create new timer
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CooldownTimer"
	screenGui.Parent = player.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 50)
	frame.Position = UDim2.new(0.5, -100, 0.1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 2
	frame.Parent = screenGui

	local label = Instance.new("TextLabel")
	label.Name = "CountdownLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = "Cooldown: " .. duration .. "s"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = frame

	return screenGui, label
end

-- Activate invisibility
activateInvisibility = function()
	if isInvisible or onCooldown then
		local reason = isInvisible and "already invisible" or "on cooldown"
		print("Cannot activate invisibility: " .. reason)
		return
	end

	print("Activating invisibility")

	-- Find and save animations first
	findAnimateScript()
	saveOriginalAnimationSettings()
	loadInvisibleAnimations()

	-- Save original state before changing anything
	saveOriginalState()

	-- Update state flags
	isInvisible = true
	visibilityRestorationAttempted = false
	humanoid:SetAttribute("Invisible", true)

	-- Enable input blocking
	enableInputBlocking()

	-- Create silhouette BEFORE making character invisible
	-- This ensures you can see yourself while invisible
	createSilhouette()

	-- Override animations in Animate script
	overrideAnimateScriptAnimations()

	-- Create survivor ESP
	createSurvivorESP()

	-- Make character invisible locally (but not the silhouette)
	setCharacterVisibility(true)

	-- Create countdown message on screen
	local screenGui, label = createInvisibilityTimerGUI(INVISIBILITY_DURATION)

	-- Start countdown
	local timeLeft = INVISIBILITY_DURATION
	if countdownConnection then
		countdownConnection:Disconnect()
	end

	countdownConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not isInvisible then
			if countdownConnection then
				countdownConnection:Disconnect()
				countdownConnection = nil
			end
			return
		end

		timeLeft = timeLeft - deltaTime
		if timeLeft <= 0 then
			if countdownConnection then
				countdownConnection:Disconnect()
				countdownConnection = nil
			end
			deactivateInvisibility()
			return
		end

		if label and label.Parent then
			label.Text = "Invisible: " .. math.floor(timeLeft + 0.5) .. "s"
		end
	end)

	-- Setup a failsafe timer to ensure visibility is restored
	task.delay(INVISIBILITY_DURATION + 1, function()
		if isInvisible and not visibilityRestorationAttempted then
			print("Failsafe timer triggered - force restoring visibility")
			forceVisibilityRestoration()
		end
	end)
end

-- Deactivate invisibility
deactivateInvisibility = function()
	if not isInvisible then
		print("Not invisible, cannot deactivate")
		return
	end

	print("Deactivating invisibility")

	-- Update state flags first to prevent re-entry
	isInvisible = false
	humanoid:SetAttribute("Invisible", false)

	-- Create a flag to track deactivation in progress
	local deactivatingFlag = Instance.new("BoolValue")
	deactivatingFlag.Name = "DeactivatingInvisibility"
	deactivatingFlag.Value = true
	deactivatingFlag.Parent = character

	-- Disable input blocking immediately
	disableInputBlocking()

	-- Stop countdown if it's still running
	if countdownConnection then
		countdownConnection:Disconnect()
		countdownConnection = nil
	end

	-- Clean up timer GUI
	if player.PlayerGui:FindFirstChild("InvisibilityTimer") then
		player.PlayerGui.InvisibilityTimer:Destroy()
	end

	-- Only remove survivor ESP - keep silhouette for self visibility
	pcall(function()
		-- Remove survivor ESP
		for _, otherPlayer in pairs(Players:GetPlayers()) do
			if otherPlayer.Character then
				for _, item in pairs(otherPlayer.Character:GetChildren()) do
					if item.Name == "SurvivorESP" then
						pcall(function() item:Destroy() end)
					end
				end
			end
		end

		-- We'll remove silhouette after a delay to let player see themselves appear
		task.delay(0.5, function()
			removeSilhouette()
		end)
	end)

	-- Play appear animation and sound (both locally and tell server to play for everyone)
	pcall(function()
		appearAnimTrack:Play()
		appearSound:Play()

		-- Tell server to play sound for everyone else
		invisibilityEvent:FireServer(false, getTransparencyData(), true) -- Third parameter indicates to play sound
	end)

	-- Restore visibility immediately after playing appear animation
	pcall(function()
		setCharacterVisibility(false)
	end)

	-- After a short delay, restore animations and do a final visibility check
	task.delay(0.3, function()
		-- Restore original animations
		pcall(function()
			restoreAnimateScriptAnimations()
		end)

		-- Double-check visibility state
		pcall(function()
			setCharacterVisibility(false)
		end)

		-- Remove deactivation flag
		if deactivatingFlag and deactivatingFlag.Parent then
			deactivatingFlag:Destroy()
		end
	end)

	-- Failsafe - check once more after 1 second
	task.delay(1, function()
		if not visibilityRestorationAttempted then
			print("Visibility restoration failsafe triggered")
			forceVisibilityRestoration()
		end
	end)

	-- Start cooldown
	startCooldown()
end

-- Start cooldown timer
startCooldown = function()
	onCooldown = true

	-- Create cooldown UI
	local screenGui, label = createCooldownTimerGUI(COOLDOWN_TIME)

	-- Start cooldown timer
	local timeLeft = COOLDOWN_TIME
	local cooldownConnection
	cooldownConnection = RunService.Heartbeat:Connect(function(deltaTime)
		timeLeft = timeLeft - deltaTime
		if timeLeft <= 0 then
			cooldownConnection:Disconnect()
			onCooldown = false
			if player.PlayerGui:FindFirstChild("CooldownTimer") then
				player.PlayerGui.CooldownTimer:Destroy()
			end

			-- Show ready message briefly
			local readyGui = Instance.new("ScreenGui")
			readyGui.Name = "ReadyNotification"
			readyGui.Parent = player.PlayerGui

			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(0, 200, 0, 50)
			frame.Position = UDim2.new(0.5, -100, 0.1, 0)
			frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			frame.BackgroundTransparency = 0.5
			frame.BorderSizePixel = 2
			frame.Parent = readyGui

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.Text = "Invisibility Ready!"
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBold
			label.TextScaled = true
			label.Parent = frame

			-- Remove ready message after 2 seconds
			task.delay(2, function()
				if readyGui and readyGui.Parent then
					readyGui:Destroy()
				end
			end)

			return
		end

		if label and label.Parent then
			label.Text = "Cooldown: " .. math.floor(timeLeft + 0.5) .. "s"
		end
	end)
end

-- Listen for key presses
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E then
		-- Only proceed if this is a clean E press that won't interfere with other systems
		pcall(function()
			if isInvisible then
				deactivateInvisibility()
			else
				activateInvisibility()
			end
		end)
	end
end)

-- Handle invisible event from server (for other players)
invisibilityEvent.OnClientEvent:Connect(function(playerId, isInvisibleState, transparencyData)
	-- Process events for other players
	if playerId ~= player.UserId then
		local otherPlayer = Players:GetPlayerByUserId(playerId)
		if otherPlayer and otherPlayer.Character then
			if isInvisibleState then
				-- Make other player invisible
				for _, part in pairs(otherPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") or part:IsA("MeshPart") or 
						part:IsA("Decal") or part:IsA("Texture") or 
						part:IsA("Shirt") or part:IsA("Pants") or 
						part:IsA("ShirtGraphic") then
						part.Transparency = 1
					end
				end
			else
				-- Make other player visible using provided transparencies if available
				if transparencyData then
					for path, transparency in pairs(transparencyData) do
						-- Try to find the part using the path
						local success, part = pcall(function()
							return otherPlayer.Character:FindFirstChild(path, true)
						end)

						if success and part then
							pcall(function()
								part.Transparency = transparency
							end)
						end
					end
				else
					-- Fallback to making everything visible
					for _, part in pairs(otherPlayer.Character:GetDescendants()) do
						if part:IsA("BasePart") or part:IsA("MeshPart") or 
							part:IsA("Decal") or part:IsA("Texture") or 
							part:IsA("Shirt") or part:IsA("Pants") or 
							part:IsA("ShirtGraphic") then
							part.Transparency = 0
						end
					end
				end
			end
		end
	end
end)

-- Set up death handling to restore visibility if you die while invisible
humanoid.Died:Connect(function()
	if isInvisible then
		print("Died while invisible - forcing visibility restoration")
		forceVisibilityRestoration()
	end
end)

-- Initialize the script
local function init()
	print("Initializing invisibility system...")

	-- Find Animate script
	findAnimateScript()

	-- Make sure we note default transparencies for parts that are meant to be invisible
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") or 
			part:IsA("Decal") or part:IsA("Texture") or 
			part:IsA("Shirt") or part:IsA("Pants") or 
			part:IsA("ShirtGraphic") then

			-- Store current transparency as the default
			part:SetAttribute("DefaultTransparency", part.Transparency)
		end
	end

	-- Load animations for later use
	task.spawn(function()
		loadInvisibleAnimations()
	end)

	print("Complete Invisibility System loaded! Press E to toggle invisibility.")
end

-- Run the initialization
init()

-- Controller support for Invisibility
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	-- X button to toggle invisibility
	if input.KeyCode == Enum.KeyCode.ButtonX then
		if humanoid:GetAttribute("Dashing") then return end -- Don't activate during dash

		if isInvisible then
			deactivateInvisibility()
		else
			activateInvisibility()
		end
	end
end)

-- Also block RT and Y when invisible (matching F and Q keys)
local function handleBlockedControllerInput(input, processed)
	if processed then return end

	-- Only block these inputs when invisible
	if not isInvisible then return end

	-- Block RT (matching F key)
	if input.KeyCode == Enum.KeyCode.ButtonR2 then
		createInputBlockedNotification("RT (Melee)")
		return Enum.ContextActionResult.Sink
	end

	-- Block Y (matching Q key)
	if input.KeyCode == Enum.KeyCode.ButtonY then
		createInputBlockedNotification("Y (Laugh)")
		return Enum.ContextActionResult.Sink
	end
end

-- Add to context actions during invisibility
local function enableControllerInputBlocking()
	if inputsBlocked then return end

	ContextActionService:BindAction(
		"BlockControllerDuringInvisibility",
		handleBlockedControllerInput,
		false,
		Enum.KeyCode.ButtonR2,
		Enum.KeyCode.ButtonY
	)
end

-- Remove from context actions when visibility restored
local function disableControllerInputBlocking()
	ContextActionService:UnbindAction("BlockControllerDuringInvisibility")
end

-- Add these to your enableInputBlocking function
local originalEnableInputBlocking = enableInputBlocking
enableInputBlocking = function()
	originalEnableInputBlocking()
	enableControllerInputBlocking()
end

-- Add these to your disableInputBlocking function
local originalDisableInputBlocking = disableInputBlocking
disableInputBlocking = function()
	originalDisableInputBlocking()
	disableControllerInputBlocking()
end