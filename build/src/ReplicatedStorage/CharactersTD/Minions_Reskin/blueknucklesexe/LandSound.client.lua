wait(1)
local Grass = script.Grass
Grass.Parent = script.Parent.HumanoidRootPart
local Wood = script.Wood
Wood.Parent = script.Parent.HumanoidRootPart
local Concrete = script.Concrete
Concrete.Parent = script.Parent.HumanoidRootPart
--local Etc = (script.Slate, script.SmoothPlastic, script.Concrete, script.Sand, script.Brick, script.Concrete, script.Fabric)
local Slate = script.Slate
local SmoothPlastic = script.SmoothPlastic
local Sand = script.Sand
local Cobblestone = script.CobbleStone
local Brick = script.Brick
local Fabric = script.Fabric
local Plastic = script.Plastic
Fabric	= script.Parent.HumanoidRootPart
SmoothPlastic.Parent = script.Parent.HumanoidRootPart
Sand.Parent = script.Parent.HumanoidRootPart
Brick.Parent = script.Parent.HumanoidRootPart
Cobblestone.Parent = script.Parent.HumanoidRootPart
Slate.Parent = script.Parent.HumanoidRootPart
Plastic.Parent = script.Parent.HumanoidRootPart

script.Parent.Humanoid.StateChanged:Connect(function(_,state)
	if state == Enum.HumanoidStateType.Landed then
		script.Parent.HumanoidRootPart:WaitForChild(script.Parent.Humanoid.FloorMaterial):Play()
		end
	end)


