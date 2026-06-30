RegisterLocalEventHandler("sync:ValidateModel",function(ped,model)
	return true -- no model switches that weren't by the server
end)
RegisterLocalEventHandler("sync:ValidateArea",function(ped,area)
	-- TODO: validate to valid areas
end)
RegisterNetworkEventHandler("anticheat:HighFPS",function(player)
	KickPlayer(player,"Please limit your game to 60 FPS or lower.")
end)
