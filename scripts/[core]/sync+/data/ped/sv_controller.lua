-- SYNC+ | ped throttle | Xx_Yubari_xX
--  provides server side throttle sync, which determines how much a ped moves during free locomotion

LoadScript("data/utility/shared/keys.lua")

local st = GetScriptSharedTable()

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_THROTTLE then
		return not st.finite(value)
	elseif key == KEY_DIRECTION then
		if st.array_finite(value,2) then
			local x,y = unpack(value)
			return not (x*x + y*y < 4)
		end
		return true
	elseif key == KEY_ANCHOR then
		return not st.array_finite(value,4) or not GetAreaFromPosition(unpack(value))
	end
end)

-- api:
RegisterFunction("PedGetAnchor",function(ped)
	if IsSyncPedValid(ped) then
		local pos = ped[KEY_ANCHOR]
		if pos then
			return unpack(pos)
		end
		return 0,0,0
	end
	typerror(1,"ped")
end)
RegisterFunction("PedSetAnchor",function(ped,x,y,z)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(x) ~= "number" then
		typerror(2,"number")
	elseif type(y) ~= "number" then
		typerror(3,"number")
	elseif type(z) ~= "number" then
		typerror(4,"number")
	end
	ped[KEY_ANCHOR] = {x,y,z}
end)
RegisterFunction("PedGetDirection",function(ped)
	if IsSyncPedValid(ped) then
		local dir = ped[KEY_DIRECTION]
		if dir then
			return unpack(dir)
		end
		return 0,1
	end
	typerror(1,"ped")
end)
RegisterFunction("PedSetDirection",function(ped,x,y)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(x) ~= "number" then
		typerror(2,"number")
	elseif type(y) ~= "number" then
		typerror(3,"number")
	end
	ped[KEY_DIRECTION] = {x,y}
end)
RegisterFunction("PedGetThrottle",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_THROTTLE] or 0
end)
RegisterFunction("PedSetThrottle",function(ped,value)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(value) ~= "number" then
		typerror(2,"number")
	end
	ped[KEY_THROTTLE] = value
end)
