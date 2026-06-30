function main()
	local pickup
	while true do
		local picking = false
		local vehicle = VehicleFromDriver(gPlayer)
		if VehicleIsValid(vehicle) then
			if VehicleIsBike(vehicle) and (PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES/BIKES/VEHICLES_RIDE/NOTONBIKE/RESETONFOOT",true) or PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES/SCOOTER/VEHICLES_RIDE/NOTONBIKE/RESETONFOOT",true)) then
				PedDetachFromVehicle(ped)
			elseif PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES/SKATEBOARD",true) then
				PedSetWeapon(gPlayer,-1)
				PedSetActionNode(gPlayer,"/GLOBAL/VEHICLES","")
			end
		elseif PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES/BIKES/MOVETOVEHICLE",true) or PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES/SCOOTER/MOVETOVEHICLE",true) or PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES/MOTORCYCLE/MOVETOVEHICLE",true) then
			local vehicle,distance = -1,16
			local x1,y1,z1 = PlayerGetPosXYZ()
			for veh in AllVehicles() do
				local x2,y2,z2 = VehicleGetPosXYZ(veh)
				local dx,dy,dz = x2-x1,y2-y1,z2-z1
				local dist = dx*dx+dy*dy+dz*dz
				if dist < distance then
					vehicle,distance = veh,dist
				end
			end
			if VehicleIsValid(vehicle) and VehicleGetStatus(vehicle) == 4 then
				VehicleSetStatus(vehicle,7)
			end
			picking = PedMePlaying(gPlayer,"PICKUPBIKE",true)
		end
		if picking then
			if not pickup then
				pickup = GetAccurateTimer()
			elseif GetAccurateTimer() - pickup >= 800 then
				PedSetActionNode(gPlayer,"/GLOBAL","")
				pickup = nil
			end
		elseif pickup then
			pickup = nil
		end
		Wait(0)
	end
end
