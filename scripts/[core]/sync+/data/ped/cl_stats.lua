-- SYNC+ | ped stats | Xx_Yubari_xX
--  provides client side sync for ped stats

LoadScript("data/utility/shared/keys.lua")
LoadScript("data/utility/shared/stats.lua")

local server_stats = GetConfigBoolean(GetScriptConfig(),"server_stats",false)

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local update = server_stats or not IsSyncEntityOwned(sped)
		for s,k in pairs(KEY_STATS) do
			if update or WasSyncEntityUpdated(sped,k) then
				local v = sped[k]
				if GameGetPedStat(ped,s) ~= v then
					if v == 65535 then
						PedOverrideStat(ped,s,-1)
					else
						GameSetPedStat(ped,s,v)
					end
				end
			end
		end
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	if not server_stats then
		local ped = PedFromSyncPed(sped)
		if PedIsValid(ped) then
			for s,k in pairs(KEY_STATS) do
				local v = GameGetPedStat(ped,s)
				local range = gStatRange[s]
				local list = gStatWhitelist[s]
				if range then
					if v < range[1] then
						v = range[1] -- limit to range
					elseif v > range[2] then
						v = range[2]
					end
				elseif list and not list[s] then
					v = nil -- don't send, not in whitelist
				end
				if v and sped[k] ~= v then
					sped[k] = v -- update if needed
				end
			end
		end
	end
end)
