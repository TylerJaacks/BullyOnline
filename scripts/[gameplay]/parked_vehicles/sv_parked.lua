LoadScript("spawns.lua")

DEBUG_VEHICLE_POSITIONS = false
MINIMUM_ENTITY_SPACE = 200
PED_SPAWN_PROTECTION = 3

gVehicles = {}
gPlayers = {}
gSpawned = 0

-- players
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterNetworkEventHandler("parked_vehicles:StartScript",function(player)
	if DEBUG_VEHICLE_POSITIONS then
		for _,data in ipairs(gVehicles) do
			if IsSyncVehicleValid(data.vehicle) then
				SendNetworkEvent(player,"parked_vehicles:ShowPosition",vehicle)
			end
		end
	end
	gPlayers[player] = true
end)

-- spawner
function main()
	for i in ipairs(gVehicleSpawns) do
		gVehicles[i] = {
			inside = false, -- anyone is inside
			-- .vehicle is set when one is spawned
		}
	end
	while true do
		for i,spot in ipairs(gVehicleSpawns) do
			local data = gVehicles[i]
			local sx,sy,sz,sh = unpack(spot.spawn)
			if data.vehicle then
				if not IsSyncVehicleValid(data.vehicle) or not F_UpdateSpawnedVehicle(data) then
					gSpawned = gSpawned - 1
					data.inside = false
					data.vehicle = nil
					data.when = nil
				end
			elseif F_IsPlayerWithin(sx,sy,sz,spot.maximum) then
				if not data.inside then
					if not F_IsPlayerWithin(sx,sy,sz,spot.minimum) and F_CanSpawnVehicle(spot) and math.random(100) <= spot.chance then
						local vehicle
						local model = F_GetRandomModel(spot.models)
						if type(model) == "number" then
							vehicle = CreateSyncVehicle(model)
						elseif dsl.propcars then
							vehicle = dsl.propcars.CreateVehicle(model)
						end
						if vehicle then
							if DEBUG_VEHICLE_POSITIONS then
								for player in pairs(gPlayers) do
									SendNetworkEvent(player,"parked_vehicles:ShowPosition",vehicle)
								end
							end
							SetSyncEntityPos(vehicle,sx,sy,sz,sh)
							gSpawned = gSpawned + 1
							data.when = GetAccurateTimer()
							data.vehicle = vehicle
						end
					end
					data.inside = true
				end
			elseif data.inside then
				data.inside = false
			end
		end
		Wait(100)
	end
end
function F_UpdateSpawnedVehicle(data)
	local vx,vy,vz = GetSyncEntityPos(data.vehicle)
	if F_IsAnyoneInside(data.vehicle) then
		data.when = GetAccurateTimer()
	elseif not F_IsPlayerWithin(vx,vy,vz,DESPAWN_DISTANCE) and GetAccurateTimer() - data.when >= DESPAWN_TIMER then
		DeleteSyncEntity(data.vehicle)
		return false
	end
	return true
end
function F_IsAnyoneInside(vehicle)
	for seat = 0,3 do
		if GetSyncVehiclePassenger(vehicle,seat) then
			return true
		end
	end
	return false
end
function F_IsPlayerWithin(sx,sy,sz,range)
	for player in AllSyncPlayers(GetSyncMainDimension()) do
		local px,py,pz = GetSyncEntityPos(GetSyncPlayerPed(player))
		if F_InRange(sx,sy,sz,px,py,pz,range) then
			return true
		end
	end
	return false
end
function F_IsAnythingWithin(sx,sy,sz,range)
	for ped in AllSyncPeds(GetSyncMainDimension()) do
		local px,py,pz = GetSyncEntityPos(ped)
		if F_InRange(sx,sy,sz,px,py,pz,range) then
			return true
		end
	end
	for vehicle in AllSyncVehicles(GetSyncMainDimension()) do
		local vx,vy,vz = GetSyncEntityPos(vehicle)
		if F_InRange(sx,sy,sz,vx,vy,vz,range) then
			return true
		end
	end
	return false
end
function F_CanSpawnVehicle(spot)
	local count = 0
	local sx,sy,sz = unpack(spot.spawn)
	for vehicle in AllSyncVehicles(GetSyncMainDimension()) do
		local vx,vy,vz = GetSyncEntityPos(vehicle)
		if F_InRange(sx,sy,sz,vx,vy,vz,MAX_NEARBY_DISTANCE) then
			count = count + 1
		end
	end
	return not F_IsAnythingWithin(sx,sy,sz,PED_SPAWN_PROTECTION) and gSpawned < MAX_TOTAL_SPAWNED and count < MAX_NEARBY_SPAWNED and GetSyncEntitySpace() >= MINIMUM_ENTITY_SPACE
end
function F_GetRandomModel(models)
	local weight = 0
	for _,w in ipairs(models) do
		weight = weight + w[1]
	end
	weight = math.random(weight)
	for _,w in ipairs(models) do
		if weight <= w[1] then
			return w[2]
		end
		weight = weight - w[1]
	end
end

-- utility
function F_InRange(x1,y1,z1,x2,y2,z2,range)
	local dx,dy,dz = x2-x1,y2-y1,z2-z1
	return dx*dx+dy*dy+dz*dz < range*range
end
