local gDistance

SetCommand("pos",function()
	local area = AreaGetVisible()
	local vehicle = VehicleFromDriver(gPlayer)
	if dsl.freecam and dsl.freecam.IsActive() then
		local x1,y1,z1 = dsl.freecam.GetPosition()
		local x2,y2,z2 = dsl.freecam.GetPosition(0,10,0)
		SetClipboard(string.format("%.2f, %.2f, %.2f, %.2f, %.2f, %.2f",x1,y1,z1,x2,y2,z2))
		PrintOutput(string.format("Freecam Position: %.2f, %.2f, %.2f | Target: %.2f, %.2f, %.2f | Area: %d (%s)",x1,y1,z1,x2,y2,z2,area,GetAreaName(area)))
	elseif VehicleIsValid(vehicle) then
		local x,y,z = VehicleGetPosXYZ(vehicle)
		local p,r,h = VehicleGetRotation(vehicle)
		p,r,h = math.deg(p),math.deg(r),math.deg(h)
		SetClipboard(string.format("%.2f, %.2f, %.2f, %.1f",x,y,z,h))
		PrintOutput(string.format("Vehicle XYZ(PRH): %.2f, %.2f, %.2f (%.1f, %.1f, %.1f) | Area: %d (%s)",x,y,z,p,r,h,area,GetAreaName(area)))
	else
		local x,y,z = PlayerGetPosXYZ()
		local h = math.deg(PedGetHeading(gPlayer))
		SetClipboard(string.format("%.2f, %.2f, %.2f, %.1f",x,y,z,h))
		PrintOutput(string.format("Player XYZ(H): %.2f, %.2f, %.2f (%.1f) | Area: %d (%s)",x,y,z,h,area,GetAreaName(area)))
	end
end,false,"Usage: pos\nGet your current position and copy it to your clipboard.")
SetCommand("dist",function()
	if gDistance then
		TerminateThread(gDistance)
		gDistance = nil
	else
		gDistance = CreateThread("T_Distance")
	end
end,false,"Usage: dist\nTrack distance from a starting position.")

function T_Distance()
	local distance = 0
	local x1,y1,z1 = PlayerGetPosXYZ()
	while true do
		local x2,y2,z2 = PlayerGetPosXYZ()
		local dx,dy,dz = x2-x1,y2-y1,z2-z1
		local dist = math.sqrt(dx*dx+dy*dy+dz*dz)
		if dist > distance then
			distance = dist
		end
		SetTextFont("Arial")
		SetTextBlack()
		SetTextColor(255,255,255,255)
		SetTextShadow()
		SetTextAlign("C","B")
		SetTextPosition(0.5,0.98)
		DrawText("position: %.1f, %.1f, %.1f\ncurrent: %.1f, %.1f, %.1f\ndistance: %.2f (max: %.2f)",x1,y1,z1,x2,y2,z2,dist,distance)
		Wait(0)
	end
end
