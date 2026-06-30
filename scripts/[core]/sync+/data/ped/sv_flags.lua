-- SYNC+ | ped flags | Xx_Yubari_xX
--  provides server side sync for *some* ped flags

LoadScript("data/utility/shared/keys.lua")
LoadScript("data/utility/shared/flags.lua")

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_FLAGS then
		return type2(value) ~= "bitfield"
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	F_InitPed(ped)
end)

-- initialize:
function F_InitPed(ped)
	local bits = CreateBitfield()
	for i,f in ipairs(gFlagOrder) do
		if gFlagDefaults[f] then
			bits[i-1] = true
		end
	end
	ped[KEY_FLAGS] = bits
end
for ped in AllSyncPeds() do
	F_InitPed(ped)
end

-- api:
RegisterFunction("PedGetFlag",function(ped,flag)
	if IsSyncPedValid(ped) then
		local index = gFlagIndex[flag]
		if not index then
			argerror(2,"unsupported flag")
		end
		return ped[KEY_FLAGS][index-1]
	end
	typerror(1,"ped")
end)
RegisterFunction("PedSetFlag",function(ped,flag,value)
	if IsSyncPedValid(ped) then
		local index = gFlagIndex[flag]
		if not index then
			argerror(2,"unsupported flag")
		elseif type(value) ~= "boolean" then
			if type(value) ~= "number" then
				typerror(3,"boolean")
			end
			value = value ~= 0
		end
		ped[KEY_FLAGS][index-1] = value
		return
	end
	typerror(1,"ped")
end)
