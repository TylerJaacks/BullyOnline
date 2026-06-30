-- SYNC+ | ped gravity | Xx_Yubari_xX
--  provides server side sync for ped gravity

LoadScript("data/utility/shared/keys.lua")

local server_gravity = GetConfigBoolean(GetScriptConfig(),"server_gravity",false)

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_GRAVITY then
		return server_gravity or type(value) ~= "boolean"
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	ped[KEY_GRAVITY] = true
end)

-- initialize:
for ped in AllSyncPeds() do
	ped[KEY_GRAVITY] = true
end

-- api:
RegisterFunction("PedGetEffectedByGravity",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_GRAVITY]
end)
RegisterFunction("PedSetEffectedByGravity",function(ped,affected) -- typo is intentional
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(affected) ~= "boolean" then
		typerror(2,"boolean")
	end
	ped[KEY_GRAVITY] = affected
end)
