local runService = game:GetService("RunService")

local char = script.Parent
local Human = char:WaitForChild("Humanoid")

function updateShakeEffect()
	local currentTime = tick()
	if Human.WalkSpeed > 15 and Human.MoveDirection.Magnitude > 0 then
		local shakeX = math.cos(currentTime * 10) * .5
		local shakeY = math.abs(math.sin(currentTime * 10)) * .5
		
		local shake = Vector3.new(shakeX, shakeY, 0)
		
		Human.CameraOffset = Human.CameraOffset:lerp(shake, .25)
	else -- Not walking
		Human.CameraOffset = Human.CameraOffset * .75
	end
end

runService.RenderStepped:Connect(updateShakeEffect)