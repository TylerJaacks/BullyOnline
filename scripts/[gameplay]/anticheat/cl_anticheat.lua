MIN_TIME_STEP = 0.81
STRIKE_AMOUNT = 10
RESET_TIMEOUT = 30000

function main()
	local when
	local cleared = GetAccurateTimer()
	local strikes = 0
	while true do
		if GetPhysicsMult() < MIN_TIME_STEP then
			if not when then
				when = GetAccurateTimer()
			elseif GetAccurateTimer() - when >= 1000 then
				when = GetAccurateTimer()
				cleared = when
				strikes = strikes + 1
				if strikes >= STRIKE_AMOUNT then
					SendNetworkEvent("anticheat:HighFPS")
				end
			end
		elseif when then
			when = nil
		end
		if not when and GetAccurateTimer() - cleared >= RESET_TIMEOUT then
			cleared = GetAccurateTimer()
			strikes = 0
		end
		Wait(0)
	end
end
