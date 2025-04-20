script.Parent.CFrame = CFrame.new(script.Parent.Position.x, script.Parent.Position.y, script.Parent.Position.z)

while true do                                                                                  
wait()
script.Parent.CFrame = script.Parent.CFrame * CFrame.Angles(math.rad(0), math.rad(10.0), math.rad(0))
end 