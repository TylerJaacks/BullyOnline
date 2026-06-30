-- SYNC+ | ped weapons | Xx_Yubari_xX
--  provides client side sync for ped weapons

LoadScript("data/utility/shared/keys.lua")
LoadScript("data/utility/shared/weapons.lua")

local updating = setmetatable({},{__mode = "k"}) -- peds that are waiting to set a weapon
local updates = {n = 0} -- used to rate limit weapons set per second

local rate_limit = GetConfigNumber(GetScriptConfig(),"weapon_rate_limit",30)
local rate_timer = GetConfigNumber(GetScriptConfig(),"weapon_rate_timer",2000)

-- events:
RegisterNetworkEventHandler("sync+:ClearWeapons",function()
	PedClearAllWeapons(gPlayer)
end)

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	if updating[sped] or WasSyncEntityUpdated(sped,KEY_WEAPON) or not IsSyncEntityOwned(sped) then
		local ped = PedFromSyncPed(sped)
		if PedIsValid(ped) then
			local weapon = sped[KEY_WEAPON]
			local ammo = sped[KEY_AMMO]
			if PedGetWeapon(ped) ~= weapon or (weapon ~= -1 and PedGetAmmoCount(ped,weapon) ~= ammo) then
				if weapon == -1 then
					PedClearAllWeapons(ped)
					PedSetWeaponNow(ped,-1,0,false)
					table.insert(updates,GetAccurateTimer())
					updating[sped] = nil
				elseif F_CanSetWeapon(ped) and WeaponRequestModel(weapon) then
					PedClearAllWeapons(ped)
					PedSetWeaponNow(ped,weapon,ammo,false)
					table.insert(updates,GetAccurateTimer())
					updating[sped] = nil
				elseif not updating[sped] then
					updating[sped] = true -- try again next update
				end
			end
		elseif updating[sped] then
			updating[sped] = nil -- ped stopped existing so we'll worry about it later
		end
	elseif WasSyncEntityUpdated(sped,KEY_AMMO) then
		local ped = PedFromSyncPed(sped)
		local weapon = sped[KEY_WEAPON]
		if PedIsValid(ped) and PedGetWeapon(ped) == weapon and weapon ~= -1 then
			local ammo = sped[KEY_AMMO]
			if ped == gPlayer then
				local adding = ammo - PedGetAmmoCount(gPlayer,weapon)
				if adding ~= 0 then
					GiveAmmoToPlayer(weapon,adding,false)
				end
			elseif PedGetAmmoCount(ped,weapon) ~= ammo then
				PedSetWeapon(ped,weapon,ammo,false)
				table.insert(updates,GetAccurateTimer())
			end
		end
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local weapon = PedGetWeapon(ped)
		if not gSafeWeapons[weapon] then
			weapon = -1 -- unsafe weapon, use -1
		end
		if weapon ~= -1 then
			local ammo = PedGetAmmoCount(ped,weapon)
			if sped[KEY_AMMO] ~= ammo then
				sped[KEY_AMMO] = ammo
			end
		end
		if sped[KEY_WEAPON] ~= weapon then
			sped[KEY_WEAPON] = weapon
		end
	end
end)

-- exports:
function exports.SetPedWeapon(ped,weapon,ammo)
	if PedGetWeapon(ped) ~= weapon or (weapon ~= -1 and PedGetAmmoCount(ped,weapon) ~= ammo) then
		if weapon == -1 then
			PedClearAllWeapons(ped)
			PedSetWeaponNow(ped,-1,0,false)
			table.insert(updates,GetAccurateTimer())
		elseif gSafeWeapons[weapon] and F_CanSetWeapon(ped) and WeaponRequestModel(weapon) then
			PedClearAllWeapons(ped)
			PedSetWeaponNow(ped,weapon,ammo,false)
			table.insert(updates,GetAccurateTimer())
		end
	end
end

-- utility:
function F_CanSetWeapon(ped)
	local timer = GetAccurateTimer()
	while updates[1] and timer - updates[1] >= rate_timer do
		table.remove(updates,1)
	end
	if updates.n < rate_limit then
		return VehicleIsValid(VehicleFromDriver(ped)) or PedMePlaying(ped,"DEFAULT_KEY",true)
	end
	return false
end
