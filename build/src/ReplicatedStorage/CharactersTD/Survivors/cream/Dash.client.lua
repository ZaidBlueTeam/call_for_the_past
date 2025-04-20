--[[
Created by Prexry/FierceDev/Microstung
Start by moving this into StarterPlayer > StarterPlayerScripts
Now edit the config to your liking.
]]--

local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart") -- Looks for players "HumanoidRootPart".
local keybind = Enum.KeyCode.Q -- Change this to your dash keybind.
local debounce = false -- Cooldown is not yet active at this moment.
local cooldown = 20 -- How long until the player can dash again.
local speed = 60 -- The speed of the dash.
local duration = 10 -- How long the dash will last.

local dashAnimation = Instance.new("Animation")
dashAnimation.AnimationId = "rbxassetid://0" -- Animation ID for the dash.

local dashSoundId = "rbxassetid://3084314259" -- Audio ID for the dash sound

local function dash()
	if debounce == true then
		print("Dash is on cooldown, make sure you wait "..cooldown.." seconds before using it again.") -- Prints that the user cannot use the dash until the specified time.
		return
	end
	debounce = true -- Cooldown is currently active at this moment.
	humanoid.WalkSpeed = speed -- Changes player's speed to the specified speed.
	local animationTrack = humanoid:LoadAnimation(dashAnimation) -- Specifies the Animation.
	animationTrack:Play() -- Play the specified Animation.

	-- Play dash sound
	local sound = Instance.new("Sound")
	sound.SoundId = dashSoundId
	sound.Parent = rootPart -- Attach sound to the root part so it moves with the character
	sound.Volume = 0.5 -- Adjust volume if necessary
	sound:Play()

	wait(duration) -- How long until the player will dash again referencer.
	humanoid.WalkSpeed = 14 -- Set player ack to default speed.
	wait(cooldown) -- How long until the player will be able to use the dash once more referencer.
	debounce = false -- Cooldown is no longer active.
	print("Dashed successfully.") -- Prints that the user successfully dashed.
end

game:GetService("UserInputService").InputBegan:Connect(function(input) --Keybind Trigger
	if input.KeyCode == keybind then
		dash()
	end
end)
