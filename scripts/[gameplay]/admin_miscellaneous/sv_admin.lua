gPlayers = {}
gScale = {}

-- player permissions
RegisterNetworkEventHandler("admin_miscellaneous:Request",function(player)
	if DoesPlayerHaveRole(player,"superadmin") or GetPlayerIp(player) == "127.0.0.1" then
		SendNetworkEvent(player,"admin_miscellaneous:Allow")
		SendNetworkEvent(player,"admin_miscellaneous:Super")
		gPlayers[player] = "super"
	elseif DoesPlayerHaveRole(player,"admin") then
		SendNetworkEvent(player,"admin_miscellaneous:Allow")
		gPlayers[player] = "admin"
	else
		gPlayers[player] = false
	end
	SendNetworkEvent(player,"admin_miscellaneous:Scale",gScale)
end)
RegisterLocalEventHandler("sync:DeletePed",function(ped)
	gScale[ped] = nil
end)
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)

-- network events
RegisterNetworkEventHandler("admin_miscellaneous:Heal",function(player)
	if gPlayers[player] then
		local ped = GetSyncPlayerPed(player)
		PedSetHealth(ped,PedGetMaxHealth(ped))
	end
end)
RegisterNetworkEventHandler("admin_miscellaneous:Scale",function(player,scale)
	if gPlayers[player] and type(scale) == "number" and scale > -1 / 0 and scale < 1 / 0 then
		gScale[GetSyncPlayerPed(player)] = scale
		for player in pairs(gPlayers) do
			SendNetworkEvent(player,"admin_miscellaneous:Scale",gScale)
		end
	end
end)
RegisterNetworkEventHandler("admin_miscellaneous:Auditorium",function(player)
	if gPlayers[player] == "super" then
		local ped = GetSyncPlayerPed(player)
		SetSyncEntityPos(ped,-769.73,308.41,77.25,180)
		for other in AllSyncPlayers(GetSyncEntityDimension(ped)) do
			if other ~= player then
				local x,y,z = -769.67,298.99,77.73
				local d = math.random(0,300)/100
				local h = math.rad(math.random(0,359))
				SetSyncEntityPos(GetSyncPlayerPed(other),x-math.sin(h)*d,y+math.cos(h)*d,z,0)
			end
		end
	end
end)
RegisterNetworkEventHandler("admin_miscellaneous:Clock",function(player,minutes)
	if gPlayers[player] and type(minutes) == "number" and minutes >= 0 and minutes < 1440 then
		ClockSet(math.floor(minutes/60),math.mod(minutes,60))
	end
end)
