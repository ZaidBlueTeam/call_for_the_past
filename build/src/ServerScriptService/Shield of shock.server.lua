local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShockShieldEvent = ReplicatedStorage:WaitForChild("ShockShieldEvent")

local stunDuration = 3
local invincibilityTime = 2
local shieldDuration = 10  

local function playStunAnimations(humanoid)
	-- Play hit reaction animation first
	local hitReactionAnim = Instance.new("Animation")
	hitReactionAnim.AnimationId = "rbxassetid://134319170245964" -- Replace with actual hit animation ID
	local hitAnimTrack = humanoid:LoadAnimation(hitReactionAnim)
	hitAnimTrack:Play()

	-- Wait for the hit reaction animation to finish
	task.wait(hitAnimTrack.Length)

	-- Play stun animation (looped)
	local stunAnim = Instance.new("Animation")
	stunAnim.AnimationId = "rbxassetid://112178683548703" -- Replace with actual stun animation ID
	local stunAnimTrack = humanoid:LoadAnimation(stunAnim)
	stunAnimTrack.Looped = true
	stunAnimTrack:Play()

	return stunAnimTrack
end

ShockShieldEvent.OnServerEvent:Connect(function(player)
	local char = player.Character
	if not char then return end  

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end  

	-- Create Shock Shield on server
	local shockShield = Instance.new("Part")
	shockShield.Size = Vector3.new(10, 10, 10)
	shockShield.Shape = Enum.PartType.Ball
	shockShield.Material = Enum.Material.ForceField
	shockShield.Transparency = 0.3
	shockShield.Color = Color3.fromRGB(0, 255, 255)
	shockShield.Anchored = false
	shockShield.CanCollide = false
	shockShield.Parent = workspace
	shockShield.Position = root.Position

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = shockShield
	weld.Part1 = root
	weld.Parent = shockShield

	-- Attach particle effect
	local particle = Instance.new("ParticleEmitter")
	particle.Texture = "rbxassetid://YOUR_PARTICLE_EFFECT_ID"
	particle.Rate = 15
	particle.Lifetime = NumberRange.new(1)
	particle.Parent = shockShield

	-- Attach looping sound
	local shockSound = Instance.new("Sound")
	shockSound.SoundId = "rbxassetid://705787045"
	shockSound.Volume = 2
	shockSound.Looped = true
	shockSound.Parent = root
	shockSound:Play()

	-- Function to stun EXE
	local function stunEXE(hit)
		local hitPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
		if hitPlayer and hitPlayer.Team and hitPlayer.Team.Name == "EXE" then
			local hitChar = hitPlayer.Character
			local humanoid = hitChar and hitChar:FindFirstChild("Humanoid")
			local rootPart = hitChar and hitChar:FindFirstChild("HumanoidRootPart")

			if humanoid and rootPart and not hitChar:GetAttribute("Stunned") and not hitChar:GetAttribute("Invincible") then
				-- Apply stun
				hitChar:SetAttribute("Stunned", true)
				hitChar:SetAttribute("Invincible", true)

				-- Freeze the player by anchoring
				rootPart.Anchored = true

				-- Play stun animations
				local stunAnimTrack = playStunAnimations(humanoid)

				-- Destroy shield & sound immediately
				shockSound:Destroy()
				particle:Destroy()
				shockShield:Destroy()

				-- Wait for stun duration
				task.wait(stunDuration)

				-- Stop stun animation
				if stunAnimTrack then
					stunAnimTrack:Stop()
				end

				-- Unfreeze the player
				rootPart.Anchored = false

				-- Remove stun & apply temporary invincibility
				hitChar:SetAttribute("Stunned", false)
				task.wait(invincibilityTime)
				hitChar:SetAttribute("Invincible", false)
			end
		end
	end

	-- Detect when EXE touches the shield
	shockShield.Touched:Connect(stunEXE)

	-- Auto-remove shield after duration
	task.delay(shieldDuration, function()
		if shockShield and shockShield.Parent then
			shockShield:Destroy()
		end
		if shockSound and shockSound.Parent then
			shockSound:Destroy()
		end
	end)
end)
