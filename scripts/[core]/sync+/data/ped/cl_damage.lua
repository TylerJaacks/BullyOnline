-- SYNC+ | ped damage | Xx_Yubari_xX
--  provides client side damage multiplier sync

LoadScript("data/utility/shared/keys.lua")

local server_dmg_mult = GetConfigBoolean(GetScriptConfig(),"server_dmg_mult",false)

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local always = server_dmg_mult or not IsSyncEntityOwned(sped)
		if always or WasSyncEntityUpdated(sped,KEY_DAMAGE_GIVEN) then
			for i,v in ipairs(sped[KEY_DAMAGE_GIVEN]) do
				PedSetDamageGivenMultiplier(ped,i-1,v)
			end
		end
		if always or WasSyncEntityUpdated(sped,KEY_DAMAGE_TAKEN) then
			for i,v in ipairs(sped[KEY_DAMAGE_TAKEN]) do
				PedSetDamageTakenMultiplier(ped,i-1,v)
			end
		end
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	if not server_dmg_mult then
		local ped = PedFromSyncPed(sped)
		if PedIsValid(ped) then
			F_UpdateMults(sped,ped,PedGetDamageGivenMultiplier,KEY_DAMAGE_GIVEN)
			F_UpdateMults(sped,ped,PedGetDamageTakenMultiplier,KEY_DAMAGE_TAKEN)
		end
	end
end)
function F_UpdateMults(sped,ped,func,key)
	local copy = {}
	for i in ipairs(sped[key]) do
		copy[i] = func(ped,i-1)
	end
	for i,v in ipairs(sped[key]) do
		if copy[i] ~= v then
			sped[key] = copy -- update the whole table if anything is different
			return
		end
	end
end
