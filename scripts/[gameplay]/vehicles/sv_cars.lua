LoadScript("vehicles.lua")

SOUND_RANGE = 7
INTERACT_RANGE = 8

gVehicles = {}

function exports.SetLock(vehicle,key)
	if not IsSyncVehicleValid(vehicle) then
		argerror(1,"invalid vehicle")
	elseif type(key) ~= "string" then
		typerror(2,"string")
	elseif gVehicles[vehicle] then
		gVehicles[vehicle].key = key
		return true
	elseif not F_IsLockable(vehicle) then
		return false
	end
	gVehicles[vehicle] = {
		seats = F_InitSeats(F_GetMaxSeats(vehicle)),
		players = {},
		key = key,
	}
	return true
end

CreateThread(function()
	while true do
		local now = GetAccurateTimer()
		for vehicle,locked in pairs(gVehicles) do
			for seat = 0,3 do
				local ped = GetSyncVehiclePassenger(vehicle,seat)
				if ped then
					local player = GetSyncPlayerFromPed(ped)
					if player then
						local data = locked.players[player]
						if not data or data.seat ~= seat then
							SetSyncPedVehicle(ped,nil)
						end
					end
				end
			end
			for player,data in pairs(locked.players) do
				if GetSyncPedVehicle(GetSyncPlayerPed(player)) == vehicle then
					if not data.inside then
						data.inside = true
					end
				elseif data.inside or now - data.when >= 2000 then
					locked.players[player] = nil
				end
			end
		end
		Wait(0)
	end
end)
RegisterLocalEventHandler("PlayerDropped",function(player)
	for _,locked in pairs(gVehicles) do
		locked.players[player] = nil
	end
end)
RegisterLocalEventHandler("sync:DeleteVehicle",function(vehicle)
	gVehicles[vehicle] = nil
end)
RegisterNetworkEventHandler("vehicles:EnterVehicle",function(player,vehicle,seat,slot)
	if IsSyncVehicleValid(vehicle) and F_CanInteract(GetSyncPlayerPed(player),vehicle) then
		local locked = gVehicles[vehicle]
		if slot == nil then
			if not locked or locked.seats[seat] == false then
				if locked then
					locked.players[player] = {inside = false,seat = seat,when = GetAccurateTimer()}
				end
				SendNetworkEvent(player,"vehicles:AllowVehicle",vehicle,seat) -- get in car
			else
				SendNetworkEvent(player,"vehicles:DenyVehicle",true) -- locked (play sound)
			end
			return
		elseif dsl.inventory then
			local id,_,key = dsl.inventory.GetPlayerItemData(player,slot)
			if gKeyItems[id] then
				if not locked or locked.key ~= key or locked.seats[seat] == nil then
					SendNetworkEvent(player,"vehicles:LockVehicle") -- wrong key
				elseif locked.seats[seat] then
					SendNetworkEvent(player,"vehicles:LockVehicle",true) -- unlocked car
					F_SyncSoundEffect(player,"vehicles:LockSound",vehicle,true)
					locked.seats[seat] = false
				else
					SendNetworkEvent(player,"vehicles:LockVehicle",false) -- locked car
					F_SyncSoundEffect(player,"vehicles:LockSound",vehicle)
					locked.seats[seat] = true
				end
				return
			end
		end
	end
	SendNetworkEvent(player,"vehicles:DenyVehicle") -- nothing happened
end)
RegisterNetworkEventHandler("vehicles:ExitVehicle",function(player,vehicle)
	local locked = gVehicles[vehicle]
	if locked then
		local data = locked.players[player]
		if data and data.inside and locked.seats[data.seat] and GetSyncVehiclePassenger(vehicle,data.seat) == GetSyncPlayerPed(player) then
			F_SyncSoundEffect(nil,"vehicles:LockSound",vehicle,true) -- unlock when exiting
			locked.seats[data.seat] = false
		end
	end
end)
RegisterNetworkEventHandler("vehicles:LockVehicle",function(player,vehicle)
	local locked = gVehicles[vehicle]
	if locked and locked.players[player] and GetSyncVehiclePassenger(vehicle,0) == GetSyncPlayerPed(player) then
		local locking = false
		for _,lock in pairs(locked.seats) do
			if not lock then
				locking = true -- if any are unlocked, lock all
				break
			end
		end
		for seat in pairs(locked.seats) do
			locked.seats[seat] = locking
		end
		locking = not locking
		SendNetworkEvent(player,"vehicles:LockVehicle",locking)
		F_SyncSoundEffect(player,"vehicles:LockSound",vehicle,locking)
	else
		SendNetworkEvent(player,"vehicles:DenyVehicle")
	end
end)
RegisterNetworkEventHandler("vehicles:HonkVehicle",function(player,vehicle)
	if IsSyncVehicleValid(vehicle) and GetSyncVehiclePassenger(vehicle,0) == GetSyncPlayerPed(player) then
		F_SyncSoundEffect(player,"vehicles:HornSound",vehicle)
	end
end)
RegisterNetworkEventHandler("vehicles:SwitchEngine",function(player,vehicle,on)
	if IsSyncVehicleValid(vehicle) and GetSyncVehiclePassenger(vehicle,0) == GetSyncPlayerPed(player) then
		F_SyncSoundEffect(player,"vehicles:EngineSound",vehicle,on)
	end
end)

function F_InitSeats(limit)
	local seats = {}
	for i = 1,limit do
		seats[i-1] = true
	end
	return seats
end
function F_CanInteract(ped,vehicle)
	if not GetSyncPedVehicle(ped) then
		local x1,y1,z1 = GetSyncEntityPos(ped)
		local x2,y2,z2 = GetSyncEntityPos(vehicle)
		local dx,dy,dz = x2-x1,y2-y1,z2-z1
		return dx*dx+dy*dy+dz*dz < INTERACT_RANGE*INTERACT_RANGE
	end
	return false
end
function F_SyncSoundEffect(player,event,vehicle,...)
	local x1,y1,z1 = GetSyncEntityPos(vehicle)
	for other in AllSyncPlayers(GetSyncEntityDimension(vehicle)) do
		if other ~= player then
			local x2,y2,z2 = GetSyncEntityPos(GetSyncPlayerPed(other))
			local dx,dy,dz = x2-x1,y2-y1,z2-z1
			if dx*dx+dy*dy+dz*dz < SOUND_RANGE*SOUND_RANGE then
				SendNetworkEvent(other,event,vehicle,unpack(arg))
			end
		end
	end
end
