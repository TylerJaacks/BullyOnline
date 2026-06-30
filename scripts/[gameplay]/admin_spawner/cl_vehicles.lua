local gVehicles = {}
local gManager

local gSpawning = 0
local gCreated

-- f2menu registry
RegisterNetworkEventHandler("admin_spawner:Allow",function()
	RegisterLocalEventHandler("f2menu:Open",function(f_add)
		f_add({
			name = "Vehicle Spawner",
			description = "(admin only)\nSpawn and manage vehicles.",
			thread = M_VehicleManager,
		})
	end)
	RegisterLocalEventHandler("f2menu:Shutdown",function()
		gManager = nil
	end)
end)

-- vehicle tracking
RegisterNetworkEventHandler("admin_spawner:RequestedVehicle",function(vehicle)
	gSpawning = gSpawning - 1
	gCreated = vehicle
end)
RegisterNetworkEventHandler("admin_spawner:SpawnedVehicle",function(vehicle,name)
	if type(vehicle) == "table" then
		gVehicles = vehicle
	else
		gVehicles[vehicle] = name
	end
	if gManager then
		F_UpdateManager()
	end
end)
RegisterLocalEventHandler("sync:DeleteVehicle",function(vehicle)
	gVehicles[vehicle] = nil
	if gManager then
		F_UpdateManager()
	end
end)

-- manager menu
function M_VehicleManager(parent,selected)
	local menu = parent:submenu(selected.name,"Manage vehicles.")
	F_UpdateManager()
	while menu:active() do
		if menu:option("< spawn new >",nil,"Spawn a new vehicle.") then
			M_SpawnVehicle(menu)
		end
		for _,v in ipairs(gManager) do
			if menu:option(v.name) then
				M_ManageVehicle(menu,v.scar)
			end
		end
		menu:draw()
		Wait(0)
	end
	gManager = nil
end
function F_UpdateManager()
	gManager = {}
	for scar,name in pairs(gVehicles) do
		table.insert(gManager,{scar = scar,name = name})
	end
	table.sort(gManager,function(a,b)
		return string.lower(a.name) < string.lower(b.name)
	end)
end

-- spawn vehicle
function M_SpawnVehicle(parent)
	local menu = parent:submenu("Spawn Vehicle")
	local cars = {}
	local names = {
		"bmxrace","retro","crapbmx","bikecop","Scooter","bike","custombike","banbike","mtnbike","oladbike","racer","aquabike",
		"Mower","Arc_3","taxicab","Arc_2","Dozer","GoCart","Limo","Dlvtruck","Foreign","cargreen","70wagon","policecar","domestic","Truck","Arc_1"
	}
	if dsl.propcars then
		cars = dsl.propcars.GetNames()
	end
	while menu:active() do
		for m = 272,298 do
			if menu:option("["..m.."] "..names[m-271]) then
				O_SpawnVehicle(menu,names[m-271],m)
			end
		end
		for _,car in ipairs(cars) do
			if menu:option(car,"["..(dsl.propcars.GetTag(car) or "INVALID").."]") then
				O_SpawnVehicle(menu,car,car)
			end
		end
		menu:draw()
		Wait(0)
	end
end
function O_SpawnVehicle(menu,name,model,x,y,z,h)
	gSpawning = gSpawning + 1
	SendNetworkEvent("admin_spawner:SpawnVehicle",name,model,F_SpawnPosition())
	while menu:active() and gSpawning ~= 0 do
		menu:draw("[SPAWNING]")
		Wait(0)
	end
	if gCreated then
		M_ManageVehicle(menu,gCreated)
	end
end
function F_SpawnPosition()
	if dsl.freecam and dsl.freecam.IsActive() then
		local x,y,z = dsl.freecam.GetPosition(0,3,0)
		local p,r,h = dsl.freecam.GetRotation()
		return x,y,z,h
	else
		local h,x,y,z = PedGetHeading(gPlayer),PlayerGetPosXYZ()
		return x-math.sin(h)*5,y+math.cos(h)*5,z+1,math.deg(h)
	end
end

-- manage vehicle
function M_ManageVehicle(parent,scar)
	local menu = parent:submenu("Manage Vehicle")
	while gVehicles[scar] and menu:active() do
		if menu:option("Warp Into Vehicle",nil,"Warp into this vehicle.") then
			O_WarpVehicle(menu,scar)
		elseif menu:option("Set Lock Key",nil,"Set the lock on this vehicle.") then
			O_SetLock(menu,scar)
		elseif menu:option("Delete Vehicle",nil,"Delete this vehicle.") then
			SendNetworkEvent("admin_spawner:DeleteVehicle",scar)
		end
		menu:draw()
		Wait(0)
	end
end
function O_WarpVehicle(menu,scar)
	local seat = 0
	while gVehicles[scar] and menu:active() do
		menu:draw("> seat: "..seat.." <")
		Wait(0)
		if menu:up() then
			seat = math.mod(seat+1,4)
		elseif menu:down() then
			seat = seat - 1
			if seat < 0 then
				seat = 3
			end
		elseif menu:right() then
			SendNetworkEvent("admin_spawner:WarpVehicle",scar,seat)
			break
		elseif menu:left() then
			break
		end
	end
end
function O_SetLock(menu,scar)
	local typing = StartTyping()
	if not typing then
		return
	end
	while menu:active() do
		if not IsTypingActive(typing) then
			if not WasTypingAborted(typing) then
				SendNetworkEvent("admin_spawner:LockVehicle",scar,GetTypingString(typing))
			end
			break
		end
		menu:draw(GetTypingString(typing,true))
		Wait(0)
	end
end

-- request vehicles
SendNetworkEvent("admin_spawner:InitVehicles")
