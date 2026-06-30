RegisterLocalEventHandler("sync:SuppressPed",function(ped)
	if PedIsModel(ped,233) then
		local x1,y1,z1 = -725.44,377.46,293.91
		local x2,y2,z2 = PedGetPosXYZ(ped)
		local dx,dy,dz = x2-x1,y2-y1,z2-z1
		if dx*dx+dy*dy+dz*dz < 10 then
			return true -- don't suppress punchbags in the prep's gym
		end
	end
end)
