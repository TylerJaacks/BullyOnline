-- SYNC+ | ped flags | Xx_Yubari_xX
--  provides client side sync for *some* ped flags

LoadScript("data/utility/shared/keys.lua")
LoadScript("data/utility/shared/flags.lua")

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) and (WasSyncEntityUpdated(sped,KEY_FLAGS) or not IsSyncEntityOwned(sped)) then
		local bits = sped[KEY_FLAGS]
		for i,f in ipairs(gFlagOrder) do
			PedSetFlag(ped,f,bits[i-1])
		end
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local bits = sped[KEY_FLAGS]
		local copy = CreateBitfield(bits)
		for i,f in ipairs(gFlagOrder) do
			local v = PedGetFlag(ped,f)
			if v ~= bits[i-1] then
				copy[i-1] = v
			end
		end
		if copy ~= bits then
			sped[KEY_FLAGS] = copy
		end
	end
end)
