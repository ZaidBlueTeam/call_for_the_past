local Torso = script.Parent
local Humanoid = Torso.Parent:FindFirstChildOfClass("Humanoid")
local Timer = 10
local Debris = game:GetService("Debris")

if Humanoid then
	local Fire = script:FindFirstChildOfClass("ParticleEmitter")
	if Fire then
		Fire.Parent = Torso
		Fire.Enabled = true
		Debris:AddItem(Fire,Timer)
		Debris:AddItem(script,Timer)
	end
end

while Humanoid do
	Humanoid:TakeDamage(1)
	wait(1)
end