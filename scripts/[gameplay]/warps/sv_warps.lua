LoadScript("warps.lua")

gDimensions = {}
gPlayers = {}

RegisterNetworkEventHandler("warps:InitScript",function(player)
	local pd = F_GetPlayerData(player)
	if pd.dimension then
		SendNetworkEvent(player,"warps:SetDimension",pd.dimension)
	else
		SendNetworkEvent(player,"warps:SetDimension","main")
	end
	if DoesPlayerHaveRole(player,"admin") then
		SendNetworkEvent(player,"warps:AllowDebug")
	end
end)
RegisterNetworkEventHandler("warps:UpdateDimension",function(player,id)
	local pd = F_GetPlayerData(player)
	F_LeaveDimension(true,player,pd)
	if id then
		SendNetworkEvent(player,"warps:ContinueTransition")
		F_EnterDimension(player,pd,id)
	end
end)
RegisterLocalEventHandler("PlayerDropped",function(player)
	local pd = gPlayers[player]
	if pd then
		F_LeaveDimension(false,player,pd)
		gPlayers[player] = nil
	end
end)

function F_GetPlayerData(player)
	local pd = gPlayers[player]
	if not pd then
		pd = {} -- can have .dimension
		gPlayers[player] = pd
	end
	return pd
end
function F_GetWarpById(id)
	for _,warp in ipairs(gWarps) do
		if warp.id == id then
			return warp
		end
	end
end
function F_LeaveDimension(graceful,player,pd)
	local dd = gDimensions[pd.dimension]
	if dd then
		if graceful then
			local ped = GetSyncPlayerPed(player)
			if GetSyncEntityDimension(ped) == dd.di then
				SendNetworkEvent(player,"warps:SetDimension","main")
				SetSyncEntityDimension(ped,GetSyncMainDimension())
			end
		end
		dd.players[player] = nil
		if not next(dd.players) then
			TerminateThread(dd.thread)
			DeleteSyncDimension(dd.di)
			gDimensions[pd.dimension] = nil
		end
		pd.dimension = nil
	end
end
function F_EnterDimension(player,pd,id)
	local warp = F_GetWarpById(id)
	local ped = GetSyncPlayerPed(player)
	if warp and warp.destination_dimension ~= "main" and GetSyncEntityDimension(ped) == GetSyncMainDimension() then
		local dd = gDimensions[warp.destination_dimension]
		if not dd then
			dd = {
				players = {[player] = GetAccurateTimer()},
				di = F_SetupDimension(CreateSyncDimension(warp.destination_dimension),warp.objects),
			}
			dd.thread = CreateThread("T_Dimension",warp,warp.destination_dimension,dd)
			gDimensions[warp.destination_dimension] = dd
		else
			dd.players[player] = GetAccurateTimer()
		end
		SendNetworkEvent(player,"warps:SetDimension",warp.destination_dimension)
		SetSyncEntityDimension(ped,dd.di)
		SetSyncEntityPos(ped,unpack(warp.destination))
		pd.dimension = warp.destination_dimension
	end
end
function F_SetupDimension(di,objects)
	if objects and dsl.object_spawner then
		SetSyncActiveDimension(di)
		for _,set in ipairs(objects) do
			dsl.object_spawner.Activate(set)
		end
		SetSyncActiveDimension(GetSyncMainDimension())
	end
	return di
end
function T_Dimension(warp,name,dd)
	while gDimensions[name] == dd do
		local timer = GetAccurateTimer()
		for player,when in pairs(dd.players) do
			if timer - when >= 2000 then
				local ped = GetSyncPlayerPed(player)
				if GetSyncEntityDimension(ped) ~= dd.di or GetSyncEntityArea(ped) ~= warp.destination_area then
					F_LeaveDimension(true,player,gPlayers[player])
				end
			end
		end
		Wait(0)
	end
end
