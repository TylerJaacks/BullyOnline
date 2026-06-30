MAX_LENGTH = GetConfigNumber(GetScriptConfig(),"max_length",100)
MAX_DISTANCE = 30

gPlayers = {}

RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterNetworkEventHandler("proximity:InitScript",function(player)
	gPlayers[player] = true
end)
RegisterNetworkEventHandler("proximity:SendMessage",function(player,message)
	if gPlayers[player] and F_CheckMessage(message) then
		local ped = GetSyncPlayerPed(player)
		local di,area,x1,y1,z1 = GetSyncEntityDimension(ped),GetSyncEntityArea(ped),GetSyncEntityPos(ped)
		for player in pairs(gPlayers) do
			if F_IsNearby(GetSyncPlayerPed(player),di,area,x1,y1,z1) then
				SendNetworkEvent(player,"proximity:ShowMessage",ped,message,false)
			end
		end
	end
end)
RegisterNetworkEventHandler("proximity:TypeMessage",function(player,message)
	if gPlayers[player] then
		local ped = GetSyncPlayerPed(player)
		local di,area,x1,y1,z1 = GetSyncEntityDimension(ped),GetSyncEntityArea(ped),GetSyncEntityPos(ped)
		if not message then
			for player in pairs(gPlayers) do
				if F_IsNearby(GetSyncPlayerPed(player),di,area,x1,y1,z1) then
					SendNetworkEvent(player,"proximity:ShowMessage",ped)
				end
			end
		elseif F_CheckMessage(message) then
			for player in pairs(gPlayers) do
				if F_IsNearby(GetSyncPlayerPed(player),di,area,x1,y1,z1) then
					SendNetworkEvent(player,"proximity:ShowMessage",ped,message,true)
				end
			end
		end
	end
end)

function F_IsNearby(ped,di,area,x1,y1,z1)
	if GetSyncEntityDimension(ped) == di and GetSyncEntityArea(ped) == area then
		local x2,y2,z2 = GetSyncEntityPos(ped)
		local dx,dy,dz = x2-x1,y2-y1,z2-z1
		return dx*dx+dy*dy+dz*dz < MAX_DISTANCE*MAX_DISTANCE
	end
	return false
end
function F_CheckMessage(message)
	if type(message) == "string" and string.find(message,"%S") then
		local length = utf8.len(message)
		if length and length <= MAX_LENGTH then
			return true
		end
	end
	return false
end
