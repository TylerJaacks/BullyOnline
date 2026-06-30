SPAWN = {185.30,413.86,0.98,161.8}
CHANCE = 100

CreateThread(function()
	local mosstime = false
	while true do
		local hour,minute = ClockGet()
		minute = hour * 60 + minute
		if ChapterGet() ~= 2 and WeatherGet() == 5 and minute >= 180 and minute < 210 then
			if not mosstime then
				local players = F_GetNearbyPlayers()
				if players and dsl.propcars and math.random(100) <= CHANCE then
					local mossman = dsl.propcars.CreateVehicle("mossman")
					if mossman then
						for _,player in ipairs(players) do
							SendNetworkEvent(player,"mossman:ThunderStrike",unpack(SPAWN))
						end
						SetSyncEntityPos(mossman,unpack(SPAWN))
						LockSyncEntityOwner(mossman,nil)
						F_MossmanWait(mossman,3000)
						--UnlockSyncEntityOwner(mossman)
						if IsSyncVehicleValid(mossman) then
							SendNetworkEvent(-1,"mossman:BurrowUnderground",mossman,unpack(SPAWN))
							F_MossmanWait(mossman,4000)
							DeleteSyncEntity(mossman)
						end
					end
				end
				mosstime = true
			end
		elseif mosstime then
			mosstime = false
		end
		Wait(1000)
	end
end)
function F_GetNearbyPlayers()
	local results = {}
	local sx,sy,sz = unpack(SPAWN)
	for player in AllSyncPlayers(GetSyncActiveDimension()) do
		local px,py,pz = GetSyncEntityPos(GetSyncPlayerPed(player))
		local dx,dy,dz = px-sx,py-sy,pz-sz
		if dx*dx+dy*dy+dz*dz < 400 then
			table.insert(results,player)
		end
	end
	return results
end
function F_MossmanWait(mossman,ms)
	local killed = {}
	local started = GetAccurateTimer()
	while GetAccurateTimer() - started < ms do
		local mx,my,mz = GetSyncEntityPos(mossman)
		for player in AllSyncPlayers(GetSyncActiveDimension()) do
			local px,py,pz = GetSyncEntityPos(GetSyncPlayerPed(player))	
			local dx,dy,dz = px-mx,py-my,pz-mz
			if not killed[player] and dx*dx+dy*dy+dz*dz < 16 then
				SendNetworkEvent(player,"mossman:KillPlayer")
				killed[player] = true
			end
		end
		for seat = 0,3 do
			local ped = GetSyncVehiclePassenger(mossman,seat)
			if ped then
				local player = GetSyncPlayerFromPed(ped)
				if player and not killed[player] then
					SendNetworkEvent(player,"mossman:KillPlayer")
					killed[player] = true
				end
				SetSyncPedVehicle(ped,nil)
			end
		end
		Wait(0)
	end
end
