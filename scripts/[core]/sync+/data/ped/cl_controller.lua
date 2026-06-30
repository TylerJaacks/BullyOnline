-- SYNC+ | ped throttle | Xx_Yubari_xX
--  provides client side throttle sync, which determines how much a ped moves during free locomotion

LoadScript("data/utility/shared/keys.lua")

local dx,dy

-- apply:
RegisterLocalEventHandler("PedUpdateActionController",function(ped,index)
	if index == 0 then
		local sped = PedGetSyncPed(ped)
		if sped and not IsSyncEntityOwned(sped) then
			local throttle = sped[KEY_THROTTLE]
			local direction = sped[KEY_DIRECTION]
			local anchor = sped[KEY_ANCHOR]
			if throttle then
				PedSetThrottle(ped,throttle)
			end
			if direction then
				PedSetDirection(ped,unpack(direction))
			end
			if anchor then
				local ax,ay,az,ah = unpack(anchor)
				PedSetAnchorMatrix(ped,Rz(ah))
				PedSetAnchor(ped,ax,ay,az)
			end
		end
		if ped == gPlayer then
			dx,dy = PedGetDirection(ped)
		end
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	local throttle = 0
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) and not PedIsInAnyVehicle(ped) then
		local ax,ay,az = PedGetAnchor(ped)
		local ap,ar,ah = GetMatrixRotation(PedGetAnchorMatrix(ped))
		if GetAreaFromPosition(ax,ay,az) then
			F_UpdateArray(sped,KEY_ANCHOR,ax,ay,az,ah)
		end
		if dx and dx*dx + dy*dy < 4 then
			F_UpdateArray(sped,KEY_DIRECTION,dx,dy)
		end
		throttle = PedGetThrottle(ped)
	end
	if sped[KEY_THROTTLE] ~= throttle then
		sped[KEY_THROTTLE] = throttle -- only assign to the entity if the value is different, to save bandwidth
	end
end)

-- utility:
function F_UpdateArray(sped,key,...)
	local value = sped[key]
	arg.n = nil
	if not value then
		sped[key] = arg
		return
	end
	for i,v in ipairs(value) do
		if v ~= arg[i] then
			sped[key] = arg
			return
		end
	end
end
