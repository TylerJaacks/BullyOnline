gPlaytime = 0

RegisterNetworkEventHandler("playtime_tracker:UpdatePlaytime",function(minutes)
	gPlaytime = math.floor(minutes)
end)
SetCommand("playtime",function(player)
	local hours = math.floor(gPlaytime/60)
	local minutes = math.mod(gPlaytime,60)
	if hours == 0 then
		PrintOutput("server playtime: "..minutes.." m")
	elseif minutes == 0 then
		PrintOutput("server playtime: "..hours.." h")
	else
		PrintOutput("server playtime: "..hours.." h "..minutes.." m")
	end
end,false,"Usage: playtime\nPrint your current playtime in this server.")

SendNetworkEvent("playtime_tracker:RequestPlaytime")
