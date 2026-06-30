gPlayers = {}

RegisterNetworkEventHandler("admin_spawner:Request",function(player)
	if DoesPlayerHaveRole(player,"admin") then
		SendNetworkEvent(player,"admin_spawner:Allow")
		gPlayers[player] = true
	end
end)
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
GetScriptSharedTable().IsAllowed = function(player)
	return gPlayers[player]
end
