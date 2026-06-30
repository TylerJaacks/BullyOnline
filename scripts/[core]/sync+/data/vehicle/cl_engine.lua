-- SYNC+ | vehicle engine | Xx_Yubari_xX
--  provides client side sync for vehicle engines

LoadScript("data/utility/shared/keys.lua")

-- apply:
RegisterLocalEventHandler("sync:PreUpdateVehicle",function(svehicle)
	local vehicle = VehicleFromSyncVehicle(svehicle)
	if VehicleIsValid(vehicle) and (WasSyncEntityUpdated(svehicle,KEY_ENGINE) or not IsSyncEntityOwned(svehicle)) and VehicleGetEngine(vehicle) ~= svehicle[KEY_ENGINE] then
		VehicleEnableEngine(vehicle,svehicle[KEY_ENGINE])
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdateVehicle",function(svehicle)
	local vehicle = VehicleFromSyncVehicle(svehicle)
	if VehicleIsValid(vehicle) then
		local engine = VehicleGetEngine(vehicle)
		if engine ~= svehicle[KEY_ENGINE] then
			svehicle[KEY_ENGINE] = engine
		end
	end
end)
