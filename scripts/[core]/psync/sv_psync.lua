EVENT_TIMEOUT = 5000
EVENT_MAX = 100

gPlayers = {}

RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterNetworkEventHandler("psync:InitScript",function(player)
	if not gPlayers[player] then
		gPlayers[player] = {}
	end
	PedSetDamageGivenMultiplier(GetSyncPlayerPed(player),0,1)
end)
RegisterNetworkEventHandler("psync:ShootWeapon",function(player,ped,action,weapon)
	if gPlayers[player] then
		F_AddEvent(player)
		if IsSyncPedValid(ped) and F_IsWeaponValid(weapon) and GetSyncEntityOwner(ped) == player and type(action) == "string" then
			for other in pairs(gPlayers) do
				if other ~= player then
					SendNetworkEvent(other,"psync:ShootWeapon",ped,action,weapon)
				end
			end
		end
	end
end)
RegisterNetworkEventHandler("psync:ShotPed",function(player,ped,weapon,damage,headshot)
	if gPlayers[player] then
		F_AddEvent(player)
		if IsSyncPedValid(ped) and F_IsWeaponValid(weapon) and type(damage) == "number" and damage > 0 and damage < 1 / 0 then
			local dimension = GetSyncEntityDimension(GetSyncPlayerPed(player))
			if GetSyncEntityDimension(ped) == dimension and RunLocalEvent("psync:SyncProjectile",player) then
				local hp = math.max(0,PedGetHealth(ped)-damage)
				for other in pairs(gPlayers) do
					if other ~= player and GetSyncEntityDimension(GetSyncPlayerPed(other)) == dimension then
						if headshot then
							SendNetworkEvent(other,"psync:ShotPed",ped,weapon,hp,true)
						else
							SendNetworkEvent(other,"psync:ShotPed",ped,weapon,hp)
						end
					end
				end
				PedSetHealth(ped,hp)
			end
		end
	end
end)

-- utility
function F_AddEvent(player)
	local timer = GetAccurateTimer()
	local events = gPlayers[player]
	while events[1] and timer - events[1] >= EVENT_TIMEOUT do
		table.remove(events,1)
	end
	if events[EVENT_MAX] then
		if dsl.moderator_tools then
			dsl.moderator_tools.FileReport("[psync]",GetPlayerName(player),"spammed "..EVENT_MAX.." net events under "..EVENT_TIMEOUT.." ms")
		end
		PrintOutput(GetPlayerName(player).." hit psync event limit (ip: "..GetPlayerIp(player)..")")
		KickPlayer(player)
		error("psync event limit reached")
	end
	table.insert(events,timer)
end
function F_IsWeaponValid(weapon)
	return type(weapon) == "number" and math.floor(weapon) == weapon and weapon >= 299 and weapon <= 444
end
