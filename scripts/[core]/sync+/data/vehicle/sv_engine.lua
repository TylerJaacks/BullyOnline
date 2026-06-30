-- SYNC+ | vehicle engine | Xx_Yubari_xX
--  provides server side sync for vehicle engines

LoadScript("data/utility/shared/keys.lua")

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_ENGINE then
		return type(value) ~= "boolean"
	end
end)
RegisterLocalEventHandler("sync:CreateVehicle",function(vehicle)
	vehicle[KEY_ENGINE] = false
end)

-- initialize:
for vehicle in AllSyncVehicles() do
	vehicle[KEY_ENGINE] = false
end

-- api:
RegisterFunction("VehicleGetEngine",function(vehicle)
	if not IsSyncVehicleValid(vehicle) then
		typerror(1,"vehicle")
	end
	return vehicle[KEY_ENGINE]
end)
RegisterFunction("VehicleEnableEngine",function(vehicle,on)
	if not IsSyncVehicleValid(vehicle) then
		typerror(1,"vehicle")
	elseif on == nil then
		vehicle[KEY_ENGINE] = true
	elseif type(on) ~= "boolean" then
		typerror(2,"boolean")
	end
	vehicle[KEY_ENGINE] = on
end)
