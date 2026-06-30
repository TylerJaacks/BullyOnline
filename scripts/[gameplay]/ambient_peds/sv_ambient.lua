DontRateLimitNetworkEvent("ambient_peds:SpawnPed")
LoadScript("population.lua")

gDimensions = {}
gPlayers = {}

-- player events
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterNetworkEventHandler("ambient_peds:UpdateArea",function(player,area,trigger)
	if type(area) == "number" and math.floor(area) == area then
		local pd = gPlayers[player]
		if not pd then
			pd = {
				-- .area is saved to validate their sync ped is in the same area as they sent us
				-- .population is their current population table (or nil)
				-- .spawning is set when the server is waiting for a spawn response
			}
			gPlayers[player] = pd
		end
		pd.area = area
		pd.population = gTriggerPopulation[trigger] or gDefaultPopulation[area]
	end
end)
RegisterNetworkEventHandler("ambient_peds:SpawnPed",function(player,area,trigger,x,y,z)
	local pd = gPlayers[player]
	if pd then
		local sd = pd.spawning
		if sd then
			if x and ValidateSyncPos(GetSyncPlayerPed(player),x,y,z) then
				local data = gDimensions[sd.di]
				local population = gTriggerPopulation[trigger] or gDefaultPopulation[area]
				if data and data.active and (data.override or population) and (data.override or F_GetPopulation(population)) == sd.pop then
					-- ped production is active and the current population is the same as when requested, so attempt a spawn
					F_AttemptSpawn(data.peds,sd,x,y,z)
				end
			end
			pd.spawning = nil
		end
	end
end)

-- ped tracking
RegisterLocalEventHandler("sync:DeletePed",function(ped)
	for _,data in pairs(gDimensions) do
		if F_RemovePedFromList(data.peds,ped) then
			break
		end
	end
end)
RegisterLocalEventHandler("sync:SwapDimension",function(ped,new)
	for old,data in pairs(gDimensions) do
		local v = F_RemovePedFromList(data.peds,ped)
		if v then
			table.insert(F_GetDimension(new).peds,v)
			break
		end
	end
end)

-- entity space maintainer
RegisterLocalEventHandler("sync:CreateEntity",function(ent)
	local di = GetSyncEntityDimension(ent)
	local data = gDimensions[di]
	if data and data.peds[1] then
		SetSyncActiveDimension(di)
		if GetSyncEntitySpace() < MINIMUM_SPACE then
			DeleteSyncEntity(table.remove(data.peds,math.random(data.peds.n)))
		end
	end
end)

-- general utility
function F_Dist(x1,y1,z1,x2,y2,z2)
	local dx,dy,dz = x2-x1,y2-y1,z2-z1
	return dx*dx+dy*dy+dz*dz
end

-- spawner / despawner thread
function T_Spawner(di,data)
	while true do
		F_Despawner(di,data.peds)
		F_Spawner(di,data)
		Wait(0)
	end
end
function F_Despawner(di,peds)
	local index = 1
	while peds[index] do
		local x,y,z = GetSyncEntityPos(peds[index].ped)
		if F_IsAnyPlayerNearby(x,y,z,di,DESPAWN_DISTANCE) then
			index = index + 1
		else
			DeleteSyncEntity(table.remove(peds,index).ped)
		end
	end
end
function F_Spawner(di,data)
	if data.active and data.peds.n < MAXIMUM_SPAWNED and GetSyncEntitySpace() > MINIMUM_SPACE then
		for player in AllSyncPlayers(di) do
			local pd = gPlayers[player]
			if pd and (data.override or pd.population) and not pd.spawning then
				local pop = data.override or F_GetPopulation(pd.population)
				local ped = GetSyncPlayerPed(player)
				local x,y,z = GetSyncEntityPos(ped)
				if GetSyncEntityArea(ped) == pd.area and F_GetNearbyCount(x,y,z,data.peds) < math.min(pop[1],MAX_NEARBY_POPULATION) then
					local factions = {n = 0}
					for index,count in ipairs(F_GetNearbyCounts(x,y,z,data.peds)) do
						if count < pop[index+1] then
							table.insert(factions,index) -- not enough of this faction
						end
					end
					while factions[1] do
						local models = {n = 0}
						local faction = table.remove(factions,math.random(factions.n))
						for i,m in ipairs(gFactionModels[faction]) do
							table.insert(models,m)
						end
						while models[1] do
							local model = table.remove(models,math.random(models.n))
							if not model then
								print("models:")
								for k,v in pairs(models) do
									print(k,v)
								end
								error("ambient spawner messed up")
							end
							if not F_IsModelNearby(x,y,z,di,model,gUniqueStatus[model+1]) then
								SendNetworkEvent(player,"ambient_peds:GetSpawn")
								pd.spawning = {
									di = di,
									pop = pop,
									model = model,
									faction = faction,
								}
							end
						end
					end
				end
			end
		end
	end
end

-- spawning utility
function F_AttemptSpawn(peds,sd,x,y,z)
	SetSyncActiveDimension(sd.di)
	if peds.n < MAXIMUM_SPAWNED and GetSyncEntitySpace() > MINIMUM_SPACE and F_IsAnyPlayerNearby(x,y,z,sd.di,SPAWN_DIST_MAX) and not F_IsAnyPlayerNearby(x,y,z,sd.di,SPAWN_DIST_MIN) then
		local range = SPAWN_SPACING_PEDS * SPAWN_SPACING_PEDS
		for ped in AllSyncPeds(sd.di) do
			if F_Dist(x,y,z,GetSyncEntityPos(ped)) < range then
				return
			end
		end
		range = SPAWN_SPACING_VEHICLES * SPAWN_SPACING_VEHICLES
		for vehicle in AllSyncVehicles(sd.di) do
			if F_Dist(x,y,z,GetSyncEntityPos(vehicle)) < range then
				return
			end
		end
		if F_GetNearbyCount(x,y,z,peds) < math.min(sd.pop[1],MAX_NEARBY_POPULATION) then
			local count = 0
			for _,v in ipairs(peds) do
				if v.faction == sd.faction and F_Dist(x,y,z,GetSyncEntityPos(v.ped)) < range then
					count = count + 1
				end
			end
			if count < sd.pop[sd.faction+1] and not F_IsModelNearby(x,y,z,sd.di,sd.model,gUniqueStatus[sd.model+1]) and RunLocalEvent("ambient_peds:SpawningPed",sd.model,x,y,z) then
				local ped = CreateSyncPed(sd.model)
				SetSyncEntityPos(ped,x,y,z)
				PedWander(ped) -- from sync+
				table.insert(peds,{ped = ped,faction = sd.faction})
				RunLocalEvent("ambient_peds:SpawnedPed",ped)
			end
		end
	end
end
function F_GetPopulation(population)
	local h,m = ClockGet() -- from sync+
	if h >= 7 and h < 9 then
		return population[1] -- POPULATION_DAY: 7:00 AM - 8:59 AM
	elseif h >= 9 and (h < 11 or (h == 12 and m < 30)) then
		return population[2] -- POPULATION_CLASS: 9:00 AM - 11:29 AM
	elseif ((h == 11 and m >= 30) or h >= 12) and h < 13 then
		return population[1] -- POPULATION_DAY: 11:30 AM - 12:59 PM
	elseif h >= 13 and (h < 15 or (h == 15 and m < 30)) then
		return population[2] -- POPULATION_CLASS: 1:00 PM - 3:29 PM
	elseif ((h == 15 and m >= 30) or h >= 16) and h < 19 then
		return population[1] -- POPULATION_DAY: 3:30 PM - 6:59 PM
	elseif h >= 19 and h < 23 then
		return population[3] -- POPULATION_NIGHT: 7:00 PM - 10:59 PM
	end
	return population[4] -- POPULATION_CURFEW: 11:00 PM - 6:59 AM
end
function F_GetNearbyCount(x,y,z,peds)
	local count = 0
	local range = POPULATION_DISTANCE * POPULATION_DISTANCE
	for _,v in ipairs(peds) do
		if F_Dist(x,y,z,GetSyncEntityPos(v.ped)) < range then
			count = count + 1
		end
	end
	return count
end
function F_GetNearbyCounts(x,y,z,peds)
	local counts = {}
	local range = POPULATION_DISTANCE * POPULATION_DISTANCE
	for f = 1,12 do
		counts[f] = 0
	end
	for _,v in ipairs(peds) do
		if v.faction ~= 0 and F_Dist(x,y,z,GetSyncEntityPos(v.ped)) < range then
			counts[v.faction] = counts[v.faction] + 1
		end
	end
	return counts
end
function F_IsModelNearby(x,y,z,di,model,limit)
	if limit >= 1 then
		local range = POPULATION_DISTANCE * POPULATION_DISTANCE
		for ped in AllSyncPeds(di) do
			if GetSyncEntityModel(ped) == model and F_Dist(x,y,z,GetSyncEntityPos(ped)) < range then
				limit = limit - 1
				if limit < 1 then
					return true -- model limit reached
				end
			end
		end
		return false -- model limit not reached
	end
	return true -- limit is below 1
end
function F_IsAnyPlayerNearby(x,y,z,di,range)
	range = range * range
	for player in AllSyncPlayers(di) do
		if F_Dist(x,y,z,GetSyncEntityPos(GetSyncPlayerPed(player))) < range then
			return true
		end
	end
	return false
end

-- dimension state
function F_GetDimension(di)
	local data = gDimensions[di]
	if not data then
		data = {
			-- .active is true if ped production is enabled
			-- .override is a table for the current population override (or nil)
			peds = {n = 0}, -- each ped is {ped = ped, faction = faction} where faction is an index
		}
		data.thread = CreateThread("T_Spawner",di,data)
		gDimensions[di] = data
	end
	return data
end
function F_ValidateDimension(di)
	local data = gDimensions[di]
	if data and not data.peds[1] and not data.active and not data.override then
		TerminateThread(data.thread)
		gDimensions[di] = nil
	end
end
function F_RemovePedFromList(peds,ped)
	for i,v in ipairs(peds) do
		if v.ped == ped then
			return table.remove(peds,i)
		end
	end
end

-- api functions
RegisterFunction("PedMakeAmbient",function(ped)
	for _,data in pairs(gDimensions) do
		for i,v in ipairs(data.peds) do
			if v.ped == ped then
				return -- already ambient
			end
		end
	end
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	table.insert(F_GetDimension(GetSyncEntityDimension(ped)).peds,{ped = ped,faction = 0})
end)
RegisterFunction("StopPedProduction",function(stop)
	local di = GetSyncActiveDimension()
	if type(stop) ~= "boolean" then
		typerror(1,"boolean")
	end
	F_GetDimension(di).active = not stop
	F_ValidateDimension(di)
end)
RegisterFunction("AreaOverridePopulation",function(...)
	for i = 1,13 do
		if type(arg[i]) ~= "number" then
			typerror(i,"number")
		end
	end
	while arg.n > 13 do
		table.remove(arg)
	end
	arg.n = nil
	F_GetDimension(GetSyncActiveDimension()).override = arg
end)
RegisterFunction("AreaRevertToDefaultPopulation",function()
	local di = GetSyncActiveDimension()
	F_GetDimension(di).override = nil
	F_ValidateDimension(di)
end)
RegisterFunction("PedGetUniqueModelStatus",function(model)
	if type(model) ~= "number" then
		typerror(1,"number")
	elseif not gUniqueStatus[model] then
		argerror(1,"invalid model")
	end
	return gUniqueStatus[model]
end)
RegisterFunction("PedSetUniqueModelStatus",function(model,status)
	if type(model) ~= "number" then
		typerror(1,"number")
	elseif type(status) ~= "number" then
		typerror(2,"number")
	elseif not gUniqueStatus[model] then
		argerror(1,"invalid model")
	end
	gUniqueStatus[model] = status
end)

-- turn on by default if set
if ON_BY_DEFAULT then
	SetSyncActiveDimension(GetSyncMainDimension())
	StopPedProduction(false)
end

function ClockGet() return 16,0 end -- temporary until sync+ does it
