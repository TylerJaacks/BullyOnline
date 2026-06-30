-- SYNC+ | ped damage | Xx_Yubari_xX
--  provides server side damage multiplier sync

LoadScript("data/utility/shared/keys.lua")

local st = GetScriptSharedTable()

local server_dmg_mult = GetConfigBoolean(GetScriptConfig(),"server_dmg_mult",false)

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_DAMAGE_GIVEN or key == KEY_DAMAGE_TAKEN then
		return server_dmg_mult or not st.array_finite(value,4)
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	ped[KEY_DAMAGE_GIVEN] = {1.0,1.0,1.0,1.0}
	ped[KEY_DAMAGE_TAKEN] = {1.0,1.0,1.0,1.0}
end)

-- initialize:
for ped in AllSyncPeds() do
	ped[KEY_DAMAGE_GIVEN] = {1.0,1.0,1.0,1.0}
	ped[KEY_DAMAGE_TAKEN] = {1.0,1.0,1.0,1.0}
end

-- utility:
function F_Set(ped,key,damage,multiplier)
	local mults = ped[key]
	if mults[damage] then
		local copy = {unpack(mults)}
		copy[damage] = multiplier
		ped[key] = copy -- marks the table for update
		return true
	end
	return false
end

-- api:
RegisterFunction("PedGetDamageGivenMultiplier",function(ped,damage)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_DAMAGE_GIVEN][damage+1] or argerror(2,"unsupported damage type")
end)
RegisterFunction("PedGetDamageTakenMultiplier",function(ped,damage)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_DAMAGE_TAKEN][damage+1] or argerror(2,"unsupported damage type")
end)
RegisterFunction("PedSetDamageGivenMultiplier",function(ped,damage,multiplier)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(multiplier) ~= "number" then
		typerror(3,"number")
	elseif not F_Set(ped,KEY_DAMAGE_GIVEN,damage+1,multiplier) then
		argerror(2,"invalid damage type")
	end
end)
RegisterFunction("PedSetDamageTakenMultiplier",function(ped,damage,multiplier)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(multiplier) ~= "number" then
		typerror(3,"number")
	elseif not F_Set(ped,KEY_DAMAGE_TAKEN,damage+1,multiplier) then
		argerror(2,"invalid damage type")
	end
end)
