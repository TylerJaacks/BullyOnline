-- SYNC+ | vehicle sirens | Xx_Yubari_xX
--  provides server side sync for vehicle sirens

LoadScript("data/utility/shared/keys.lua")

local st = GetScriptSharedTable()

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_SIREN then
		return type(value) ~= "boolean"
	end
end)
RegisterLocalEventHandler("sync:CreateVehicle",function(vehicle)
	vehicle[KEY_SIREN] = false
end)

-- initialize:
for vehicle in AllSyncVehicles() do
	vehicle[KEY_SIREN] = false
end

-- api:
RegisterFunction("VehicleGetSiren",function(vehicle)
	if not IsSyncVehicleValid(vehicle) then
		typerror(1,"vehicle")
	end
	return vehicle[KEY_SIREN]
end)
RegisterFunction("VehicleEnableSiren",function(vehicle,on)
	if not IsSyncVehicleValid(vehicle) then
		typerror(1,"vehicle")
	elseif on == nil then
		vehicle[KEY_SIREN] = true
	elseif type(on) ~= "boolean" then
		typerror(2,"boolean")
	end
	vehicle[KEY_SIREN] = on
end)
