gPlayers = {}

RegisterNetworkEventHandler("radar:RequestPlayers",function(requester)
	local players = {}
	local id = GetPlayerId(requester)
	local name = GetPlayerName(requester)
	local color = F_GetRoleColor(requester)
	for player in pairs(gPlayers) do
		SendNetworkEvent(player,"radar:UpdatePlayer",id,name,color)
	end
	gPlayers[requester] = color
	for player,color in pairs(gPlayers) do
		players[GetPlayerId(player)] = {GetPlayerName(player),color}
	end
	SendNetworkEvent(requester,"radar:UpdatePlayers",players)
end)
RegisterLocalEventHandler("PlayerDropped",function(dropped)
	gPlayers[dropped] = nil
	for player in pairs(gPlayers) do
		SendNetworkEvent(player,"radar:UpdatePlayer",GetPlayerId(dropped))
	end
end)
function F_GetRoleColor(player)
	if dsl.role_colors then
		return dsl.role_colors.GetColorIndex(player)
	end
	return 0
end
