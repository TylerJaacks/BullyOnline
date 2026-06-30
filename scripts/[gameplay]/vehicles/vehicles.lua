-- vehicle functions
function F_GetVehicleStat(vehicle,key)
	local stats
	if gDerpyScriptServer then
		stats = gVehicleModels[GetSyncEntityModel(vehicle)]
	else
		stats = gVehicleModels[VehicleGetModelId(vehicle)]
	end
	if stats then
		return stats[key]
	end
end
function F_GetEnterNode(vehicle)
	return F_GetVehicleStat(vehicle,"enter")
end
function F_GetExitNode(vehicle)
	return F_GetVehicleStat(vehicle,"exit")
end
function F_GetMoveNode(vehicle)
	return F_GetVehicleStat(vehicle,"move")
end
function F_GetPickupNode(vehicle)
	return F_GetVehicleStat(vehicle,"pickup")
end
function F_ShouldVehicleWarp(vehicle,seat)
	if dsl.propcars then
		local warp = dsl.propcars.ShouldUseWarp(vehicle,seat)
		if warp ~= nil then
			return warp
		end
	end
	return (seat ~= 0 and F_GetVehicleStat(vehicle,"warp_except_driver")) or F_GetVehicleStat(vehicle,"warp") or false
end
function F_GetMaxSeats(vehicle)
	if dsl.propcars then
		local seats = dsl.propcars.GetMaxSeats(vehicle)
		if seats then
			return seats
		end
	end
	return F_GetVehicleStat(vehicle,"seats") or 1
end
function F_IsLockable(vehicle)
	if dsl.propcars then
		local lockable = dsl.propcars.IsLockable(vehicle)
		if lockable ~= nil then
			return lockable
		end
	end
	return F_GetVehicleStat(vehicle,"lockable") or false
end
function F_IsMotorcycle(vehicle)
	return F_GetVehicleStat(vehicle,"motorcycle") or false
end

-- normal vehicles
gVehicleModels = {
	[272] = { -- bmxrace
		lockable = false,
		seats = 1,
	},
	[273] = { -- retro
		lockable = false,
		seats = 1,
	},
	[274] = { -- crapbmx
		lockable = false,
		seats = 1,
	},
	[275] = { -- bikecop
		motorcycle = true,
		warp = true,
		lockable = false,
		seats = 1,
	},
	[276] = { -- Scooter
		lockable = false,
		seats = 1,
	},
	[277] = { -- bike
		lockable = false,
		seats = 1,
	},
	[278] = { -- custombike
		lockable = false,
		seats = 1,
	},
	[279] = { -- banbike
		lockable = false,
		seats = 1,
	},
	[280] = { -- mtnbike
		lockable = false,
		seats = 1,
	},
	[281] = { -- oladbike
		lockable = false,
		seats = 1,
	},
	[282] = { -- racer
		lockable = false,
		seats = 1,
	},
	[283] = { -- aquabike
		lockable = false,
		seats = 1,
	},
	[284] = { -- Mower
		lockable = false,
		seats = 1,
	},
	[285] = { -- Arc_3
		lockable = true,
		seats = 1,
		warp = true,
	},
	[286] = { -- taxicab
		lockable = true,
		seats = 4,
		move = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/%s",
		enter = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/ATCAR/GETINVEHICLE/%s/SEDAN",
		exit = "/GLOBAL/VEHICLES/CARS/CARGROUND/DISMOUNT/GETOFF/SUV/%s/EXITVEHICLE",
	},
	[287] = { -- Arc_2
		lockable = true,
		seats = 4,
		warp = true,
	},
	[288] = { -- Dozer
		lockable = true,
		seats = 1,
		move = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/%s",
		enter = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/ATCAR/GETINVEHICLE/%s/TRUCK",
		exit = "/GLOBAL/VEHICLES/CARS/CARGROUND/DISMOUNT/GETOFF/TRUCK/%s/EXITVEHICLE",
	},
	[289] = { -- GoCart
		lockable = false,
		seats = 1,
	},
	[290] = { -- Limo
		lockable = true,
		seats = 4,
		move = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/%s",
		enter = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/ATCAR/GETINVEHICLE/%s/SEDAN",
		exit = "/GLOBAL/VEHICLES/CARS/CARGROUND/DISMOUNT/GETOFF/SUV/%s/EXITVEHICLE",
	},
	[291] = { -- Dlvtruck
		lockable = true,
		seats = 2,
		move = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/%s",
		enter = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/ATCAR/GETINVEHICLE/%s/TRUCK",
		exit = "/GLOBAL/VEHICLES/CARS/CARGROUND/DISMOUNT/GETOFF/TRUCK/%s/EXITVEHICLE",
	},
	[292] = { -- Foreign
		lockable = true,
		seats = 4,
		move = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/%s",
		enter = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/ATCAR/GETINVEHICLE/%s/SEDAN",
		exit = "/GLOBAL/VEHICLES/CARS/CARGROUND/DISMOUNT/GETOFF/SUV/%s/EXITVEHICLE",
	},
	[293] = { -- cargreen
		lockable = true,
		seats = 4,
		move = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/%s",
		enter = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/ATCAR/GETINVEHICLE/%s/SEDAN",
		exit = "/GLOBAL/VEHICLES/CARS/CARGROUND/DISMOUNT/GETOFF/SUV/%s/EXITVEHICLE",
	},
	[294] = { -- 70wagon
		lockable = true,
		seats = 4,
		move = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/%s",
		enter = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/ATCAR/GETINVEHICLE/%s/SEDAN",
		exit = "/GLOBAL/VEHICLES/CARS/CARGROUND/DISMOUNT/GETOFF/SUV/%s/EXITVEHICLE",
	},
	[295] = { -- policecar
		lockable = true,
		seats = 2,
		move = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/%s",
		enter = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/ATCAR/GETINVEHICLE/%s/SUV",
		exit = "/GLOBAL/VEHICLES/CARS/CARGROUND/DISMOUNT/GETOFF/SUV/%s/EXITVEHICLE",
	},
	[296] = { -- domestic
		lockable = true,
		seats = 4,
		move = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/%s",
		enter = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/ATCAR/GETINVEHICLE/%s/SEDAN",
		exit = "/GLOBAL/VEHICLES/CARS/CARGROUND/DISMOUNT/GETOFF/SUV/%s/EXITVEHICLE",
	},
	[297] = { -- Truck
		lockable = true,
		seats = 2,
		move = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/%s",
		enter = "/GLOBAL/VEHICLES/CARS/MOVETOVEHICLE/ATCAR/GETINVEHICLE/%s/SUV",
		exit = "/GLOBAL/VEHICLES/CARS/CARGROUND/DISMOUNT/GETOFF/SUV/%s/EXITVEHICLE",
	},
	[298] = { -- Arc_1
		lockable = true,
		seats = 1,
		warp = true,
	},
}

-- key items
gKeyItems = {}
for key in AllConfigStrings(GetScriptConfig(),"key_item") do
	gKeyItems[key] = true
end
