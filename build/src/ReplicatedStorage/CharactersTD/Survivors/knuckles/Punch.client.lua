local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents if they don't exist
local MeleeStunEvent = ReplicatedStorage:FindFirstChild("MeleeStunEvent")
if not MeleeStunEvent then
	MeleeStunEvent = Instance.new("RemoteEvent")
	MeleeStunEvent.Name = "MeleeStunEvent"
	MeleeStunEvent.Parent = ReplicatedStorage
end

local PunchSoundEvent = ReplicatedStorage:FindFirstChild("PunchSoundEvent")
if not PunchSoundEvent then
	PunchSoundEvent = Instance.new("RemoteEvent")
	PunchSoundEvent.Name = "PunchSoundEvent"
	PunchSoundEvent.Parent = ReplicatedStorage
end

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid) -- Ensure animator exists

-- Punch animation
local punchAnim = Instance.new("Animation")
punchAnim.AnimationId = "rbxassetid://88785427345398" -- Replace with actual animation ID

local cooldown = 15 -- Punch cooldown
local canPunch = true -- Prevent spam punching
local punchSpeed = 1.2 -- **⚡ Adjust this to change punch animation speed**
local hitboxSize = Vector3.new(4, 4, 4) -- Size of the punch hitbox
local hitboxDistance = 3 -- Distance in front of the player

-- Handle character reloading
player.CharacterAdded:Connect(function(newChar)
	char = newChar
	humanoid = char:WaitForChild("Humanoid")
	animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
end)

local function performPunch()
	if not canPunch then return end
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	canPunch = false

	-- Play punch animation
	local punchTrack = animator:LoadAnimation(punchAnim)
	punchTrack:Play()
	punchTrack:AdjustSpeed(punchSpeed) -- **Set animation speed**

	-- 🔊 Play "miss" sound initially
	PunchSoundEvent:FireServer(char, "Miss")

	-- Create hitbox
	local hitbox = Instance.new("Part")
	hitbox.Size = hitboxSize
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.Anchored = true
	hitbox.Parent = char
	hitbox.Position = char.HumanoidRootPart.Position + (char.HumanoidRootPart.CFrame.LookVector * hitboxDistance)

	-- Check for EXE hit
	local hitSuccess = false
	for _, target in pairs(game.Players:GetPlayers()) do
		if target.Team and target.Team.Name == "EXE" and target.Character then
			local exeRoot = target.Character:FindFirstChild("HumanoidRootPart")
			local exeHumanoid = target.Character:FindFirstChild("Humanoid")

			-- Skip if EXE is invisible
			if exeHumanoid and exeHumanoid:GetAttribute("Invisible") then
				continue -- Skip invisible players
			end

			if exeRoot and (exeRoot.Position - hitbox.Position).Magnitude < 3 then
				-- 🔊 Play "hit" sound
				PunchSoundEvent:FireServer(char, "Hit")

				-- Stun the EXE
				MeleeStunEvent:FireServer(target)
				hitSuccess = true
				break
			end
		end
	end

	-- Destroy hitbox after checking
	hitbox:Destroy()

	-- Cooldown before next punch
	task.wait(cooldown)
	canPunch = true
end

-- Bind input for punching
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F then -- Press "F" to punch
		performPunch()
	end
end)

-- Create feedback for player when punch is ready after cooldown
local function createPunchReadyEffect()
	-- Visual feedback when punch is ready again
	if not player.PlayerGui:FindFirstChild("PunchReadyNotification") then
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "PunchReadyNotification"

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, 200, 0, 50)
		frame.Position = UDim2.new(0.5, -100, 0.8, 0)
		frame.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
		frame.BackgroundTransparency = 0.3
		frame.BorderSizePixel = 0

		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, 10)
		uiCorner.Parent = frame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 16
		label.Text = "Punch Ready! (F)"
		label.Parent = frame

		frame.Parent = screenGui
		screenGui.Parent = player.PlayerGui

		-- Remove notification after 2 seconds
		task.delay(2, function()
			if screenGui and screenGui.Parent then
				screenGui:Destroy()
			end
		end)
	end
end

-- Show ready message on script load
task.delay(1, createPunchReadyEffect)

print("Stun Melee Local Script loaded! Press F to punch and stun EXE players.")

-- Controller support for Melee/Stun
UserInputService.InputChanged:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.ButtonR2 then -- RT button
		-- Only trigger when pressed past threshold
		if input.Position.Z > 0.7 and input.Delta.Z > 0.2 then
			performPunch() 
		end
	end
end)