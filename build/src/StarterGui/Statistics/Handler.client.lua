local RunService = game:GetService("RunService")
local PingRemote = script.GetPing

local FPSCounter = script.Parent.Holder.FPS
local PingCounter = script.Parent.Holder.Ping

local Colors = {
	Good = Color3.fromRGB(0, 255, 0),
	Normal = Color3.fromRGB(255, 255, 0),
	Bad = Color3.fromRGB(255, 0, 0)
}

function GetPing()
	local Send = tick()
	local Ping = nil

	PingRemote:FireServer()

	local Receive; Receive = PingRemote.OnClientEvent:Connect(function()
		Ping = tick() - Send 
	end)

	wait(1)
	
	Receive:Disconnect()

	return Ping or 999
end

RunService.RenderStepped:Connect(function(TimeBetween)
	local FPS = math.floor(1 / TimeBetween)
	
	FPSCounter.Text = "FPS  : "..tostring(FPS)
	
	if FPS >= 50 then
		FPSCounter.TextColor3 = Colors.Good
		script.Parent.Holder.Problematic_FPS.Visible = false
	elseif FPS >= 30 then
		FPSCounter.TextColor3 = Colors.Normal
		script.Parent.Holder.Problematic_FPS.Visible = false
	elseif FPS >= 1 then
		FPSCounter.TextColor3 = Colors.Bad
		script.Parent.Holder.Problematic_FPS.Visible = true
	end
end)

local PingThread = coroutine.wrap(function()
	while wait() do
		local Ping = tonumber(string.format("%.3f", GetPing() * 1000))
		PingCounter.Text = "Ping : "..tostring(math.floor(Ping)).." ms"
		
		if Ping <= 100 then
			PingCounter.TextColor3 = Colors.Good
			script.Parent.Holder.Problematic_Ping.Visible = false
		elseif Ping <= 300 then
			PingCounter.TextColor3 = Colors.Normal
			script.Parent.Holder.Problematic_Ping.Visible = false
		elseif Ping > 300 then
			PingCounter.TextColor3 = Colors.Bad
			script.Parent.Holder.Problematic_Ping.Visible = true
		end
	end
end)

PingThread()