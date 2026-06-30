-- SYNC+ | vehicle sirens | Xx_Yubari_xX
--  provides client side sync for vehicle sirens

LoadScript("data/utility/shared/keys.lua")

-- apply:
RegisterLocalEventHandler("sync:PreUpdateVehicle",function(svehicle)
	local vehicle = VehicleFromSyncVehicle(svehicle)
	if VehicleIsValid(vehicle) then
		local model = VehicleGetModelId(vehicle)
		if model == 275 or model == 295 then
			if (WasSyncEntityUpdated(svehicle,KEY_SIREN) or not IsSyncEntityOwned(svehicle)) and VehicleGetSiren(vehicle) ~= svehicle[KEY_SIREN] then
				VehicleEnableSiren(vehicle,svehicle[KEY_SIREN])
			end
			VehicleSirenAllwaysOn(vehicle,true)
		end
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdateVehicle",function(svehicle)
	local vehicle = VehicleFromSyncVehicle(svehicle)
	if VehicleIsValid(vehicle) then
		local model = VehicleGetModelId(vehicle)
		if model == 275 or model == 295 then
			local siren = VehicleGetSiren(vehicle)
			if siren ~= svehicle[KEY_SIREN] then
				svehicle[KEY_SIREN] = siren
			end
		end
	end
end)
