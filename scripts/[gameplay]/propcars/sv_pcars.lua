local gAdmins = {}
local gPlayers = {}
local gConfigs = LoadTable("propcars.bin")
local gCars = {}

TAGS = {"OFFICIAL","UNOFFICIAL","EXPERIMENT",OFFICIAL = 1,UNOFFICIAL = 2,EXPERIMENT = 3}

function exports.CreateVehicle(name)
	local v = F_FindConfig(name)
	if v then
		local car = CreateSyncVehicle(v.model)
		if car then
			for player in pairs(gPlayers) do
				if not IsPlayerValid(player) then
					gPlayers[player] = nil
				end
			end
			F_SetCar(car,v)
		end
		return car
	end
	argerror(1,"invalid propcar")
end

function exports.GetNames() -- table
	local list = {}
	for i,v in ipairs(gConfigs) do
		list[i] = v.name
	end
	return list
end
function exports.GetName(car) -- nil | string
	local v = gCars[car]
	if v then
		return v.name
	end
end
function exports.IsInvisible(car) -- boolean
	local v = gCars[car]
	if v then
		return v.invisible
	end
	return false
end
function exports.ArePedsInvisible(car) -- boolean
	local v = gCars[car]
	if v then
		return v.hidepeds
	end
	return false
end
function exports.ShouldUseWarp(car,seat) -- nil | boolean
	local v = gCars[car]
	if v then
		if seat == 0 then
			return v.warp == 2
		end
		return v.warp ~= 0
	end
end
function exports.GetMaxSeats(car) -- nil | number [0, 3]
	local v = gCars[car]
	return v and v.seats
end
function exports.IsLockable(car) -- nil | boolean
	local v = gCars[car]
	return v and v.lockable
end
function exports.HasEngine(car) -- nil | boolean
	local v = gCars[car]
	return v and v.engine
end

RegisterLocalEventHandler("PlayerDropped",function(player)
	gAdmins[player] = nil
	gPlayers[player] = nil
end)
RegisterNetworkEventHandler("propcars:StartScript",function(player)
	if DoesPlayerHaveRole(player,"admin") then
		gAdmins[player] = true
		SendNetworkEvent(player,"propcars:GiveMenu")
	end
	SendNetworkEvent(player,"propcars:InitConfig",gConfigs)
	for car,v in pairs(gCars) do
		SendNetworkEvent(player,"propcars:SetCar",car,v.name)
	end
	gPlayers[player] = true
end)

RegisterNetworkEventHandler("propcars:NewConfig",function(player,name,model)
	if gAdmins[player] then
		if not F_FindConfig(name) then
			local v = F_NewConfig(name,model)
			table.insert(gConfigs,v)
			F_ResortConfigs()
			for player in pairs(gPlayers) do
				SendNetworkEvent(player,"propcars:UpdateConfig",v)
			end
		end
		SendNetworkEvent(player,"propcars:CreatedConfig")
		SaveTable("propcars.bin",gConfigs)
	end
end)
RegisterNetworkEventHandler("propcars:UpdateConfig",function(player,value)
	if gAdmins[player] and F_UpdateConfig(value) then
		for player in pairs(gPlayers) do
			SendNetworkEvent(player,"propcars:UpdateConfig",value)
		end
		SaveTable("propcars.bin",gConfigs)
	end
end)
RegisterNetworkEventHandler("propcars:DuplicateConfig",function(player,src,dest)
	src = F_FindConfig(src)
	if src and gAdmins[player] and not F_FindConfig(dest) then
		local copy = {}
		for k,v in pairs(src) do
			copy[k] = v
		end
		copy.name = dest
		table.insert(gConfigs,copy)
		F_ResortConfigs()
		for player in pairs(gPlayers) do
			SendNetworkEvent(player,"propcars:UpdateConfig",copy)
		end
		SaveTable("propcars.bin",gConfigs)
	end
end)
RegisterNetworkEventHandler("propcars:RemoveConfig",function(player,name)
	if gAdmins[player] then
		local i = 1
		for car,v in pairs(gCars) do
			if v.name == name then
				gCars[car] = nil
			end
		end
		while gConfigs[i] do
			if gConfigs[i].name == name then
				table.remove(gConfigs,i)
			else
				i = i + 1
			end
		end
		for player in pairs(gPlayers) do
			SendNetworkEvent(player,"propcars:RemoveConfig",name)
		end
		SaveTable("propcars.bin",gConfigs)
	end
end)

RegisterLocalEventHandler("sync:DeleteVehicle",function(car)
	gCars[car] = nil
end)

RegisterLocalEventHandler("ScriptShutdown",function(s)
	if s == GetCurrentScript() then
		for car in pairs(gCars) do
			DeleteSyncEntity(car)
		end
	end
end)

function F_ResortConfigs()
	table.sort(gConfigs,function(a,b)
		local x,y = TAGS[a.tag],TAGS[b.tag]
		if x ~= y then
			return x < y
		end
		return string.lower(a.name) < string.lower(b.name)
	end)
end
function F_UpdateConfig(value)
	for i,v in ipairs(gConfigs) do
		if v.name == value.name then
			gConfigs[i] = value
			F_ResortConfigs()
			return true
		end
	end
	return false
end
function F_FindConfig(name)
	for _,v in ipairs(gConfigs) do
		if v.name == name then
			return v
		end
	end
end
function F_NewConfig(name,model)
	return {
		name = name,
		model = model,
		props = {},
		invisible = false,
		hidepeds = false,
		unique = false,
		warp = 0, -- 0 no, 1 passengers, 2 anyone
		seats = 4,
		lockable = true,
		engine = false, -- has an engine
		tag = "OFFICIAL",
		-- can also have honk table for {sound, bank}
	}
end
function F_SetCar(car,v)
	gCars[car] = v
	for player in pairs(gPlayers) do
		SendNetworkEvent(player,"propcars:SetCar",car,v.name)
	end
end
