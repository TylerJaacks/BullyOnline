function CB_ServerCommand(arg)
	if arg then
		SendNetworkEvent("svcmd:RunCommand",arg)
	end
end
RegisterNetworkEventHandler("svcmd:RunOutput",function(output)
	CallFunctionFromScript(nil,function()
		for _,v in ipairs(output) do
			if v[2] == "output" then
				PrintOutput(v[1])
			elseif v[2] == "error" then
				PrintError(v[1])
			elseif v[2] == "warning" then
				PrintWarning(v[1])
			else
				PrintSpecial(v[1])
			end
		end
	end)
end)
RegisterNetworkEventHandler("svcmd:SetAdmin",function(admin)
	if admin then
		SetCommand("server",CB_ServerCommand,true)
	else
		ClearCommand("server")
	end
end)
SendNetworkEvent("svcmd:AskAdmin")
