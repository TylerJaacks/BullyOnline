gPlayers = {}

RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterNetworkEventHandler("svcmd:AskAdmin",function(player)
	local admin = DoesPlayerHaveRole(player,"superadmin") or GetPlayerIp(player) == "127.0.0.1"
	SendNetworkEvent(player,"svcmd:SetAdmin",admin)
	gPlayers[player] = admin
end)
RegisterNetworkEventHandler("svcmd:RunCommand",function(player,arg)
	if gPlayers[player] and type(arg) == "string" then
		local output = {}
		PrintOutput(GetPlayerName(player)..": /server "..arg)
		local handler = RegisterLocalEventHandler("ConsolePrinted",function(message,mtype)
			table.insert(output,{message,mtype})
		end)
		if not RunCommand(arg) then
			table.insert(output,{"unknown server command","error"})
		end
		RemoveEventHandler(handler)
		SendNetworkEvent(player,"svcmd:RunOutput",output)
	end
end)
