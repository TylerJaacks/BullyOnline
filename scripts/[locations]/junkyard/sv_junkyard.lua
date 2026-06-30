CreateThread(function()
	local nearby = false
	local vehicle
	local despawn
	while true do
		if F_IsAnyoneNearby(43) then
			if not nearby then
				if not vehicle and dsl.propcars and GetSyncEntitySpace() >= 100 then
					vehicle = dsl.propcars.CreateVehicle("pieceofshitcar_basic")
					if vehicle then
						SetSyncEntityPos(vehicle,-740.29,-616.43,3.65,-145.7)
					end
				end
				nearby = true
			end
		elseif nearby then
			if vehicle then
				despawn = GetAccurateTimer()
			end
			nearby = false
		elseif despawn and GetAccurateTimer() - despawn >= 60000 then
			if IsSyncVehicleValid(vehicle) then
				DeleteSyncEntity(vehicle)
			end
			vehicle = nil
			despawn = nil
		end
		Wait(0)
	end
end)
function F_IsAnyoneNearby(area)
	for player in AllSyncPlayers(GetSyncMainDimension()) do
		if GetSyncEntityArea(GetSyncPlayerPed(player)) == area then
			return true
		end
	end
	return false
end
