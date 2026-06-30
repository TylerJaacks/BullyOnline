RegisterNetworkEventHandler("freecam:AskAdmin",function(player)
	if DoesPlayerHaveRole(player,"admin") then
		SendNetworkEvent(player,"freecam:SetAdmin")
	end
end)
