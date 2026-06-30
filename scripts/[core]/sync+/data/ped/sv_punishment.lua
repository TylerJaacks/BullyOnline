-- SYNC+ | ped punishment | Xx_Yubari_xX
--  provides server side sync for ped punishment points

LoadScript("data/utility/shared/keys.lua")

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_PUNISHMENT then
		return type(value) ~= "number" or not (value >= 0 and value <= 300)
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	ped[KEY_PUNISHMENT] = 0
end)

-- initialize:
for ped in AllSyncPeds() do
	ped[KEY_PUNISHMENT] = 0
end

-- api:
RegisterFunction("PedGetPunishmentPoints",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_PUNISHMENT]
end)
RegisterFunction("PedSetPunishmentPoints",function(ped,points)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(points) ~= "number" then
		typerror(2,"number")
	end
	ped[KEY_PUNISHMENT] = math.max(0,math.min(300,points))
end)
