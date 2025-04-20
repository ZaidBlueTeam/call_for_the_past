local player = game.Players.LocalPlayer
repeat wait() until player.Character and player.Character:FindFirstChild("Humanoid")
local humanoid = player.Character:FindFirstChild("Humanoid")
local mouse = player:GetMouse()

local anim = Instance.new("Animation")
anim.AnimationId = "http://www.roblox.com/asset/?id=111233933866620" -- replace "ANIMATION" with your animation ID

mouse.KeyDown:Connect(function(key)
	if key == "q" then
		local playAnim = humanoid:LoadAnimation(anim)
		playAnim:Play()

		-- Stop the animation after 2 seconds (you can adjust the time)
		wait(1.8)
		playAnim:Stop()
	end
end)