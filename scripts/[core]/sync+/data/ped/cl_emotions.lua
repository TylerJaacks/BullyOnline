-- SYNC+ | ped emotions | Xx_Yubari_xX
--  provides client side sync for ped emotions

LoadScript("data/utility/shared/keys.lua")

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	if WasSyncEntityUpdated(sped,KEY_EMOTIONS) or not IsSyncEntityOwned(sped) then
		local ped = PedFromSyncPed(sped)
		if PedIsValid(ped) then
			for id,emo in pairs(sped[KEY_EMOTIONS]) do
				local target = GetSyncEntityFromId(id)
				if IsSyncPedValid(target) then
					target = PedFromSyncPed(target)
					if PedIsValid(target) and PedGetEmotionTowardsPed(ped,target) ~= emo then
						PedSetEmotionTowardsPed(ped,target,emo)
					end
				end
			end
		end
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local update = false
		local emotions = sped[KEY_EMOTIONS]
		for starget in AllSyncPeds() do
			local target = PedFromSyncPed(starget)
			if PedIsValid(target) then
				local emo = PedGetEmotionTowardsPed(ped,target)
				local id = GetSyncEntityId(starget)
				if emotions[id] ~= emo then
					emotions[id] = emo
					update = true
				end
			end
		end
		if update then
			sped[KEY_EMOTIONS] = emotions
		end
	end
end)
