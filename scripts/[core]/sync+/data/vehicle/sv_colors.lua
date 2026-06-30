-- SYNC+ | vehicle colors | Xx_Yubari_xX
--  provides server side sync for vehicle colors

LoadScript("data/utility/shared/keys.lua")

local st = GetScriptSharedTable()

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_COLOR_A or key == KEY_COLOR_B then
		return type(value) ~= "number" or math.floor(value) ~= value or not (value >= 0 and value <= 99)
	end
end)
RegisterLocalEventHandler("sync:CreateVehicle",function(vehicle)
	F_InitColor(vehicle,GetSyncEntityModel(vehicle))
end)
RegisterLocalEventHandler("sync:SwapModel",function(vehicle,model)
	if IsSyncVehicleValid(vehicle) then
		F_InitColor(vehicle,model)
	end
end)

-- initialize:
function F_InitColor(vehicle,model)
	local colors = st.colors[model]
	if colors then
		vehicle[KEY_COLOR_A],vehicle[KEY_COLOR_B] = unpack(colors[math.random(table.getn(colors))])
	else
		vehicle[KEY_COLOR_A] = 0
		vehicle[KEY_COLOR_B] = 0
	end
end
for vehicle in AllSyncVehicles() do
	F_InitColor(vehicle,GetSyncEntityModel(vehicle))
end

-- api:
RegisterFunction("VehicleGetColor",function(vehicle)
	if not IsSyncVehicleValid(vehicle) then
		typerror(1,"vehicle")
	end
	return vehicle[KEY_COLOR_A],vehicle[KEY_COLOR_B]
end)
RegisterFunction("VehicleSetColor",function(vehicle,a,b)
	if not IsSyncVehicleValid(vehicle) then
		typerror(1,"vehicle")
	elseif type(a) ~= "number" then
		typerror(2,"number")
	elseif type(b) ~= "number" then
		typerror(3,"number")
	end
	vehicle[KEY_COLOR_A] = a
	vehicle[KEY_COLOR_B] = b
end)
