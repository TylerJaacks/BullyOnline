gPlayers = {}
gDefaultSpawns = {
	{-748.05, 636.78, 30.93, 0.9}, -- BMX Park
	{-568.53, 136.23, 46.15, 0.9}, -- Harrington House
	{-728.33, 37.38, -2.33, 0.9}, -- Dragon's Wing Basement
	--{-730.70, 382.70, 298.04, 0.9}, -- Boxing Gym Upstairs Room
	--{-418.37, 376.59, 80.84, 0.9}, -- Auto Shop
}

RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterLocalEventHandler("sync:CreatePlayer",function(player,ped)
	SetSyncEntityPos(GetSyncPlayerPed(player),F_GetSpawn(player,true))
	RunLocalEvent("spawner:Spawned",player)
end)
RegisterNetworkEventHandler("spawner:_Init",function(player)
	gPlayers[player] = true
end)
RegisterNetworkEventHandler("spawner:_Dead",function(player)
	if gPlayers[player] then
		local ped = GetSyncPlayerPed(player)
		if not dsl["sync+"] or PedIsDead(ped) then
			local x,y,z,h = F_GetSpawn(player,false)
			if x then
				if dsl["sync+"] then
					PedSetDead(ped,false)
				else
					SendNetworkEvent(player,"spawner:_Revive")
				end
				if h then
					SetSyncEntityPos(ped,x,y,z,h)
				else
					SetSyncEntityPos(ped,x,y,z)
				end
				RunLocalEvent("spawner:Respawned",player)
			end
		end
	end
end)

function F_GetSpawn(player,initial)
	local x,y,z,r = unpack(gDefaultSpawns[math.random(table.getn(gDefaultSpawns))])
	local h = math.rad(math.random(0,359))
	local d = math.random(0,r*100) / 100
	local f_set = function(sx,sy,sz,sh)
		if type(x) ~= "number" then
			typerror(1,"number")
		elseif type(y) ~= "number" then
			typerror(2,"number")
		elseif type(z) ~= "number" then
			typerror(3,"number")
		end
		x,y,z = sx,sy,sz
		if h ~= nil then
			if type(h) ~= "number" then
				typerror(4,"number")
			end
			h = sh
		end
	end
	x,y,z = x-math.sin(h)*d,y+math.cos(h)*d,z
	if initial then
		RunLocalEvent("spawner:Spawning",player,f_set)
		return x,y,z,h
	elseif RunLocalEvent("spawner:Respawning",player,f_set) then
		return x,y,z,h
	end
end
