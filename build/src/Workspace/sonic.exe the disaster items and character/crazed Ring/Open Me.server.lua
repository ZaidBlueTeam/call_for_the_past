-- Sound Touch Brick Made By Textmasterthe9th
local head = script.Parent
local sound = head:findFirstChild("Sound")
---leave it alone
function onTouched(part)
	local h = part.Parent:findFirstChild("Humanoid")
	if h~=nil then
		script.parent.PointLight.Enabled = false
		sound:play()
		script.Disabled = true
		wait(23)
		script.parent.PointLight.Enabled = true
		sound:stop()
		script.Disabled = false

	end
end

script.Parent.Touched:connect(onTouched)

--to change the sound go into the object in the brick called "Sound"
--change the "SoundId" Inside Of The Object To The Sound That you Want To Play When You Touch The Brick.
--It Is That Simple.