BAN_ROLE = GetConfigString(GetScriptConfig(),"ban_role","banned")
MAX_REPORT_PER_PLAYER = 3 -- only store the latest reports from a certain username
MAX_REPORT_REASON = 100
MAX_REPORT_TOTAL = 200

gScript = GetCurrentScript()

gPlayers = {} -- table contains all valid players, true for moderator and false for non-moderator
gOnline = {} -- moderators who have initialized their script (meant for player tracking)

gMuted = {} -- muted chat players [player] = {timer,duration}
gBans = {} -- [ip] = true

gReportCount = 0
gReports = {}

gPreBans = {}

-- export functions
function exports.FileReport(from,about,reason)
	if type(from) ~= "string" or type(about) ~= "string" or type(reason) ~= "string" then
		error("invalid arguments",2)
	end
	CallFunctionFromScript(gScript,F_FileReport,from,about,reason)
end

-- player tracking
RegisterLocalEventHandler("PlayerDropped",function(player)
	gOnline[player] = nil
	if gPlayers[player] ~= nil then
		local id = GetPlayerId(player)
		for player in pairs(gOnline) do
			SendNetworkEvent(player,"moderator_tools:SetPlayer",id)
		end
		gPlayers[player] = nil
	end
	gMuted[player] = nil
end)
RegisterLocalEventHandler("PlayerConnected",function(player)
	if IsPlayerValid(player,false) then
		local id,name = GetPlayerId(player),GetPlayerName(player)
		for player in pairs(gOnline) do
			SendNetworkEvent(player,"moderator_tools:SetPlayer",id,name)
		end
		F_UpdatePlayerModerator(player)
	end
end)
RegisterLocalEventHandler("PlayerConnecting",function(player)
	local ip = GetPlayerIp(player)
	local user = string.lower(GetPlayerName(player))
	if gPreBans[user] and IsPlayerSignedIn(player) then
		GivePlayerAccountRole(player,BAN_ROLE)
		gBans[ip] = true
		F_SaveBanList()
		gPreBans[user] = nil
	end
	if gBans[ip] or DoesPlayerHaveRole(player,BAN_ROLE) then
		KickPlayer(player,"You are banned.")
	end
end)

-- chat event
RegisterLocalEventHandler("chat:SendMessage",function(player,message)
	local mute = gMuted[player]
	if mute then
		if GetAccurateTimer() - mute[1] < mute[2] then
			return true
		end
		gMuted[player] = nil
	end
end)

-- general network events
RegisterNetworkEventHandler("moderator_tools:RequestPermission",function(player)
	if gPlayers[player] then
		local players = {}
		for player in pairs(gPlayers) do
			players[GetPlayerId(player)] = GetPlayerName(player)
		end
		if next(players) then
			SendNetworkEvent(player,"moderator_tools:SetPlayers",players)
		end
		SendNetworkEvent(player,"moderator_tools:InitReports",gReports)
		SendNetworkEvent(player,"moderator_tools:GivePermission")
		gOnline[player] = true
	end
end)
RegisterNetworkEventHandler("moderator_tools:ReportPlayer",function(player,about,reason)
	if IsPlayerSignedIn(player) and type(about) == "string" and type(reason) == "string" and not string.find(reason,"[^%p%w ]") and string.len(about) <= 24 then
		F_FileReport(GetPlayerName(player),about,reason)
	end
end)
RegisterNetworkEventHandler("moderator_tools:DismissReport",function(player,from,about,index)
	if gPlayers[player] and type(from) == "string" and type(about) == "string" and type(index) == "number" then
		local reports = gReports[from]
		if reports then
			local report = reports[index]
			if report and report[1] == about then
				for player in pairs(gOnline) do
					SendNetworkEvent(player,"moderator_tools:RemoveReport",from,index)
				end
				table.remove(reports,index)
				if not reports[1] then
					gReports[from] = nil
				end
				F_SaveReportList()
			end
		end
	end
end)

-- moderator network events
RegisterNetworkEventHandler("moderator_tools:WarnPlayer",function(player,id,text)
	if gPlayers[player] and type(text) == "string" then
		local target = F_GetPlayerById(id)
		if target then
			SendNetworkEvent(target,"moderator_tools:DisplayWarning",text)
			F_LogAction(player,"warned "..GetPlayerName(target),text)
		else
			SendNetworkEvent(player,"moderator_tools:CommandResponse")
		end
	end
end)
RegisterNetworkEventHandler("moderator_tools:MutePlayer",function(player,id,minutes)
	if gPlayers[player] and (minutes == nil or type(minutes) == "number") then
		local target = F_GetPlayerById(id)
		if not target or F_ShouldProtectPlayer(target) then
			SendNetworkEvent(player,"moderator_tools:CommandResponse")
		elseif minutes then
			SendNetworkEvent(target,"moderator_tools:NotifyMuted",minutes)
			F_LogAction(player,"muted "..GetPlayerName(target).." for "..minutes.." minute(s)")
			gMuted[target] = {GetAccurateTimer(),minutes*60000}
		elseif gMuted[target] then
			SendNetworkEvent(target,"moderator_tools:NotifyMuted")
			F_LogAction(player,"unmuted "..GetPlayerName(target))
			gMuted[target] = nil
		else
			SendNetworkEvent(player,"moderator_tools:CommandResponse",GetPlayerName(target).." was not muted")
		end
	end
end)
RegisterNetworkEventHandler("moderator_tools:KickPlayer",function(player,id,reason)
	if gPlayers[player] and type(reason) == "string" then
		local target = F_GetPlayerById(id)
		if target and not F_ShouldProtectPlayer(target) then
			F_LogAction(player,"kicked "..GetPlayerName(target),reason)
			KickPlayer(target,reason)
		else
			SendNetworkEvent(player,"moderator_tools:CommandResponse")
		end
	end
end)
RegisterNetworkEventHandler("moderator_tools:BanAccount",function(player,id)
	if gPlayers[player] then
		local target = F_GetPlayerById(id)
		if not target or F_ShouldProtectPlayer(target) then
			SendNetworkEvent(player,"moderator_tools:CommandResponse")
		elseif IsPlayerSignedIn(target) then
			local run,status = RunCommand("account promote "..GetPlayerName(target).." "..BAN_ROLE)
			if not run or not status then
				error("failed to ban")
			end
			F_LogAction(player,"banned "..GetPlayerName(target).." (by account)")
			KickPlayer(target,"You have been banned.")
		else
			F_LogAction(player,"kicked "..GetPlayerName(target).." (but wanted to ban)")
			KickPlayer(target,"You have been kicked.")
		end
	end
end)
RegisterNetworkEventHandler("moderator_tools:BanIpByString",function(player,ip)
	if gPlayers[player] and type(ip) == "string" and string.find(ip,"^%d+.%d+.%d+.%d+$") then
		for player in AllPlayers() do
			if GetPlayerIp(player) == ip and F_ShouldProtectPlayer(player) then
				return
			end
		end
		gBans[ip] = true
		F_LogAction(player,"banned ip",ip)
		for player in AllPlayers() do
			if GetPlayerIp(player) == ip then
				KickPlayer(player,"You have been banned.")
			end
		end
		F_SaveBanList()
	end
end)
RegisterNetworkEventHandler("moderator_tools:BanIpByPlayer",function(player,id)
	if gPlayers[player] then
		local target = F_GetPlayerById(id)
		if target and not F_ShouldProtectPlayer(target) then
			local ip = GetPlayerIp(target)
			gBans[ip] = true
			F_LogAction(player,"banned "..GetPlayerName(target).." (by ip)",ip)
			KickPlayer(target,"You have been banned.")
			F_SaveBanList()
		else
			SendNetworkEvent(player,"moderator_tools:CommandResponse")
		end
	end
end)
RegisterNetworkEventHandler("moderator_tools:PreBan",function(player,user)
	if gPlayers[player] and type(user) == "string" then
		gPreBans[string.lower(user)] = true
		F_LogAction(player,"pre-banned "..user)
	end
end)

-- file report
function F_FileReport(from,about,reason)
	local reports = gReports[from]
	if string.len(reason) > MAX_REPORT_REASON then
		reason = string.sub(reason,1,MAX_REPORT_REASON-3).."..."
	end
	if gReportCount >= MAX_REPORT_TOTAL then
		local n,r = next(gReports)
		if n then
			for player in pairs(gOnline) do
				SendNetworkEvent(player,"moderator_tools:RemoveReport",n)
			end
			gReportCount = gReportCount - table.getn(r)
			gReports[n] = nil
		end
		reports = gReports[from]
	end
	if reports then
		if table.getn(reports) >= MAX_REPORT_PER_PLAYER then
			for player in pairs(gOnline) do
				SendNetworkEvent(player,"moderator_tools:RemoveReport",from,1)
			end
			table.remove(reports,1)
		end
		table.insert(reports,{about,reason})
	else
		gReports[from] = {{about,reason}}
	end
	for player in pairs(gOnline) do
		SendNetworkEvent(player,"moderator_tools:AddReport",from,about,reason)
	end
	PrintOutput(from.." reported "..about..". reason: "..reason)
	F_SaveReportList()
end

-- utility functions
function F_LogAction(player,text,extra)
	if extra then
		PrintOutput(GetPlayerName(player).." "..text.." ("..tostring(extra)..")")
	else
		PrintOutput(GetPlayerName(player).." "..text)
	end
	SendNetworkEvent(player,"moderator_tools:CommandResponse",text)
end
function F_ShouldProtectPlayer(player)
	return DoesPlayerHaveRole(player,"admin") or F_DoesPlayerHaveModerator(player)
end
function F_DoesPlayerHaveModerator(player)
	for role in AllConfigStrings(GetScriptConfig(),"mod_role") do
		if DoesPlayerHaveRole(player,role) then
			return true
		end
	end
	return false
end
function F_UpdatePlayerModerator(player)
	gPlayers[player] = F_DoesPlayerHaveModerator(player)
end
function F_GetPlayerById(id)
	for player in AllPlayers() do
		if GetPlayerId(player) == id then
			return player
		end
	end
end
function F_LoadReportList()
	local file,bytes = OpenFile("reports.txt","rb")
	if bytes > 0 then
		for from,about,reason in string.gfind(ReadFile(file,bytes),"(%S+)%s+(%S+)%s+([^\r\n]+)") do
			local reports = gReports[from]
			if reports then
				table.insert(reports,{about,reason})
			else
				gReports[from] = {{about,reason}}
			end
			gReportCount = gReportCount + 1
		end
	end
	CloseFile(file)
end
function F_SaveReportList()
	local file = OpenFile("reports.txt","wb")
	for from,reports in pairs(gReports) do
		for _,v in ipairs(reports) do
			WriteFile(file,from.." "..v[1].." "..v[2].."\r\n")
		end
	end
	CloseFile(file)
end
function F_LoadBanList()
	local file,bytes = OpenFile("bans.txt","rb")
	if bytes > 0 then
		for ip in string.gfind(ReadFile(file,bytes),"(%S+)[^\r\n]*") do
			gBans[ip] = true
		end
	end
	CloseFile(file)
end
function F_SaveBanList()
	local sorted = {}
	local file = OpenFile("bans.txt","wb")
	for ip in pairs(gBans) do
		table.insert(sorted,ip)
	end
	table.sort(sorted)
	for _,ip in ipairs(sorted) do
		WriteFile(file,ip.."\r\n")
	end
	CloseFile(file)
end

-- existing players
for player in AllPlayers() do
	F_UpdatePlayerModerator(player)
end

-- lift / reset bans
SetCommand("clear_bans",function(trap)
	if trap then
		PrintError("unexpected argument")
	else
		gBans = {}
		F_SaveBanList()
		PrintOutput("cleared all ip bans")
	end
end)
SetCommand("clear_ban",function(ip)
	if not ip then
		PrintError("expected ip")
	elseif not gBans[ip] then
		PrintError("ip not in ban list")
	else
		gBans[ip] = nil
		F_SaveBanList()
		PrintOutput("cleared ip ban")
	end
end)

-- load bans
F_LoadReportList()
F_LoadBanList()
