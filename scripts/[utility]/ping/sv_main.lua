RegisterNetworkEventHandler("ping:ping",function(player)
	SendNetworkEvent(player,"ping:pong")
end)
