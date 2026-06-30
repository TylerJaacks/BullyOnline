-- SYNC+ | ped health | Xx_Yubari_xX
--  provides server side health / death sync

LoadScript("data/utility/shared/keys.lua")

local st = GetScriptSharedTable()
local peds = setmetatable({},{__mode = "k"})

local server_max_hp = GetConfigBoolean(GetScriptConfig(),"server_max_hp",false)
local allow_double_hp = GetConfigBoolean(GetScriptConfig(),"allow_double_hp",false)

-- limit health:
function st.F_LimitHealth(ped)
	if allow_double_hp and GetSyncPlayerFromPed(ped) then
		if ped[KEY_HP] > ped[KEY_MAXHP] * 2 then
			ped[KEY_HP] = ped[KEY_MAXHP] * 2
		end
	elseif ped[KEY_HP] > ped[KEY_MAXHP] then
		ped[KEY_HP] = ped[KEY_MAXHP]
	end
end

-- remove dead:
CreateThread(function()
	while true do
		for ped in AllSyncPeds() do
			if ped[KEY_DEAD] and not GetSyncPlayerFromPed(ped) then
				if not peds[ped] then
					peds[ped] = GetAccurateTimer()
				elseif GetAccurateTimer() - peds[ped] >= 70000 then
					-- takes about 60 seconds for peds on the client to fade out so we'll do 70
					DeleteSyncEntity(ped)
				end
			elseif peds[ped] then
				peds[ped] = nil
			end
		end
		Wait(0)
	end
end)

-- events:
RegisterLocalEventHandler("sync:PreUpdatePed",function(ped)
	if ped[KEY_INVULNERABLE] and ped[KEY_DEAD] then
		ped[KEY_DEAD] = false -- this ped wasn't supposed to be killable
	end
	st.F_LimitHealth(ped)
end)
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_MAXHP then
		if server_max_hp or not st.finite(value) or not (value > 0) then
			return true -- max hp must be positive
		end
	elseif key == KEY_HP then
		return not st.finite(value)
	elseif key == KEY_INVULNERABLE then
		return true -- clients can't set this field
	elseif key == KEY_DEAD then
		return type(value) ~= "boolean"
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	F_InitHP(ped)
end)
RegisterLocalEventHandler("sync:SwapModel",function(ped,model)
	if IsSyncPedValid(ped) then
		local stat = st.stats[st.stats[model]]
		if stat then
			ped[KEY_HP] = stat[4] * (ped[KEY_HP] / ped[KEY_MAXHP])
			ped[KEY_MAXHP] = stat[4]
			RunLocalEvent("sync+:SwapModel",ped)
		end
	end
end)

-- initialize:
function F_InitHP(ped)
	local stat = st.stats[st.stats[GetSyncEntityModel(ped)]]
	if stat then
		ped[KEY_MAXHP] = stat[4]
	else
		ped[KEY_MAXHP] = 100
	end
	ped[KEY_HP] = ped[KEY_MAXHP]
	ped[KEY_INVULNERABLE] = false
	ped[KEY_DEAD] = false
end
for ped in AllSyncPeds() do
	F_InitHP(ped)
end

-- api:
RegisterFunction("PedApplyDamage",function(ped,damage)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(damage) ~= "number" then
		typerror(2,"number")
	end
	ped[KEY_HP] = math.max(0,ped[KEY_HP]-damage)
	if ped[KEY_HP] == 0 then
		ped[KEY_DEAD] = true
	end
end)
RegisterFunction("PedGetHealth",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_HP]
end)
RegisterFunction("PedGetMaxHealth",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_MAXHP]
end)
RegisterFunction("PedIsDead",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_DEAD]
end)
RegisterFunction("PedSetDead",function(ped,dead)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(dead) ~= "boolean" then
		typerror(2,"boolean")
	end
	if dead then
		ped[KEY_DEAD] = true
	else
		F_InitHP(ped)
	end
end)
RegisterFunction("PedSetHealth",function(ped,hp)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(hp) ~= "number" then
		typerror(2,"number")
	elseif hp < 0 then
		hp = 0
	end
	if allow_double_hp and GetSyncPlayerFromPed(ped) then
		if hp > ped[KEY_MAXHP] * 2 then
			ped[KEY_MAXHP] = hp / 2
		end
	elseif hp > ped[KEY_MAXHP] then
		ped[KEY_MAXHP] = hp
	end
	ped[KEY_HP] = hp
end)
RegisterFunction("PedSetInvulnerable",function(ped,invulnerable)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(invulnerable) ~= "boolean" then
		typerror(2,"boolean")
	end
	ped[KEY_INVULNERABLE] = invulnerable
end)
RegisterFunction("PedSetMaxHealth",function(ped,hp)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(hp) ~= "number" then
		typerror(2,"number")
	elseif hp < 0 then
		hp = 0
	end
	ped[KEY_MAXHP] = hp
	st.F_LimitHealth(ped)
end)
