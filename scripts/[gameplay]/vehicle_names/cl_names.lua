LoadScript("names.lua")

FADE_IN_TIME_MS = 1000
FADE_HOLD_TIME_MS = 3500
FADE_OUT_TIME_MS = 1000

TEXT_DISTANCE = 0.08
TEXT_SCALE = 2.1

function main()
	local thread
	local current
	while true do
		local vehicle = VehicleFromDriver(gPlayer)
		if vehicle ~= current then
			if VehicleIsValid(vehicle) then
				local name = gVehicleNames[VehicleGetModelId(vehicle)]
				if dsl.propcars then
					local pname = dsl.propcars.GetName(vehicle)
					if pname then
						name = gVehicleNames[pname]
					end
				end
				if name then
					if thread then
						TerminateThread(thread)
					end
					thread = CreateAdvancedThread("PRE_FADE","T_Display",name)
				end
			end
			current = vehicle
		end
		Wait(0)
	end
end
function T_Display(name)
	local started = GetAccurateTimer()
	while true do
		local alpha = 255
		local passed = GetAccurateTimer() - started
		if passed < FADE_IN_TIME_MS then
			alpha = (passed / FADE_IN_TIME_MS) * 255
		elseif passed >= FADE_IN_TIME_MS + FADE_HOLD_TIME_MS then
			if passed >= FADE_IN_TIME_MS + FADE_HOLD_TIME_MS + FADE_OUT_TIME_MS then
				return
			end
			alpha = (1 - (passed - (FADE_IN_TIME_MS + FADE_HOLD_TIME_MS)) / FADE_OUT_TIME_MS) * 255
		end
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(230,230,230,alpha)
		SetTextOutline()
		SetTextAlign("R","B")
		SetTextPosition(1-TEXT_DISTANCE/GetDisplayAspectRatio(),1-TEXT_DISTANCE)
		SetTextScale(TEXT_SCALE)
		DrawText(name)
		Wait(0)
	end
end
