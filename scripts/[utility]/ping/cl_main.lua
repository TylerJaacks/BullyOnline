local gTimer

SetCommand("ping",function()
	gTimer = GetAccurateTimer()
	SendNetworkEvent("ping:ping")
end,false,"Usage: ping\nPings the server and record the time it took to get a response.")
RegisterNetworkEventHandler("ping:pong",function()
	if gTimer then
		PrintOutput(string.format("%s ms",tostring(GetAccurateTimer()-gTimer)))
		gTimer = nil
	else
		PrintWarning("unexpected server pong")
	end
end)
