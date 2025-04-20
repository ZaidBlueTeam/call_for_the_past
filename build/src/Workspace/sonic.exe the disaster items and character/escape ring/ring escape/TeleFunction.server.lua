-- This script was specially made by crazyman32 for the use all ROBLOX players.

local Teleport_To_This_Tag = "0001" 	-- This is the Tag thing you find in the teleporter bricks. The brick with the tag that matches this is the brick you will tele to once you touch this one.

function findTele(tag) 
	local tele = nil 
	function scan(p) 
		for _,v in pairs(p:GetChildren()) do 
			if ((v.Name == "Telepad2") and (v:findFirstChild("Tag"))) then 
				if (v.Tag.Value == tag) then tele = v break end 
			end 
			if (#v:GetChildren() > 0) then scan(v) end 
		end 
	end 
	scan(game:service("Workspace")) 
	return tele 
end 

script.Parent.Touched:connect(function(h) 
	local p = game:service("Players"):GetPlayerFromCharacter(h.Parent) 
	if not (p) then return end 
	if (p:findFirstChild("JustTeleported")) then return end 
	if not (findTele(Teleport_To_This_Tag)) then return end 
	local tele = findTele(Teleport_To_This_Tag) 
	if (tele) then 
		if (p.Character) then 
			p.Character:MoveTo(tele.CFrame.p+Vector3.new(0,3.25,0)) 
			local t = Instance.new("Weld") 
			t.Name = "JustTeleported" 
			t.Parent = p 
			delay(1.5,function() t:remove() end) 
		end 
	end 
end) 
