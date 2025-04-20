local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShockShieldEvent = ReplicatedStorage:WaitForChild("ShockShieldEvent") -- RemoteEvent for shield

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid) -- Ensure animator exists
local root = char:WaitForChild("HumanoidRootPart")

local shockCooldown = false  
local cooldownDuration = 15  

-- Shockwave activation animation
local shockActivateAnim = Instance.new("Animation")
shockActivateAnim.AnimationId = "rbxassetid://129769688492032"  -- Replace with correct animation ID

local function activateShockShield()
	if shockCooldown then return end  
	shockCooldown = true  

	-- Play activation animation
	local animTrack = animator:LoadAnimation(shockActivateAnim)
	animTrack:Play()

	-- Play activation sound (audible to everyone)
	local activateSound = Instance.new("Sound")
	activateSound.SoundId = "rbxassetid://YOUR_ACTIVATION_SOUND_ID" -- Replace with actual sound ID
	activateSound.Volume = 2
	activateSound.Parent = root
	activateSound:Play()

	-- Fire event to server to create the shield
	ShockShieldEvent:FireServer()

	-- Cooldown before Survivor can use shield again
	task.delay(cooldownDuration, function()
		shockCooldown = false  
	end)
end

-- Bind key input to activate shield
game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		activateShockShield()
	end
end)
