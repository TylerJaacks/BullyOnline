gPlayers = {}
gWaiting = true
gRestart = true
gKick = false

function main()
	local started = GetAccurateTimer()
	local timer = GetConfigNumber(GetScriptConfig(),"restart_hours",0)
	if timer <= 0 then
		PrintError("restart_hours must be positive")
		StopCurrentScriptCollection()
		return
	end
	timer = timer * 60 * 60 * 1000
	while gWaiting and GetAccurateTimer() - started < timer do
		Wait(1000)
	end
	if GetConfigBoolean(GetScriptConfig(),"chat_warning",false) then
		F_Chat("Server restarting in 5 minutes!",5 * 60000)
		gKick = true
		F_Chat("Server restarting in 1 minute!",59000)
		F_Chat("Server restarting!",1000)
	end
	QuitServer(gRestart)
end
function F_Chat(str,ms)
	if dsl.chat then
		dsl.chat.Say(str)
	end
	Wait(ms)
end
RegisterLocalEventHandler("PlayerConnecting",function(player)
	if gKick then
		KickPlayer(player,"Server restarting, join back in a couple minutes!")
	end
end)
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterNetworkEventHandler("autorestart:Request",function(player)
	if DoesPlayerHaveRole(player,"admin") then
		SendNetworkEvent(player,"autorestart:Commands")
		gPlayers[player] = true
	else
		gPlayers[player] = nil
	end
end)
RegisterNetworkEventHandler("autorestart:Shutdown",function(player)
	if gPlayers[player] then
		gWaiting = false
		gRestart = false
	end
end)
RegisterNetworkEventHandler("autorestart:Restart",function(player)
	if gPlayers[player] then
		gWaiting = false
		gRestart = true
	end
end)
