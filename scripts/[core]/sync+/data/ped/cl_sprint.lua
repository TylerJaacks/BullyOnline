-- SYNC+ | ped sprint | Xx_Yubari_xX
--  provides client side sync for a ped's stamina and infinite sprint setting

LoadScript("data/utility/shared/keys.lua")

local server_inf_sprint = GetConfigBoolean(GetScriptConfig(),"server_inf_sprint",false)

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local unowned = not IsSyncEntityOwned(sped)
		if unowned or WasSyncEntityUpdated(sped,KEY_STAMINA) then
			PedSetStamina(ped,sped[KEY_STAMINA])
		end
		if unowned or server_inf_sprint or WasSyncEntityUpdated(sped,KEY_SPRINT) then
			PedSetInfiniteSprint(ped,sped[KEY_SPRINT])
		end
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local stamina = PedGetStamina(ped)
		if stamina ~= sped[KEY_STAMINA] then
			sped[KEY_STAMINA] = stamina
		end
		if not server_inf_sprint then
			local infinite = PedGetInfiniteSprint(ped)
			if infinite ~= sped[KEY_SPRINT] then
				sped[KEY_SPRINT] = infinite
			end
		end
	end
end)
