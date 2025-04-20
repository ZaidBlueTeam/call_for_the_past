--Animated Texture Script by TakeoHonorable

local Main = script.Parent

local DistributedScripts = {}
local RunService = (game:FindService("RunService") or game:GetService("RunService"))

local function Wait(para) -- bypasses the latency
	para = para or wait()
	local Initial = tick()
	repeat
		RunService.Stepped:Wait()
	until tick()-Initial >= para
end

Main.Touched:Connect(function(hit)
	if not hit.Parent then return end
	local Humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
	if Humanoid then
		local Torso = (hit.Parent:FindFirstChild("Torso") or hit.Parent:FindFirstChild("HumanoidRootPart"))
		local Forcefield = Humanoid.Parent:FindFirstChildOfClass("ForceField")
		if Forcefield then return end
		if Torso then
			local Found = false
			for i=1,#DistributedScripts do
				if DistributedScripts[i].Parent == Torso then
					Found = true
				end
			end
			if not Found then
				local BurnScript = script:FindFirstChildOfClass("Script"):Clone()
				DistributedScripts[#DistributedScripts+1] = BurnScript
				BurnScript.Parent = Torso
				BurnScript.Disabled = false
			end
		end
	end
end)

while Main do
		local PartsInside = Main:GetTouchingParts()
		for i=1,#PartsInside do
			local Humanoid = PartsInside[i].Parent:FindFirstChildOfClass("Humanoid")
			if Humanoid then
				local Torso = (PartsInside[i].Parent:FindFirstChild("Torso") or PartsInside[i].Parent:FindFirstChild("HumanoidRootPart"))
				local Forcefield = PartsInside[i].Parent:FindFirstChildOfClass("ForceField")
				if not Forcefield then
				if Torso then
					local Found = false
					for i=1,#DistributedScripts do
						if DistributedScripts[i].Parent == Torso then
							Found = true
						end
					end
					if not Found then
						local BurnScript = script:FindFirstChildOfClass("Script"):Clone()
						DistributedScripts[#DistributedScripts+1] = BurnScript
						BurnScript.Parent = Torso
						BurnScript.Disabled = false
					 script.Parent:destroy()
					end
				end
			end
			end
		end
	Wait(.5)
end
