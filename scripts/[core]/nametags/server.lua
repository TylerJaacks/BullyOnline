SHOW_PLAYER_ID = GetConfigBoolean(GetScriptConfig(),"show_player_id",false)

gPlayers = {}
gHidden = {}

-- events
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterLocalEventHandler("sync:DeletePed",function(ped)
	gHidden[ped] = nil
end)
RegisterLocalEventHandler("sync:CreatePlayer",function(player,ped)
	-- a player ped was just created, so name the ped for everyone else besides the player
	local args = {GetPlayerId(player),ped,F_GetName(player),F_GetColor(player)}
	for peer in AllPlayers() do
		if peer ~= player then
			SendNetworkEvent(peer,"nametags:SetPlayer",unpack(args))
		end
	end
end)
RegisterLocalEventHandler("sync:SwapPlayer",function(player,ped)
	-- a player ped was changed to another ped, so tell everyone else to use this ped instead of the old one
	local args = {GetPlayerId(player),ped,F_GetName(player),F_GetColor(player)}
	for peer in AllPlayers() do
		if peer ~= player then
			SendNetworkEvent(peer,"nametags:SetPlayer",unpack(args))
		end
	end
end)
RegisterNetworkEventHandler("nametags:RequestPlayers",function(player)
	-- this player just started their script, so name all other players for them
	local peds = {}
	for ped in pairs(gHidden) do
		table.insert(peds,ped)
	end
	SendNetworkEvent(player,"nametags:HidePeds",peds)
	for peer in AllPlayers() do
		if peer ~= player then
			SendNetworkEvent(player,"nametags:SetPlayer",GetPlayerId(peer),GetSyncPlayerPed(peer),F_GetName(peer),F_GetColor(peer))
		end
	end
	SendNetworkEvent(player,"nametags:SetColor",F_GetColor(player))
end)
RegisterNetworkEventHandler("nametags:HidePlayer",function(player,hidden)
	local ped = GetSyncPlayerPed(player)
	for peer in AllPlayers() do
		if peer ~= player then
			if hidden then
				SendNetworkEvent(peer,"nametags:HidePed",ped,true)
			else
				SendNetworkEvent(peer,"nametags:HidePed",ped)
			end
		end
	end
	if hidden then
		gHidden[ped] = true
	else
		gHidden[ped] = nil
	end
end)

-- utility
function F_GetName(player)
	local name = GetPlayerName(player)
	if SHOW_PLAYER_ID then
		return "["..GetPlayerId(player).."] "..name
	end
	return name
end
function F_GetColor(player)
	if not gPlayers[player] then
		if dsl.role_colors then
			gPlayers[player] = dsl.role_colors.GetColorIndex(player)
		else
			gPlayers[player] = 0
		end
	end
	return gPlayers[player]
end
