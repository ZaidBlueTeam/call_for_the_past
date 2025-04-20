--BigThunderBoy
--This script will anchor everything inside the model you put it into
--It scans through every part of the model and anchors it :)

function check(model) --Function to anchor whatever is inside the model
	for i, part in pairs(model:GetChildren()) do
		if part.ClassName == "Model" then
			check(part) --if the part is a model, then call this function on that part/model
		elseif part.ClassName == "Part" then
			part.Anchored = true --else anchor the object if it is a part
		end
	end
end

check(script.Parent) --Start script to make it start running
--BigThunderBoy