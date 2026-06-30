-- SYNC+ | ped target | Xx_Yubari_xX
--  provides client side target ped sync

LoadScript("data/utility/shared/keys.lua")

local locked = setmetatable({},{__mode = "k"})

-- cleanup locked flag:
RegisterLocalEventHandler("sync:SpawnPed",function(sped)
	locked[sped] = nil -- since they won't be locked on anyone when they respawn
end)

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		if not IsSyncEntityOwned(sped) then
			local target = GetSyncEntityFromId(sped[KEY_TARGET])
			if IsSyncPedValid(target) then
				target = PedFromSyncPed(target)
			else
				target = -1
			end
			if PedIsValid(target) then
				if PedGetTargetPed(ped) ~= target then
					PedLockTarget(ped,target,3) -- lock because they have a target
					locked[sped] = true
				end
			elseif PedIsValid(PedGetTargetPed(ped)) then
				PedLockTarget(ped,-1) -- unlock because they have no target
				locked[sped] = nil
			end
			target = GetSyncEntityFromId(sped[KEY_TARGET_VEHICLE])
			if IsSyncVehicleValid(target) then
				target = VehicleFromSyncVehicle(target)
				if not VehicleIsValid(target) then
					target = -1
				end
			else
				target = -1
			end
			PedSetTargetVehicle(ped,target)
		elseif locked[sped] then
			PedLockTarget(ped,-1) -- unlock because we own them
			locked[sped] = nil
		end
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		F_UpdateTargetPed(sped,KEY_TARGET,PedGetTargetPed(ped))
		--F_UpdateTargetPed(sped,KEY_TARGET_GRAPPLE,PedGetGrappleTargetPed(ped))
		F_UpdateTargetVehicle(sped,KEY_TARGET_VEHICLE,PedGetTargetVehicle(ped))
	end
end)

-- utility:
function F_UpdateTargetPed(sped,key,target)
	if PedIsValid(target) then
		target = PedGetSyncPed(target)
	else
		target = nil
	end
	if target then
		local id = GetSyncEntityId(target)
		if sped[key] ~= id then
			sped[key] = id
		end
	elseif sped[key] ~= -1 then
		sped[key] = -1
	end
end
function F_UpdateTargetVehicle(sped,key,target)
	if VehicleIsValid(target) then
		target = VehicleGetSyncVehicle(target)
	else
		target = nil
	end
	if target then
		local id = GetSyncEntityId(target)
		if sped[key] ~= id then
			sped[key] = id
		end
	elseif sped[key] ~= -1 then
		sped[key] = -1
	end
end
