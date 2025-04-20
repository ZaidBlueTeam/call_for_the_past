function MakeBlood()

local blood = Instance.new("Part")
blood.formFactor = "Plate"
blood.Size = Vector3.new(1,0.4,1)
blood.Name = "Blood"
blood.BrickColor = BrickColor.new("Really red")
blood.Locked = true
blood.BackSurface = "Smooth"
blood.TopSurface = "Smooth"
blood.CanCollide = true

local CC = math.random(1,2)

if CC == 1 then

blood.Transparency = 0.5

elseif CC == 2 then

blood.Transparency = 0.3

end

blood.Position = script.Parent.Torso.Position
blood.Parent = script.Parent

end

humanoid = script.Parent.Humanoid
lhh = humanoid.Health

while true do

if humanoid.Health < lhh then

howmuch = math.random(4,7)
lhh = humanoid.Health

for i = 1 , howmuch do

MakeBlood()

end

end

wait(0.1)
end
