-- SYNC+ | ped target | Xx_Yubari_xX
--  provides server side target ped sync

LoadScript("data/utility/shared/keys.lua")

local st = GetScriptSharedTable()
local keys = {KEY_TARGET,KEY_TARGET_GRAPPLE,KEY_TARGET_VEHICLE}

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	for _,k in ipairs(keys) do
		if k == key then
			return not st.finite(value)
		end
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	local id = GetSyncEntityId(ped)
	for other in AllSyncPeds() do
		for _,key in ipairs(keys) do
			if other[key] == id then
				other[key] = -1 -- clear targets set to this new ped's id
			end
		end
	end
	for _,key in ipairs(keys) do
		ped[key] = -1
	end
end)

-- initialize:
for ped in AllSyncPeds() do
	ped[KEY_TARGET] = -1
end

-- api:
RegisterFunction("PedGetTargetPed",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif ped[KEY_TARGET] ~= -1 then
		local target = GetSyncEntityFromId(ped[KEY_TARGET])
		if IsSyncPedValid(target) then
			return target
		end
	end
end)
RegisterFunction("PedLockTarget",function(ped,target) -- only useful when owned by the server
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif IsSyncPedValid(target) then
		ped[KEY_TARGET] = GetSyncEntityId(target)
	elseif target == nil or target == -1 then -- also allows -1 for parity with client function
		ped[KEY_TARGET] = -1
	else
		typerror(2,"ped")
	end
end)
