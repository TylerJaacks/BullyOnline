-- SYNC+ | ped gravity | Xx_Yubari_xX
--  provides client side sync for ped gravity

LoadScript("data/utility/shared/keys.lua")

local server_gravity = GetConfigBoolean(GetScriptConfig(),"server_gravity",false)

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) and (server_gravity or WasSyncEntityUpdated(sped,KEY_GRAVITY) or not IsSyncEntityOwned(sped)) and PedGetEffectedByGravity(ped) ~= sped[KEY_GRAVITY] then
		PedSetEffectedByGravity(ped,sped[KEY_GRAVITY])
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	if not server_gravity then
		local ped = PedFromSyncPed(sped)
		if PedIsValid(ped) then
			local affected = PedGetEffectedByGravity(ped)
			if affected ~= sped[KEY_GRAVITY] then
				sped[KEY_GRAVITY] = affected
			end
		end
	end
end)
