-- SYNC+ | ped stats | Xx_Yubari_xX
--  provides server side sync for ped stats

LoadScript("data/utility/shared/keys.lua")
LoadScript("data/utility/shared/stats.lua")

local st = GetScriptSharedTable()
local peds = setmetatable({},{__mode = "k"})

local server_stats = GetConfigBoolean(GetScriptConfig(),"server_stats",false)

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	for s,k in pairs(KEY_STATS) do
		if k == key then
			if not server_stats then
				local range = gStatRange[s]
				if range and type(value) == "number" and math.floor(value) == value then -- all stats are unsigned short, so they shouldn't have a fractional part
					return not (value >= range[1] and value <= range[2])
				elseif gStatWhitelist[s] then
					return not gStatWhitelist[s][value]
				end
			end
			return true
		end
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	F_InitStats(ped,GetSyncEntityModel(ped))
end)
RegisterLocalEventHandler("sync:SwapModel",function(ped,model)
	if IsSyncPedValid(ped) then
		F_InitStats(ped,model)
	end
end)

-- initialize:
function F_InitStats(ped,model)
	peds[ped] = st.stats[model]
	F_ReinitStats(ped)
end
function F_ReinitStats(ped)
	local stats = st.stats[peds[ped]] or st.stats.STAT_DEFAULT
	for s,k in pairs(KEY_STATS) do
		ped[k] = stats[s]
	end
	return stats
end
for ped in AllSyncPeds() do
	F_InitStats(ped,GetSyncEntityModel(ped))
end

-- api:
RegisterFunction("GameGetPedStat",function(ped,stat)
	if stat ~= 4 then
		stat = KEY_STATS[stat]
	end
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif not stat then
		argerror(2,"unsupported stat")
	elseif stat == 4 then
		return ped[KEY_MAXHP]
	end
	return ped[stat]
end)
RegisterFunction("GameSetPedStat",function(ped,stat,value)
	if stat ~= 4 then
		stat = KEY_STATS[stat]
	end
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif not stat then
		argerror(2,"unsupported stat")
	elseif type(value) ~= "number" then
		typerror(3,"number")
	elseif stat == 4 then
		ped[KEY_MAXHP] = value
		st.F_LimitHealth(ped)
	else
		ped[stat] = value
	end
end)
RegisterFunction("PedGetStatsType",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return peds[ped]
end)
RegisterFunction("PedSetStatsType",function(ped,name)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif not st.stats[name] or type(name) ~= "string" then
		argerror(2,"unsupported type")
	end
	peds[ped] = name
	peds[KEY_MAXHP] = F_ReinitStats(ped)[4]
	peds[KEY_HP] = peds[KEY_MAXHP]
end)
RegisterFunction("PedOverrideStat",GameGetPedStat)
