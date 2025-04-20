local FLOAT_FORCE = 9000000000 -- Adjust for more/less float
local GLIDE_KEY = Enum.KeyCode.E -- Key to start flying
local JUMP_KEY = Enum.KeyCode.Space -- Key to ascend

local MAX_ENERGY = 100 -- Max energy Tails can use
local ENERGY_DRAIN_RATE = 10 -- Energy drain per second while flying
local ASCEND_DRAIN_MULTIPLIER = 2 -- Extra drain when ascending
local ENERGY_RECHARGE_RATE = 20 -- Energy per second when on the ground
local COOLDOWN_TIME = 2 -- Time before you can fly again (in seconds)

local UPWARD_SPEED = 7 -- Moving up
local DOWNWARD_SPEED = -10 -- Moving down
local UPWARD_ANIM_SPEED = 1.3 -- Faster animation when ascending
local DOWNWARD_ANIM_SPEED = 0.7 -- Slower animation when descending

local LOW_ENERGY_SOUND_SPEED = 0.6 -- Slower sound when out of energy

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local GlideSound = script:WaitForChild("Tails glide")

-- Animations
local glideAnim = Instance.new("Animation")
glideAnim.AnimationId = "rbxassetid://99283944620199"
local playGlideAnim = humanoid:LoadAnimation(glideAnim)

local holding = false
local ascending = false
local canFly = true -- Prevents infinite flight spam
local energy = MAX_ENERGY -- Energy starts at full
local glidingDown = false

-- Function to stop gliding (Used when landing or time runs out)
local function stopGliding()
	holding = false
	glidingDown = false
	if hrp:FindFirstChild("GlideForce") then
		hrp.GlideForce:Destroy()
	end
	playGlideAnim:Stop()
	GlideSound:Stop()
	print("Gliding stopped!")

	-- Start cooldown before you can fly again
	canFly = false
	task.wait(COOLDOWN_TIME)
	canFly = true
	energy = MAX_ENERGY -- Refill energy after cooldown
	print("Flight recharged!")
end

-- Detect Landing (Stops flight when touching ground)
humanoid.StateChanged:Connect(function(_, new)
	if new == Enum.HumanoidStateType.Landed then
		stopGliding()
	end
end)

local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gpe)
	if input.KeyCode == GLIDE_KEY and not gpe and canFly and humanoid:GetState() ~= Enum.HumanoidStateType.Landed then
		if humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping then
			holding = true
			ascending = false 
		end
	end
	if input.KeyCode == JUMP_KEY and holding then
		ascending = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == JUMP_KEY and holding then
		ascending = false
	end
end)

local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function(dt)
	if holding then
		-- Calculate energy drain
		local energyDrain = ENERGY_DRAIN_RATE * dt
		if ascending then
			energyDrain = energyDrain * ASCEND_DRAIN_MULTIPLIER
		end

		energy = energy - energyDrain -- Drain energy

		-- If energy runs out, force glide down
		if energy <= 0 then
			energy = 0
			print("Energy depleted! Glide down forced.")
			glidingDown = true
			hrp.GlideForce.Velocity = Vector3.new(0, DOWNWARD_SPEED, 0)
			playGlideAnim:AdjustSpeed(DOWNWARD_ANIM_SPEED)

			-- Slow down the glide sound when energy runs out
			if GlideSound.PlaybackSpeed ~= LOW_ENERGY_SOUND_SPEED then
				GlideSound.PlaybackSpeed = LOW_ENERGY_SOUND_SPEED
				print("Glide sound slowed down!")
			end

			if not GlideSound.IsPlaying then
				GlideSound:Play()
			end
		else
			if not hrp:FindFirstChild("GlideForce") then
				local glideForce = Instance.new("BodyVelocity")
				glideForce.Name = "GlideForce"
				glideForce.MaxForce = Vector3.new(0, FLOAT_FORCE, 0)
				glideForce.Parent = hrp
				GlideSound:Play()
				playGlideAnim:Play()
				print("Gliding started")
			end

			-- Reset sound speed when energy is above 0
			if GlideSound.PlaybackSpeed ~= 1 then
				GlideSound.PlaybackSpeed = 1
				print("Glide sound speed restored!")
			end

			-- Adjust speed & animation based on ascending or descending
			if ascending then
				hrp.GlideForce.Velocity = Vector3.new(0, UPWARD_SPEED, 0)
				playGlideAnim:AdjustSpeed(UPWARD_ANIM_SPEED)
			else
				hrp.GlideForce.Velocity = Vector3.new(0, DOWNWARD_SPEED, 0)
				playGlideAnim:AdjustSpeed(DOWNWARD_ANIM_SPEED)
			end

			glidingDown = false
		end
	else
		-- Recharge energy when grounded
		if energy < MAX_ENERGY and humanoid:GetState() == Enum.HumanoidStateType.Landed then
			energy = math.min(energy + (ENERGY_RECHARGE_RATE * dt), MAX_ENERGY)
		end

		stopGliding()
	end
end)

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local GlideSound = script:WaitForChild("Tails glide")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playGlideSoundEvent = ReplicatedStorage:WaitForChild("PlayGlideSoundEvent")

-- Other variables and functions...

local function startGliding()
	-- Your existing glide start logic...

	-- Play the glide sound locally
	GlideSound:Play()

	-- Fire the RemoteEvent to play the glide sound for all players
	playGlideSoundEvent:FireServer()
end

-- Rest of your glide logic...
