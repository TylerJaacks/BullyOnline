-- JUST THE SKATEBOARD FOR NOW BECAUSE WE'RE IN A RUSH

gWaiting = true
gWeapons = {}
gLimits = {
	[437] = 1,
}

RegisterNetworkEventHandler("weapon_items:ClearWeapons",function()
	gWaiting = false
	gWeapons = {}
end)
RegisterNetworkEventHandler("weapon_items:UpdateWeapons",function(updates)
	for weapon,ammo in pairs(updates) do
		gWeapons[weapon] = ammo
	end
end)

function main()
	PedClearAllWeapons(gPlayer)
	SendNetworkEvent("weapon_items:StartScript")
	while gWaiting do
		if PedGetWeapon(gPlayer) ~= -1 then
			PedClearAllWeapons(gPlayer)
			PedSetWeapon(gPlayer,-1)
		end
		Wait(0)
	end
	while true do
		for weapon,ammo in pairs(gWeapons) do
			local limit = gLimits[weapon]
			local current = PedGetAmmoCount(gPlayer,weapon)
			local difference = ammo - current
			if limit and ammo > limit then
				difference = math.min(ammo,limit) - current
			end
			if difference ~= 0 and RunLocalEvent("weapon_items:AdjustAmmo",weapon) then
				GiveAmmoToPlayer(weapon,difference,false)
			end
		end
		if gWeapons[PedGetWeapon(gPlayer)] == 0 and RunLocalEvent("weapon_items:ResetWeapon") then
			PedSetWeapon(gPlayer,-1)
		end
		Wait(0)
	end
end
