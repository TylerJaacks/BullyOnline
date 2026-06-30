st = GetScriptSharedTable()

gPlayers = {}
gVehicles = {}

RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterLocalEventHandler("sync:DeleteVehicle",function(vehicle)
	gVehicles[vehicle] = nil
end)

RegisterNetworkEventHandler("admin_spawner:InitVehicles",function(player)
	SendNetworkEvent(player,"admin_spawner:SpawnedVehicle",gVehicles)
	gPlayers[player] = st.IsAllowed(player)
end)
RegisterNetworkEventHandler("admin_spawner:SpawnVehicle",function(player,name,model,x,y,z,h)
	if gPlayers[player] then
		local car
		if type(model) == "number" then
			car = CreateSyncVehicle(model)
		elseif dsl.propcars then
			car = dsl.propcars.CreateVehicle(model)
		end
		if car then
			SetSyncEntityPos(car,x,y,z,h)
			for player in pairs(gPlayers) do
				SendNetworkEvent(player,"admin_spawner:SpawnedVehicle",car,name)
			end
			SendNetworkEvent(player,"admin_spawner:RequestedVehicle",car)
			gVehicles[car] = name
		else
			SendNetworkEvent(player,"admin_spawner:RequestedVehicle")
		end
	end
end)
RegisterNetworkEventHandler("admin_spawner:WarpVehicle",function(player,scar,seat)
	if gPlayers[player] and gVehicles[scar] then
		SetSyncPedVehicle(GetSyncPlayerPed(player),scar,seat)
	end
end)
RegisterNetworkEventHandler("admin_spawner:LockVehicle",function(player,scar,key)
	if gPlayers[player] and gVehicles[scar] and dsl.vehicles then
		if dsl.inventory then
			dsl.inventory.GiveUniqueItemToPlayer(player,({"bronze","silver","gold"})[math.random(3)].."_car_key",nil,key)
		end
		dsl.vehicles.SetLock(scar,key)
	end
end)
RegisterNetworkEventHandler("admin_spawner:DeleteVehicle",function(player,scar)
	if gPlayers[player] and gVehicles[scar] then
		DeleteSyncEntity(scar)
	end
end)
