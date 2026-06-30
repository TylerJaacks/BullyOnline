LoadScript("population.lua")

gTriggers = {n = 0}

-- area / trigger tracker
function main()
	local area,trigger
	while true do
		local na = AreaGetVisible()
		local nt = F_UpdateTrigger()
		if na ~= area or nt ~= trigger then
			if nt then
				SendNetworkEvent("ambient_peds:UpdateArea",na,nt)
			else
				SendNetworkEvent("ambient_peds:UpdateArea",na) -- without trigger
			end
			area,trigger = na,nt
		end
		Wait(0)
	end
end
function F_GetTrigger()
	return gTriggers[gTriggers.n]
end
function F_UpdateTrigger()
	-- triggers are held in the order they were triggered, and the most recent is used for spawning
	for index,population in ipairs(gTriggerPopulation) do
		if PedIsInTrigger(gPlayer,TRIGGER[population.name]) then
			if not population.inside then
				table.insert(gTriggers,index)
				population.inside = true
			end
		elseif population.inside then
			for i,v in ipairs(gTriggers) do
				if v == index then
					table.remove(gTriggers,i)
					break
				end
			end
			population.inside = nil
		end
	end
	return gTriggers[gTriggers.n]
end

-- validate spawn
function F_ValidateSpawn(x,y,z)
	local dist = F_Dist(x,y,z,PlayerGetPosXYZ())
	if dist >= SPAWN_DIST_MIN * SPAWN_DIST_MIN and dist < SPAWN_DIST_MAX * SPAWN_DIST_MAX then
		local range = SPAWN_SPACING_PEDS * SPAWN_SPACING_PEDS
		for ped in AllSyncPeds() do
			if F_Dist(x,y,z,GetSyncEntityPos(ped)) < range then
				return false
			end
		end
		range = SPAWN_SPACING_VEHICLES * SPAWN_SPACING_VEHICLES
		for vehicle in AllSyncVehicles() do
			if F_Dist(x,y,z,GetSyncEntityPos(vehicle)) < range then
				return false
			end
		end
		return true
	end
	return false
end
function F_Dist(x1,y1,z1,x2,y2,z2)
	local dx,dy,dz = x2-x1,y2-y1,z2-z1
	return dx*dx+dy*dy+dz*dz
end

-- spawn getter
RegisterNetworkEventHandler("ambient_peds:GetSpawn",function()
	local started = GetTimer()
	CreateThread(function()
		while GetTimer() - started < 1000 do
			local x,y,z = PedFindRandomSpawnPosition(gPlayer)
			if x ~= 9999 and F_ValidateSpawn(x,y,z) then
				SendNetworkEvent("ambient_peds:SpawnPed",AreaGetVisible(),F_GetTrigger(),x,y,z)
				return
			end
			Wait(0)
		end
		SendNetworkEvent("ambient_peds:SpawnPed") -- no arguments means we give up
	end)
end)
