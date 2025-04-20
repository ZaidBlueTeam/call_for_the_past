local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DashEvent = ReplicatedStorage:WaitForChild("DashEvent")
local SurvivorHitEvent = ReplicatedStorage:WaitForChild("SurvivorHitEvent")

local WALL_HIT_ANIM = "rbxassetid://134319170245964" -- Animation for hitting wall
local DASH_HIT_SOUND = "rbxassetid://9117969717" -- Sound when hitting survivor
local DASH_WALL_SOUND = "rbxassetid://7142857558" -- Sound when hitting a wall

local DASH_DAMAGE = 3 -- Damage from dashing into a survivor

local function handleDash(player, dashSpeed, dashDuration)
	local char = player.Character
	if not char then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChild("Humanoid")
	if not root or not humanoid then return end

	local dashVelocity = Instance.new("BodyVelocity")
	dashVelocity.Velocity = root.CFrame.LookVector * dashSpeed
	dashVelocity.MaxForce = Vector3.new(50000, 0, 50000)
	dashVelocity.Parent = root

	local hitSomething = false

	-- Hitbox detection
	local hitbox = Instance.new("Part")
	hitbox.Size = Vector3.new(6, 6, 6)
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.Anchored = true
	hitbox.Parent = char

	-- Check for collisions
	local function checkCollision()
		for _, target in pairs(game.Players:GetPlayers()) do
			if target.Team and target.Team.Name == "Survivor" and target.Character then
				local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
				local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")

				if targetRoot and targetHumanoid and (targetRoot.Position - hitbox.Position).Magnitude < 4 then
					-- Apply damage & reaction
					targetHumanoid:TakeDamage(DASH_DAMAGE)
					SurvivorHitEvent:FireClient(target, "DashHit")

					-- Play hit sound
					local hitSound = Instance.new("Sound")
					hitSound.SoundId = DASH_HIT_SOUND
					hitSound.Parent = root
					hitSound:Play()
					game.Debris:AddItem(hitSound, 2)

					hitSomething = true
					break
				end
			end
		end
	end

	-- Stop dash function
	local function stopDash()
		dashVelocity:Destroy()
		hitbox:Destroy()

		-- If hit a survivor, stop dash immediately
		if hitSomething then return end

		-- If EXE hits a wall
		local ray = Ray.new(root.Position, root.CFrame.LookVector * 5)
		local hit = workspace:FindPartOnRay(ray, char)

		if hit and hit:IsA("BasePart") and hit.CanCollide then
			-- Play wall hit animation
			local anim = Instance.new("Animation")
			anim.AnimationId = WALL_HIT_ANIM
			local animTrack = humanoid:LoadAnimation(anim)
			animTrack:Play()

			-- Play wall hit sound
			local wallSound = Instance.new("Sound")
			wallSound.SoundId = DASH_WALL_SOUND
			wallSound.Parent = root
			wallSound:Play()
			game.Debris:AddItem(wallSound, 2)

			-- Small stun delay after hitting wall
			task.wait(1.5)
		end
	end

	-- Continuously check for collision while dashing
	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		if not char or not root or not humanoid then
			connection:Disconnect()
			return
		end

		hitbox.Position = root.Position + (root.CFrame.LookVector * 3)
		checkCollision()
	end)

	-- Stop dash after time expires
	task.delay(dashDuration, function()
		connection:Disconnect()
		stopDash()
	end)
end

DashEvent.OnServerEvent:Connect(handleDash)
