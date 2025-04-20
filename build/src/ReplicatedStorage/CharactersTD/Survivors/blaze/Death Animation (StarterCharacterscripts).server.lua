local char = script.Parent
local hum = char:WaitForChild("Humanoid")
local deathAnim = hum:LoadAnimation(script.DeathAnim)
hum.BreakJointsOnDeath = false
local dead = false

function deathCheck(health)
	if health <= 0 and dead == false then
		dead = true
		char.HumanoidRootPart.Anchored = true
		deathAnim:Play()
		wait(8)
		char.HumanoidRootPart.Anchored = false
		script:Destroy()
	end
end

hum.HealthChanged:Connect(deathCheck)