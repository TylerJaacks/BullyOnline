-- SYNC+ | chapter | Xx_Yubari_xX
--  provides client side time sync

gTime = -1

-- events
RegisterNetworkEventHandler("sync+:SetClock",function(minutes,rate)
	gWhen = GetSyncTimer()
	gTime = minutes
	gRate = rate
end)

-- controller
CreateThread(function()
	SendNetworkEvent("sync+:GetClock")
	while gTime == -1 do
		Wait(0)
	end
	while true do
		local ch,cm = ClockGet()
		local th,tm = F_GetClock()
		if ch ~= th or ch ~= tm then
			ClockSet(th,tm)
		end
		Wait(0)
	end
end)

-- utility
function F_GetClock()
	local minutes = gTime + (GetSyncTimer() - gWhen) * gRate
	if minutes < 0 then
		minutes = 0
	end
	return math.mod(math.floor(minutes/60),24),math.mod(minutes,60)
end
