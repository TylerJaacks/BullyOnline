-- SYNC+ | chapter | Xx_Yubari_xX
--  provides client side weather sync

gNow = -1

gTransition = GetConfigNumber(GetScriptConfig(),"weather_trans_ms",1800) / 60

-- events
RegisterNetworkEventHandler("sync+:SetWeather",function(ms,a,b)
	gTimer = GetSyncTimer()
	if ms then
		gNow = a
		gNext = b
		gPassed = ms
	else
		gNow = 0
		gNext = 0
		gPassed = 0
	end
end)

-- controller
CreateThread(function()
	SendNetworkEvent("sync+:GetWeather")
	while gNow == -1 do
		Wait(0)
	end
	while true do
		local transition = ((gPassed + (GetSyncTimer() - gTimer)) / 1000) / gTransition
		if transition < 0 then
			transition = 0
		elseif transition > 1 then
			transition = 1
		end
		WeatherSet(0) -- also locks the weather before we set the transition data
		WeatherTransition(gNow,gNext,transition)
		Wait(0)
	end
end)
