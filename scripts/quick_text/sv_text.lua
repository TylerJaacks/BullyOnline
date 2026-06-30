gPrefix = "BULLY ONLINE EARLY ACCESS"
gText = gPrefix
gPlayers = {}

RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterNetworkEventHandler("quick_text:Start",function(player)
	gPlayers[player] = DoesPlayerHaveRole(player,"admin")
	if gText ~= "" then
		SendNetworkEvent(player,"quick_text:Update",gText)
	end
	if gPlayers[player] then
		SendNetworkEvent(player,"quick_text:Permit")
	end
end)
RegisterNetworkEventHandler("quick_text:Update",function(player,text)
	if gPlayers[player] then
		if type(text) == "string" then
			gText = gPrefix..": "..text
		else
			gText = gPrefix
		end
		for player in pairs(gPlayers) do
			SendNetworkEvent(player,"quick_text:Update",gText)
		end
	end
end)
