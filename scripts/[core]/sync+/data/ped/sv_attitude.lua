-- SYNC+ | ped attitudes | Xx_Yubari_xX
--  provides server side sync for ped attitudes

LoadScript("data/utility/shared/keys.lua")

local st = GetScriptSharedTable()
local attitude = {} -- defaults

-- defaults:
function F_RestoreDefaults()
	for faction in pairs(KEY_ATTITUDES) do
		local values = {}
		local defaults = st.attitude[faction]
		for towards in pairs(KEY_ATTITUDES) do
			values[towards] = 0 -- default for each tracked
		end
		if defaults then
			for towards,value in pairs(defaults) do
				if values[towards] then -- if tracked, override default
					values[towards] = value
				end
			end
		end
		attitude[faction] = values
	end
end
F_RestoreDefaults()

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	for f,k in pairs(KEY_ATTITUDES) do
		if k == key then
			return type(value) ~= "number" or math.floor(value) ~= value or not (value >= 0 and value <= 4)
		end
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	F_InitAttitude(ped,GetSyncEntityModel(ped))
end)
RegisterLocalEventHandler("sync:SwapModel",function(ped,model)
	if IsSyncPedValid(ped) then
		F_InitAttitude(ped,model)
	end
end)

-- initialize:
function F_InitAttitude(ped,model)
	local values = attitude[st.factions[model]]
	for towards,key in pairs(KEY_ATTITUDES) do
		ped[key] = values[towards] -- set all type to type defaults
	end
end
for ped in AllSyncPeds() do
	F_InitAttitude(ped,GetSyncEntityModel(ped))
end

-- api:
RegisterFunction("PedGetPedToTypeAttitude",function(ped,faction)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif not attitudes[faction] then
		argerror(2,"unsupported faction")
	end
	return ped[KEY_ATTITUDES[faction]] or 0
end)
RegisterFunction("PedSetPedToTypeAttitude",function(ped,faction,value)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif not attitudes[faction] then
		argerror(2,"unsupported faction")
	elseif type(value) ~= "number" or not (value >= 0 and value <= 4) then
		argerror(3,"invalid attitude")
	end
	ped[KEY_ATTITUDES[faction]] = math.floor(value)
end)
RegisterFunction("PedResetAttitudes",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	F_InitAttitude(ped)
end)
RegisterFunction("PedGetTypeToTypeAttitude",function(faction,towards)
	if not attitudes[faction] then
		argerror(1,"unsupported faction")
	elseif not attitudes[towards] then
		argerror(2,"unsupported faction")
	end
	return attitudes[faction][towards]
end)
RegisterFunction("PedSetTypeToTypeAttitude",function(faction,towards,value)
	if not attitudes[faction] then
		argerror(1,"unsupported faction")
	elseif not attitudes[towards] then
		argerror(2,"unsupported faction")
	elseif type(value) ~= "number" or not (value >= 0 and value <= 4) then
		argerror(3,"invalid attitude")
	end
	attitude[faction][towards] = value
end)
RegisterFunction("PedResetTypeAttitudesToDefault",F_RestoreDefaults)
