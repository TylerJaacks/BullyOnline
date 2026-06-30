-- SYNC+ | ped punishment | Xx_Yubari_xX
--  provides client side sync for ped punishment points

LoadScript("data/utility/shared/keys.lua")

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) and (WasSyncEntityUpdated(sped,KEY_PUNISHMENT) or not IsSyncEntityOwned(sped)) then
		PedSetPunishmentPoints(ped,sped[KEY_PUNISHMENT])
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local points = math.max(0,math.min(300,PedGetPunishmentPoints(ped)))
		if points ~= sped[KEY_PUNISHMENT] then
			sped[KEY_PUNISHMENT] = points
		end
	end
end)
