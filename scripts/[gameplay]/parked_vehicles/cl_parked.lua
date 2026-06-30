gVehicles = {}

RegisterLocalEventHandler("sync:DeleteVehicle",function(vehicle)
	gVehicles[vehicle] = nil
end)
RegisterNetworkEventHandler("parked_vehicles:ShowPosition",function(vehicle)
	gVehicles[vehicle] = true
end)

function main()
	SendNetworkEvent("parked_vehicles:StartScript")
	while true do
		if next(gVehicles) then
			local count = 0
			for scar in pairs(gVehicles) do
				local vehicle = VehicleFromSyncVehicle(scar)
				if VehicleIsValid(vehicle) then
					local sx,sy = GetScreenCoords(VehicleGetPosXYZ(vehicle))
					if sx then
						local size = 0.02
						local ar = GetDisplayAspectRatio()
						DrawRectangle(sx-(size*0.5)/ar,sy-size*0.5,size/ar,size,255,0,0,255)
					end
				end
				count = count + 1
			end
			SetTextFont("Arial")
			SetTextBlack()
			SetTextColor(255,0,0,255)
			SetTextOutline()
			SetTextAlign("C","B")
			SetTextPosition(0.5,0.9)
			DrawText(count.." parked vehicles spawned")
		end
		Wait(0)
	end
end
