local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Local player and character
local localPlayer = players.LocalPlayer
local currentCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()

-- RemoteEvent for dealing damage
local dealDamageEvent = replicatedStorage:WaitForChild("DealDamageEvent")

-- Animation setup
local attackAnimation = Instance.new("Animation")
attackAnimation.AnimationId = "rbxassetid://84829499445604" -- Replace with your attack animation ID

-- Cooldown settings
local ATTACK_COOLDOWN = 1.5 -- Cooldown in seconds
local lastAttackTime = 0 -- Tracks the last time the player attacked

-- Function to perform attack
local function performAttack()
	local currentTime = os.clock()

	-- Check if cooldown has elapsed
	if currentTime - lastAttackTime < ATTACK_COOLDOWN then
		print("Attack on cooldown. Wait before attacking again!")
		return
	end

	-- Update the last attack time
	lastAttackTime = currentTime

	-- Play the attack animation
	if currentCharacter then
		local humanoid = currentCharacter:FindFirstChild("Humanoid")
		if humanoid then
			local animationTrack = humanoid:LoadAnimation(attackAnimation)
			animationTrack:Play()
		else
			warn("Humanoid not found in character!")
		end
	else
		warn("Current character not found!")
	end

	-- Notify the server to handle damage
	dealDamageEvent:FireServer()
end

-- Detect key press
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.F then
		performAttack()
	end
end)
