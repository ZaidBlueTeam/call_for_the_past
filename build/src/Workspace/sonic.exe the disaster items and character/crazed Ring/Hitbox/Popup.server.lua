Popup = script.Parent.ScreenGui ----- Your ScreenGUI's name
Ready = true
function onTouch(hit)
	local h = hit.Parent:FindFirstChild("Humanoid")
	if h ~= nil and Ready == true then
		Ready = false
		local plyr = game.Players:FindFirstChild(h.Parent.Name) 
		local c = Popup:clone()
		c.Parent = plyr.PlayerGui
		wait(10) ------ How long you have to wait for the GUI to disappear 
		c:remove() -------- Delete this line if you want the GUI to stay and not disappear
		wait(1)
		Ready = true
		wait(0.1)
		script.Parent:destroy()

	end
end


script.Parent.Touched:connect(onTouch)

