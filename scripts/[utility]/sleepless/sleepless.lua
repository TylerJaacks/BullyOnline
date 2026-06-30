CreateThread(function()
	while true do
		if PlayerGetPhysicalState() ~= 0 then
			PlayerChangePhysicalState(0)
		end
		Wait(0)
	end
end)
RegisterLocalEventHandler("PlayerSleepCheck",function()
	return true
end)
RegisterLocalEventHandler("ScriptShutdown",function(s)
	if s == GetCurrentScript() then
		local h = ClockGet()
		if h >= 2 or h < 8 then
			ClockSet(8)
		end
	end
end)
