OPEN_RANGE = 2
CLOSE_RANGE = 3

gPlayers = {}
gTrash = LoadTable("trash.bin")

RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterLocalEventHandler("ScriptShutdown",function(s)
	if s == GetCurrentScript() then
		if dsl.inventory then
			for player,storage in pairs(gPlayers) do
				if dsl.inventory.GetPlayerStorage(player) == storage[1] then
					dsl.inventory.SetPlayerStorage(player,nil)
				end
			end
		end
	end
end)
RegisterNetworkEventHandler("trash_cans:OpenTrash",function(player)
	local ped = GetSyncPlayerPed(player)
	local pa,px,py,pz,ph = GetSyncEntityArea(ped),GetSyncEntityPos(ped)
	for _,trash in ipairs(gTrash) do
		local tm,ta,tx,ty,tz,th = unpack(trash)
		if ta == pa then
			local dx,dy,dz = tx-px,ty-py,tz-pz
			if dx*dx+dy*dy+dz*dz < OPEN_RANGE*OPEN_RANGE then
				if dsl.inventory then
					local id = string.format("trash_%d_%.3d_%.3d_%.3d",ta,tx,ty,tz)
					dsl.inventory.SetPlayerStorage(player,id,"Trash Receptacle")
					gPlayers[player] = {id,tx,ty,tz}
				end
				return
			end
		end
	end
end)
CreateThread(function()
	while true do
		if dsl.inventory then
			for player,storage in pairs(gPlayers) do
				local sid,sx,sy,sz = unpack(storage)
				if dsl.inventory.GetPlayerStorage(player) == sid then
					local px,py,pz = GetSyncEntityPos(GetSyncPlayerPed(player))
					local dx,dy,dz = sx-px,sy-py,sz-pz
					if dx*dx+dy*dy+dz*dz >= CLOSE_RANGE*CLOSE_RANGE then
						dsl.inventory.SetPlayerStorage(player,nil)
						gPlayers[player] = nil
					end
				else
					gPlayers[player] = nil
				end
			end
		elseif next(gPlayers) then
			gPlayers = {}
		end
		Wait(0)
	end
end)
