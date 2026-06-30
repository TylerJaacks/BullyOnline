-- SYNC+ | vehicle colors | Xx_Yubari_xX
--  provides client side sync for vehicle colors

LoadScript("data/utility/shared/keys.lua")

-- apply:
RegisterLocalEventHandler("sync:PreUpdateVehicle",function(svehicle)
	local vehicle = VehicleFromSyncVehicle(svehicle)
	if VehicleIsValid(vehicle) and (WasSyncEntityUpdated(svehicle,KEY_COLOR_A) or WasSyncEntityUpdated(svehicle,KEY_COLOR_B) or not IsSyncEntityOwned(svehicle)) then
		local a,b = VehicleGetColor(vehicle)
		if a ~= svehicle[KEY_COLOR_A] or b ~= svehicle[KEY_COLOR_B] then
			VehicleSetColor(vehicle,svehicle[KEY_COLOR_A],svehicle[KEY_COLOR_B])
		end
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdateVehicle",function(svehicle)
	local vehicle = VehicleFromSyncVehicle(svehicle)
	if VehicleIsValid(vehicle) then
		local a,b = VehicleGetColor(vehicle)
		if a ~= svehicle[KEY_COLOR_A] then
			svehicle[KEY_COLOR_A] = a
		end
		if b ~= svehicle[KEY_COLOR_B] then
			svehicle[KEY_COLOR_B] = b
		end
	end
end)
