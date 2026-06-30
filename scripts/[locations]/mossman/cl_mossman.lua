RegisterNetworkEventHandler("mossman:ThunderStrike",function(x,y,z)
	CreateThread(function()
		local fx = EffectCreate("ElectrocuteArc",x,y,z)
		EffectSetDirection(fx,0,0,1)
		EffectSetSphereDirection(fx,0,0,math.pi*0.5)
		EffectSlowKill(fx)
		if dsl.sounds then
			dsl.sounds.Play("Thunder01a","Rain.bnk")
			dsl.sounds.Play("Thunder01b","Rain.bnk")
			dsl.sounds.Play("Thunder01c","Rain.bnk")
		end
	end)
end)
RegisterNetworkEventHandler("mossman:BurrowUnderground",function(mossman,x,y,z)
	PauseSyncEntityPos(mossman)
	CreateThread(function()
		local sound = false
		local when = GetAccurateTimer()
		while IsSyncVehicleValid(mossman) do
			local vehicle = VehicleFromSyncVehicle(mossman)
			if dsl.fakecars and VehicleIsValid(vehicle) then
				local fake = dsl.fakecars.GetFakeVehicle(vehicle)
				if VehicleIsValid(fake) then
					vehicle = fake
				end
			end
			if VehicleIsValid(vehicle) then
				local matrix = VehicleGetMatrix(vehicle)
				local passed = (GetAccurateTimer() - when) / 2500
				if passed > 1 then
					passed = 1
				end
				if not sound and dsl.sounds then
					dsl.sounds.Play("ReaperHit","FunHouse.bnk")
					sound = true
				end
				VehicleSetPosSimple(vehicle,x,y,z-passed*2)
				VehicleSetMatrix(vehicle,matrix)
				VehicleSetEntityFlag(vehicle,0,false)
				VehicleSetStatus(vehicle,2)
			end
			Wait(0)
		end
	end)
end)
RegisterNetworkEventHandler("mossman:KillPlayer",function()
	CreateThread(function()
		local vehicle = VehicleFromDriver(gPlayer)
		if VehicleIsValid(vehicle) then
			if VehicleIsBike(vehicle) then
				PlayerDetachFromVehicle()
			else
				PedWarpOutOfCar(gPlayer)
			end
		end
		PedSetActionNode(gPlayer,"/GLOBAL/HITTREE/STANDING/POSTHIT/STANDING/DEAD/COLLAPSE/COLLAPSE_B","")
		PlayerSetHealth(0)
	end)
end)
