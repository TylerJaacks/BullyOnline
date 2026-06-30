HISTORY_MS = 2000

gBytes = 0
gPlayers = {}

CreateThread(function()
	local history = {n = 0}
	GetSentBytes()
	Wait(0)
	while true do
		local sent = GetSentBytes()
		local timer = GetAccurateTimer()
		local value = history[1]
		while value and timer - value[1] >= HISTORY_MS do
			gBytes = gBytes - table.remove(history,1)[2]
			value = history[1]
		end
		table.insert(history,{timer,sent})
		gBytes = gBytes + sent
		Wait(0)
	end
end)
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterNetworkEventHandler("net_usage:Init",function(player)
	if DoesPlayerHaveRole(player,"admin") then
		SendNetworkEvent(player,"net_usage:Allow")
		gPlayers[player] = true
	end
end)
RegisterNetworkEventHandler("net_usage:Request",function(player)
	if gPlayers[player] then
		SendNetworkEvent(player,"net_usage:Print",gBytes)
	end
end)
