-- put me in startercharacterscripts :>
-- made by ProffesorBloxy_YT
-- plagiarism will result in immediate action!

local UIS = game:GetService("UserInputService") -- Gets the UserInputService that detects the players inputs
local Sound = script:WaitForChild("Audio")

UIS.InputBegan:Connect(function(input)   
	if input.KeyCode == Enum.KeyCode.Q then   -- Change to any key
		Sound:Play()
	end
end)