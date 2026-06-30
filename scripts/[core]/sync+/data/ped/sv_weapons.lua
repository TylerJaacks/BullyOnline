-- SYNC+ | ped weapons | Xx_Yubari_xX
--  provides server side sync for ped weapons

LoadScript("data/utility/shared/keys.lua")
LoadScript("data/utility/shared/weapons.lua")

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_AMMO then
		return type(value) ~= "number" or math.floor(value) ~= value or not (value >= 0)
	elseif key == KEY_WEAPON then
		return value ~= -1 and not gSafeWeapons[value]
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	F_InitWeapon(ped)
end)

-- initialize:
function F_InitWeapon(ped)
	ped[KEY_WEAPON] = -1
	ped[KEY_AMMO] = 0
end
for ped in AllSyncPeds() do
	F_InitWeapon(ped)
end

-- api:
RegisterFunction("PedClearAllWeapons",function(ped)
	if IsSyncPedValid(ped) then
		local player = GetSyncPlayerFromPed(ped)
		if player then
			SendNetworkEvent(player,"sync+:ClearWeapons")
		end
		ped[KEY_WEAPON] = -1
		ped[KEY_AMMO] = 0
	end
	typerror(1,"ped")
end)
RegisterFunction("PedGetAmmoCount",function(ped,weapon)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(weapon) ~= "number" then
		typerror(2,"number")
	elseif weapon ~= -1 and ped[KEY_WEAPON] == weapon then
		return ped[KEY_AMMO]
	end
	return 0
end)
RegisterFunction("PedGetWeapon",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_WEAPON]
end)
RegisterFunction("PedSetWeapon",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
end)
