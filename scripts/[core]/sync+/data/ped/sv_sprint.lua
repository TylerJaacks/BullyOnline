-- SYNC+ | ped sprint | Xx_Yubari_xX
--  provides server side sync for a ped's stamina and infinite sprint setting

LoadScript("data/utility/shared/keys.lua")

local st = GetScriptSharedTable()

local server_inf_sprint = GetConfigBoolean(GetScriptConfig(),"server_inf_sprint",false)
local inf_player_sprint = GetConfigBoolean(GetScriptConfig(),"inf_player_sprint",false)

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_STAMINA then
		return not st.finite(value) or not (value >= 0)
	elseif key == KEY_SPRINT then
		return server_inf_sprint or type(value) ~= "boolean"
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	F_InitPed(ped)
end)

-- initialize:
function F_InitPed(ped)
	ped[KEY_STAMINA] = 60
	if inf_player_sprint and GetSyncPlayerFromPed(ped) then
		ped[KEY_SPRINT] = true
	else
		ped[KEY_SPRINT] = false
	end
end
for ped in AllSyncPeds() do
	F_InitPed(ped)
end

-- api:
RegisterFunction("PedGetStamina",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_STAMINA]
end)
RegisterFunction("PedSetStamina",function(ped,stamina)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(stamina) ~= "number" then
		typerror(2,"number")
	end
	ped[KEY_STAMINA] = stamina
end)
RegisterFunction("PedGetInfiniteSprint",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_SPRINT]
end)
RegisterFunction("PedSetInfiniteSprint",function(ped,infinite)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(infinite) ~= "boolean" then
		typerror(2,"boolean")
	end
	ped[KEY_SPRINT] = value
end)
