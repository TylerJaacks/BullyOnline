function CB_Shutdown()
	SendNetworkEvent("autorestart:Shutdown")
end
function CB_Restart()
	SendNetworkEvent("autorestart:Restart")
end
RegisterNetworkEventHandler("autorestart:Commands",function()
	SetCommand("schedule_shutdown",CB_Shutdown,false,"Usage: schedule_shutdown\nStart the server shutdown countdown.")
	SetCommand("schedule_restart",CB_Restart,false,"Usage: schedule_restart\nStart the server restart countdown.")
end)
SendNetworkEvent("autorestart:Request")
