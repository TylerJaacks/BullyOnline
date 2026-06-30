-- SYNC+ | ped attitudes | Xx_Yubari_xX
--  provides client side sync for ped attitudes

LoadScript("data/utility/shared/keys.lua")

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local update = not IsSyncEntityOwned(sped)
		for faction,key in pairs(KEY_ATTITUDES) do
			if update or WasSyncEntityUpdated(sped,key) then
				local value = sped[key]
				if PedGetPedToTypeAttitude(ped,faction) ~= value then
					PedSetPedToTypeAttitude(ped,faction,value)
				end
			end
		end
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		for faction,key in pairs(KEY_ATTITUDES) do
			local value = PedGetPedToTypeAttitude(ped,faction)
			if sped[key] ~= value then
				sped[key] = value
			end
		end
	end
end)
