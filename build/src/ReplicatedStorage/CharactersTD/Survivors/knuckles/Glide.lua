-- Glide System - LOCAL SCRIPT
-- Place this in StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Configuration
local GLIDE_KEY = Enum.KeyCode.Q         -- Keyboard key to activate gliding
local GLIDE_GAMEPAD_INPUT = Enum.KeyCode.ButtonY  -- Changed from ButtonL2 to ButtonY
local GLIDE_FALL_SPEED = -15             -- Vertical speed while gliding (negative = down)
local GLIDE_MOVE_SPEED = 28              -- Base movement speed while gliding
local GLIDE_COOLDOWN = 3                 -- Cooldown in seconds
local GLIDE_MAX_DURATION = 5             -- Maximum glide duration in seconds
local GLIDE_SOUND_ID = "rbxassetid://6415581306" -- Wind sound effect

-- Animation setup
local GLIDE_ANIMATION_ID = "rbxassetid://83080938577482" -- Replace with your actual gliding animation ID

-- States and variables
local isGliding = false
local canGlide = true
local wasInAir = false
local onCooldown = false
local isLanding = false  -- Add this to prevent race conditions
local glideSound = nil
local glideAnimTrack = nil
local bodyGyro = nil
local bodyVelocity = nil
local glideStartTime = 0
local durationIndicator = nil

-- Create RemoteEvent for informing the server about gliding
local glideEvent = ReplicatedStorage:FindFirstChild("GlideEvent")
if not glideEvent then
	glideEvent = Instance.new("RemoteEvent")
	glideEvent.Name = "GlideEvent"
	glideEvent.Parent = ReplicatedStorage
end

-- Function declarations
local stopGliding

local function createCooldownUI(duration)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GlideCooldown"
	screenGui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 30)
	frame.Position = UDim2.new(0.5, -100, 0.8, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0

	local cornerRadius = Instance.new("UICorner")
	cornerRadius.CornerRadius = UDim.new(0, 8)
	cornerRadius.Parent = frame

	local text = Instance.new("TextLabel")
	text.Name = "CooldownText"
	text.Text = "Glide Cooldown: " .. duration .. "s"
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 16
	text.Parent = frame

	frame.Parent = screenGui
	screenGui.Parent = player.PlayerGui

	return screenGui, text
end

local function createDurationIndicator()
    if durationIndicator then
        durationIndicator:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GlideDuration"
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 30)
    frame.Position = UDim2.new(0.5, -100, 0.7, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 8)
    cornerRadius.Parent = frame
    
    local text = Instance.new("TextLabel")
    text.Name = "DurationText"
    text.Text = "Glide Time: " .. GLIDE_MAX_DURATION .. "s"
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 16
    text.Parent = frame
    
    frame.Parent = screenGui
    screenGui.Parent = player.PlayerGui
    
    durationIndicator = screenGui
    return text
end

local function startCooldown()
    if onCooldown then return end  -- Prevent multiple cooldowns
    onCooldown = true
    canGlide = false

    -- Create cooldown UI
    local screenGui, cooldownText = createCooldownUI(GLIDE_COOLDOWN)

    -- Count down
    for i = GLIDE_COOLDOWN, 1, -1 do
        if not onCooldown then break end -- Exit if reset
        cooldownText.Text = "Glide Cooldown: " .. i .. "s"
        wait(1)
    end

    -- Clean up and reset states
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
    onCooldown = false
    canGlide = true
    isGliding = false
    
    print("Glide cooldown finished - Ready to glide again")
end

stopGliding = function()
    if not isGliding then return end
    if isLanding then return end

    isLanding = true

    -- Clean up physics objects
    if bodyGyro and bodyGyro.Parent then
        bodyGyro:Destroy()
        bodyGyro = nil
    end

    if bodyVelocity and bodyVelocity.Parent then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end

    -- Stop animation and sound
    if glideAnimTrack and glideAnimTrack.IsPlaying then
        glideAnimTrack:Stop()
    end

    if glideSound and glideSound.IsPlaying then
        glideSound:Stop()
    end

    -- Tell server we stopped
    glideEvent:FireServer(false)

    -- Clean up notification
    local notificationPath = character:GetAttribute("GlideNotification")
    if notificationPath then
        local notification = player.PlayerGui:FindFirstChild(notificationPath)
        if notification then
            notification:Destroy()
        end
        character:SetAttribute("GlideNotification", nil)
    end

    -- Clean up duration indicator
    if durationIndicator then
        durationIndicator:Destroy()
        durationIndicator = nil
    end

    -- Reset states
    isGliding = false
    
    -- Start cooldown if we weren't already on it
    if canGlide and not onCooldown then
        spawn(function()
            startCooldown()
        end)
    end

    -- Reset landing state after a short delay
    spawn(function()
        task.wait(0.1)
        isLanding = false
    end)
end

local function loadGlideAnimation()
	if glideAnimTrack then
		return glideAnimTrack
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = GLIDE_ANIMATION_ID
	glideAnimTrack = humanoid:LoadAnimation(animation)
	glideAnimTrack.Looped = true
	glideAnimTrack.Priority = Enum.AnimationPriority.Action

	return glideAnimTrack
end

local function setupGlideSound()
	if glideSound then
		return glideSound
	end

	glideSound = Instance.new("Sound")
	glideSound.SoundId = GLIDE_SOUND_ID
	glideSound.Volume = 0.5
	glideSound.Looped = true
	glideSound.Parent = character.HumanoidRootPart

	return glideSound
end

local function startGliding()
    if not canGlide or onCooldown or isGliding then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Check if the player is in the air
    if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
        return -- Only allow gliding when falling
    end

    isGliding = true

    -- Create BodyGyro to control orientation
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 10000
    bodyGyro.D = 100
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root

    -- Create BodyVelocity to control movement
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, GLIDE_FALL_SPEED, 0)
    bodyVelocity.Parent = root

    -- Play animation
    local animTrack = loadGlideAnimation()
    animTrack:Play()

    -- Play sound
    local sound = setupGlideSound()
    sound:Play()

    -- Tell the server we're gliding
    glideEvent:FireServer(true)

    -- Show gliding effect
    local notification = Instance.new("TextLabel")
    notification.Size = UDim2.new(0, 200, 0, 30)
    notification.Position = UDim2.new(0.5, -100, 0.6, 0)
    notification.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notification.BackgroundTransparency = 0.5
    notification.TextColor3 = Color3.fromRGB(255, 255, 255)
    notification.Text = "GLIDING"
    notification.Font = Enum.Font.GothamBold
    notification.TextSize = 18
    notification.Parent = player.PlayerGui

    -- Store for later removal
    character:SetAttribute("GlideNotification", notification:GetFullName())

    -- Set glide start time and create duration indicator
    glideStartTime = tick()
    local durationText = createDurationIndicator()

    -- Start duration countdown
    spawn(function()
        while isGliding do
            local timeLeft = math.max(0, GLIDE_MAX_DURATION - (tick() - glideStartTime))
            if durationText and durationText.Parent then
                durationText.Text = "Glide Time: " .. string.format("%.1f", timeLeft) .. "s"
            end
            
            if timeLeft <= 0 then
                stopGliding()
                break
            end
            
            wait(0.1)
        end
    end)

    print("Started gliding")
end

-- Update the movement code in the RunService.Heartbeat connection
RunService.Heartbeat:Connect(function(deltaTime)
    if not isGliding then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local camera = workspace.CurrentCamera
    if not camera then return end

    -- Get input for all directions
    local moveVector = Vector3.new(0, 0, 0)
    
    -- Get gamepad input with improved handling
    local gamepad = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
    local leftStick = nil
    
    -- Find thumbstick input
    for _, state in pairs(gamepad) do
        if state.KeyCode == Enum.KeyCode.Thumbstick1 then
            leftStick = state
            break
        end
    end
    
    -- Handle both controller and keyboard input
    if leftStick and leftStick.Position.Magnitude > 0.2 then -- Controller input
        -- Get camera-relative direction vectors
        local flatForward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
        local flatRight = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z).Unit
        
        -- Convert thumbstick to world movement
        moveVector = (flatRight * leftStick.Position.X) + (flatForward * -leftStick.Position.Y)
    else -- Keyboard input
        -- Get camera-relative direction vectors
        local flatForward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
        local flatRight = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z).Unit
        
        -- Combine all keyboard inputs
        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
            moveVector = moveVector + flatForward
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
            moveVector = moveVector - flatForward
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
            moveVector = moveVector - flatRight
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
            moveVector = moveVector + flatRight
        end
    end

    -- Normalize movement vector if it exists
    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit
    end

    -- Apply movement
    local horizontalVelocity = moveVector * GLIDE_MOVE_SPEED
    local verticalVelocity = Vector3.new(0, GLIDE_FALL_SPEED, 0)
    local finalVelocity = horizontalVelocity + verticalVelocity

    if bodyVelocity then
        bodyVelocity.Velocity = finalVelocity
    end

    -- Keep character level while gliding
    if bodyGyro then
        local targetCFrame
        if moveVector.Magnitude > 0 then
            -- Face the direction we're moving
            targetCFrame = CFrame.new(root.Position, root.Position + moveVector)
        else
            -- Face camera direction when not moving
            local flatLook = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
            targetCFrame = CFrame.new(root.Position, root.Position + flatLook)
        end
        
        -- Keep the character level
        targetCFrame = targetCFrame * CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
        bodyGyro.CFrame = targetCFrame
    end
end)

-- Monitor when player enters/exits air state
RunService.Heartbeat:Connect(function()
    if not character or not humanoid then return end
    
    local isInAir = humanoid:GetState() == Enum.HumanoidStateType.Freefall or
        humanoid:GetState() == Enum.HumanoidStateType.Jumping

    if isInAir and not wasInAir then
        wasInAir = true
        -- Only allow gliding if not on cooldown
        if not onCooldown then
            canGlide = true
        end
    elseif not isInAir and wasInAir then
        wasInAir = false
        
        if isGliding then
            stopGliding()
        end
    end
end)

-- Handle key press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Check for both keyboard and controller inputs
    if input.KeyCode == GLIDE_KEY or input.KeyCode == GLIDE_GAMEPAD_INPUT then
        if not isGliding and canGlide and not onCooldown then
            startGliding()
        elseif isGliding then
            stopGliding()
        end
    end
end)

-- Handle character respawn
local function onCharacterAdded(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")

	-- Reset states
	isGliding = false
	canGlide = true
	wasInAir = false
	onCooldown = false
	bodyGyro = nil
	bodyVelocity = nil
	glideAnimTrack = nil

	-- Set up sound on new character
	glideSound = nil
	setupGlideSound()

	print("Character reset - glide system ready")
end

player.CharacterAdded:Connect(onCharacterAdded)

print("Glide system initialized - Press " .. GLIDE_KEY.Name .. " or use Y button to glide while in the air")