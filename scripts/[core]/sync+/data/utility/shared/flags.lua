-- SYNC+ | flag configuration | Xx_Yubari_xX
--  this file is used by sv_flags.lua and cl_flags.lua

-- not all ped flags are synced (as that would cause major issues and not make sense)
-- instead, only flags in these tables are synced (maximum of 32)

-- note: may make seperate client-only flags in the future so the server can read them
-- but not trip the client up by ever trying to set them (and override the others)

gFlagDefaults = {
	[2] = false, -- crouching
}

gFlagOrder = {}
for f in pairs(gFlagDefaults) do
	table.insert(gFlagOrder,f)
end
table.sort(gFlagOrder)

gFlagIndex = {}
for i,f in ipairs(gFlagOrder) do
	gFlagIndex[f] = i
end
