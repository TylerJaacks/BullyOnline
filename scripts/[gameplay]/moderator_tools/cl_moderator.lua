WARNING_TIME_MS = 12000

gModerator = false
gWarnings = {}

gUpdatePlayers = false
gPlayerCount = 0
gPlayers = {}

gReportThread = false
gReportCount = 0
gReports = {}

-- local events
RegisterLocalEventHandler("f2menu:Open",function(f_add)
	if not gModerator then
		return
	end
	f_add({
		name = "Moderator Tools",
		description = "(moderator only)\nTools for moderation.",
		thread = M_MainMenu,
	})
end)

-- network events
RegisterNetworkEventHandler("moderator_tools:InitReports",function(reports)
	gReportCount = 0
	gReports = reports
	for _,r in pairs(reports) do
		gReportCount = gReportCount + table.getn(r)
	end
end)
RegisterNetworkEventHandler("moderator_tools:AddReport",function(from,about,reason)
	local reports = gReports[from]
	if reports then
		table.insert(reports,{about,reason})
	else
		gReports[from] = {{about,reason}}
	end
	gReportCount = gReportCount + 1
end)
RegisterNetworkEventHandler("moderator_tools:RemoveReport",function(from,index)
	local reports = gReports[from]
	if reports then
		if index then
			local report = reports[index]
			if report then
				gReportCount = gReportCount - 1
				table.remove(reports,index)
			end
			if not reports[1] then
				gReports[from] = nil
			end
		else
			gReportCount = gReportCount - table.getn(reports)
			gReports[from] = nil
		end
	end
end)
RegisterNetworkEventHandler("moderator_tools:DisplayWarning",function(warning)
	if not gWarnings[1] then
		CreateDrawingThread("T_Warnings")
	end
	table.insert(gWarnings,{text = warning})
end)
RegisterNetworkEventHandler("moderator_tools:NotifyMuted",function(minutes)
	if dsl.chat then
		if not minutes then
			dsl.chat.Say("You have been unmuted.")
		elseif minutes == 1 / 0 then
			dsl.chat.Say("You have been muted.")
		else
			local hours = math.floor(minutes / 60)
			if hours >= 1 then
				dsl.chat.Say("You have been muted for "..hours.." h "..math.mod(minutes,60).." m.")
			elseif minutes == 1 then
				dsl.chat.Say("You have been muted for 1 minute.")
			else
				dsl.chat.Say("You have been muted for "..minutes.." minutes.")
			end
		end
	end
end)
RegisterNetworkEventHandler("moderator_tools:CommandResponse",function(text)
	if text then
		PrintOutput(text)
		SoundPlay2D("RightBtn")
	else
		PrintError("invalid player ID")
		SoundPlay2D("WrongBtn")
	end
end)
RegisterNetworkEventHandler("moderator_tools:GivePermission",function()
	if not gReportThread then
		CreateThread("T_Reports")
		gReportThread = true
	end
	SetCommand("players",CB_Players,true,"Usage: players\nList all players with their ID.")
	SetCommand("warn",CB_Warn,true,"Usage: warn <player_id> <text...>\nShow a warning to a player by their ID.")
	SetCommand("mute",CB_Mute,false,"Usage: mute <player_id> [minutes]\nMute a player in the chat by their ID.")
	SetCommand("unmute",CB_Unmute,false,"Usage: unwarn <player_id>\nUnmute a previously muted player by their ID.")
	SetCommand("kick",CB_Kick,true,"Usage: kick <player_id> [text...]\nKick a player by their ID.")
	SetCommand("ban",CB_Ban,false,"Usage: ban <player_id> [days]\nBan a player's account by their current ID.")
	SetCommand("ban_ip",CB_BanIp,false,"Usage: ban_ip <player_id/player_ip>\nBan a player's IP by their current ID or ban an IP address directly.")
	SetCommand("pre_ban",CB_PreBan)
	gModerator = true
end)
RegisterNetworkEventHandler("moderator_tools:SetPlayers",function(players)
	gUpdatePlayers = true
	gPlayers = players
	gPlayerCount = 0
	for _ in pairs(players) do
		gPlayerCount = gPlayerCount + 1
	end
end)
RegisterNetworkEventHandler("moderator_tools:SetPlayer",function(id,name)
	gUpdatePlayers = true
	gPlayers[id] = name
	gPlayerCount = 0
	for _ in pairs(gPlayers) do
		gPlayerCount = gPlayerCount + 1
	end
end)

-- reports
SetCommand("report",function(args)
	if args then
		local valid,after,user = string.find(args,"(%S+)%s*")
		if valid then
			local reason = string.sub(args,after+1)
			if reason == "" then
				CallFunctionFromScript(nil,PrintError,"expected reason for report after username")
			elseif string.find(reason,"[^%p%w ]") then
				CallFunctionFromScript(nil,PrintError,"invalid characters in reason")
			else
				SendNetworkEvent("moderator_tools:ReportPlayer",user,reason)
				CallFunctionFromScript(nil,PrintOutput,"sent report to staff")
			end
			return
		end
	end
	CallFunctionFromScript(nil,PrintError,"expected username")
end,true,"Usage: report <user> <reason...>\nReport a player to staff. Carefully type the player's username first, then the reason for the report.")

-- threads
function T_Reports()
	while true do
		if gReportCount > 0 then
			local gb = 50 + 40 * (0.5 + 0.5 * math.sin((GetTimer()/1000)*math.pi*2))
			SetTextFont("Georgia")
			SetTextBold()
			SetTextColor(255,gb,gb,255)
			SetTextOutline()
			SetTextAlign("C","B")
			SetTextPosition(0.5,0.99)
			SetTextScale(0.8)
			DrawText(gReportCount.." reports awaiting review")
		end
		Wait(0)
	end
end
function T_Warnings()
	while true do
		local w = gWarnings[1]
		if not w.started then
			w.started = GetAccurateTimer()
		end
		if GetAccurateTimer() - w.started >= WARNING_TIME_MS then
			table.remove(gWarnings,1)
			w = gWarnings[1]
			if not w then
				return
			end
			w.started = GetAccurateTimer()
		end
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(255,80,20,255)
		SetTextOutline()
		SetTextAlign("C","B")
		SetTextPosition(0.5,0.2)
		SetTextScale(1.5)
		DrawText("WARNING")
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(255,80,20,255)
		SetTextOutline()
		SetTextAlign("C","T")
		SetTextWrapping(0.7/GetDisplayAspectRatio())
		SetTextPosition(0.5,0.22)
		SetTextScale(1.2)
		DrawText(w.text)
		Wait(0)
	end
end

-- commands
function CB_Players()
	local players = {n = 0}
	for id,name in pairs(gPlayers) do
		table.insert(players,{id,name})
	end
	table.sort(players,function(a,b)
		return a[1] < b[1]
	end)
	PrintOutput("---- players ----")
	CallFunctionFromScript(nil,function()
		if not players[1] then
			PrintOutput("(none)")
		end
		for i = 1,players.n,3 do
			local a = players[i]
			local b = players[i+1]
			local c = players[i+2]
			if c then
				PrintOutput("["..a[1].."] "..a[2].." | ["..b[1].."] "..b[2].." | ["..c[1].."] "..c[2])
			elseif b then
				PrintOutput("["..a[1].."] "..a[2].." | ["..b[1].."] "..b[2])
			else
				PrintOutput("["..a[1].."] "..a[2])
			end
		end
	end)
end
function CB_Warn(args)
	local _,after,id
	if args then
		_,after,id = string.find(args,"(%d+)%s*")
	end
	id = F_PositiveInteger(id)
	if id then
		local reason = string.sub(args,after+1)
		if reason ~= "" then
			SendNetworkEvent("moderator_tools:WarnPlayer",id,reason)
		else
			PrintError("expected warning text")
			SoundPlay2D("WrongBtn")
		end
	else
		PrintError("expected player id")
		SoundPlay2D("WrongBtn")
	end
end
function CB_Mute(id,minutes)
	id = F_PositiveInteger(id)
	if minutes then
		minutes = F_PositiveInteger(minutes)
	else
		minutes = 1 / 0
	end
	if not id then
		PrintError("expected player id")
		SoundPlay2D("WrongBtn")
	elseif not minutes then
		PrintError("invalid mute duration")
		SoundPlay2D("WrongBtn")
	else
		SendNetworkEvent("moderator_tools:MutePlayer",id,minutes)
	end
end
function CB_Unmute(id)
	id = F_PositiveInteger(id)
	if not id then
		PrintError("expected player id")
		SoundPlay2D("WrongBtn")
	else
		SendNetworkEvent("moderator_tools:MutePlayer",id)
	end
end
function CB_Kick(args)
	local _,after,id
	if args then
		_,after,id = string.find(args,"(%d+)%s*")
	end
	id = F_PositiveInteger(id)
	if id then
		local reason = string.sub(args,after+1)
		if reason ~= "" then
			SendNetworkEvent("moderator_tools:KickPlayer",id,reason)
		else
			PrintError("expected kick reason text")
			SoundPlay2D("WrongBtn")
		end
	else
		PrintError("expected player id")
		SoundPlay2D("WrongBtn")
	end
end
function CB_Ban(id)
	id = F_PositiveInteger(id)
	if not id then
		PrintError("expected player id")
		SoundPlay2D("WrongBtn")
	else
		SendNetworkEvent("moderator_tools:BanAccount",id)
	end
end
function CB_BanIp(id)
	local start,stop = string.find(id,"%d+.%d+.%d+.%d+")
	if start then
		local ip = string.sub(id,start,stop)
		SendNetworkEvent("moderator_tools:BanIpByString",ip)
		return
	end
	id = F_PositiveInteger(id)
	if not id then
		PrintError("expected player id")
		SoundPlay2D("WrongBtn")
	else
		SendNetworkEvent("moderator_tools:BanIpByPlayer",id)
	end
end
function CB_PreBan(user)
	if type(user) == "string" then
		SendNetworkEvent("moderator_tools:PreBan",user)
	else
		PrintError("expected username")
		SoundPlay2D("WrongBtn")
	end
end

-- utility
function F_PositiveInteger(id)
	id = tonumber(id)
	if id and math.floor(id) == id and id >= 0 then
		return id
	end
end
function F_TypeStringBigBox(menu,prefix)
	local typing = StartTyping()
	if typing then
		while menu:active() do
			local ar = GetDisplayAspectRatio()
			local x,y,w,h = 0.5-0.25/ar,0.35,0.5/ar,0.3
			if not IsTypingActive(typing) then
				if not WasTypingAborted(typing) then
					return GetTypingString(typing)
				end
				break
			end
			DrawRectangle(x,y,w,h,0,0,0,255)
			SetTextFont("Cascadia Mono")
			SetTextColor(255,255,255,255)
			SetTextClipping(w,h)
			SetTextAlign("L","T")
			SetTextWrapping(w)
			SetTextPosition(x,y)
			SetTextHeight(0.02)
			DrawText(prefix..GetTypingString(typing,true))
			menu:draw("[TYPING]")
			Wait(0)
		end
	end
end
function F_TypeStringSmallBox(menu,prefix)
	local typing = StartTyping()
	if typing then
		while menu:active() do
			local ar = GetDisplayAspectRatio()
			local x,y,w,h = 0.5-0.25/ar,0.45,0.5/ar,0.1
			if not IsTypingActive(typing) then
				if not WasTypingAborted(typing) then
					return GetTypingString(typing)
				end
				break
			end
			DrawRectangle(x,y,w,h,0,0,0,255)
			SetTextFont("Cascadia Mono")
			SetTextColor(255,255,255,255)
			SetTextClipping(w,h)
			SetTextAlign("L","T")
			SetTextWrapping(w)
			SetTextPosition(x,y)
			SetTextHeight(0.02)
			DrawText(prefix..GetTypingString(typing,true))
			menu:draw("[TYPING]")
			Wait(0)
		end
	end
end

-- f2menu
function M_MainMenu(parent,selected)
	local menu = parent:submenu(selected.name,selected.description)
	while menu:active() do
		if menu:option("Player List","["..gPlayerCount.."]") then
			M_PlayerList(menu)
		elseif menu:option("Report Inbox","["..gReportCount.."]") then
			M_ReportInbox(menu)
		elseif menu:option("Ban IP") then
			F_BanIp(menu)
		end
		menu:draw()
		Wait(0)
	end
end
function M_PlayerList(parent)
	local players
	local menu = parent:submenu("Player List","Perform moderative actions on a player.")
	gUpdatePlayers = true
	while menu:active() do
		if gUpdatePlayers then
			players = {}
			for id,name in pairs(gPlayers) do
				table.insert(players,{id,name})
			end
			table.sort(players,function(a,b)
				return string.lower(a[2]) < string.lower(b[2])
			end)
		end
		for _,v in ipairs(players) do
			if menu:option(v[2],"["..v[1].."]") then
				M_PlayerActions(menu,unpack(v))
			end
		end
		menu:draw()
		Wait(0)
	end
end
function M_PlayerActions(parent,id,name)
	local menu = parent:submenu(name,"Perform moderative actions on this player.")
	while menu:active() and gPlayers[id] == name do
		if menu:option("Warn",nil,"/warn "..id.." <reason>") then
			local text = F_TypeStringBigBox(menu,"warning text: ")
			if text and gPlayers[id] == name then
				if text ~= "" then
					SendNetworkEvent("moderator_tools:WarnPlayer",id,text)
				else
					menu:alert("Expected warning message.")
					SoundPlay2D("WrongBtn")
				end
			end
		elseif menu:option("Mute",nil,"/mute "..id.." <minutes>") then
			local text = F_TypeStringSmallBox(menu,"mute duration (minutes): ")
			if text and gPlayers[id] == name then
				local minutes = tonumber(text)
				if minutes then
					SendNetworkEvent("moderator_tools:MutePlayer",id,minutes)
				else
					menu:alert("Expected amount of minutes.")
					SoundPlay2D("WrongBtn")
				end
			end
		elseif menu:option("Unmute",nil,"/unmute "..id) then
			SendNetworkEvent("moderator_tools:MutePlayer",id)
		elseif menu:option("Kick",nil,"/kick "..id.." <reason>") then
			local text = F_TypeStringBigBox(menu,"kick reason: ")
			if text and gPlayers[id] == name then
				if text ~= "" then
					SendNetworkEvent("moderator_tools:KickPlayer",id,text)
				else
					menu:alert("Expected kick reason.")
					SoundPlay2D("WrongBtn")
				end
			end
		elseif menu:option("Ban (account)",nil,"/ban "..id) then
			SendNetworkEvent("moderator_tools:BanAccount",id)
		elseif menu:option("Ban (ip)",nil,"/ban_ip "..id) then
			SendNetworkEvent("moderator_tools:BanIpByPlayer",id)
		end
		menu:draw()
		Wait(0)
	end
end
function M_ReportInbox(parent)
	local sorted = {}
	local menu = parent:submenu("Report Inbox","View and dismiss reports.")
	for from,reports in pairs(gReports) do
		table.insert(sorted,{from,reports})
	end
	table.sort(sorted,function(a,b)
		return string.lower(a[1]) < string.lower(b[1])
	end)
	while menu:active() do
		for _,v in ipairs(sorted) do
			if gReports[v[1]] == v[2] and menu:option("from "..v[1],"["..table.getn(v[2]).."]") then
				M_PlayerInbox(menu,unpack(v))
			end
		end
		menu:draw()
		Wait(0)
	end
end
function M_PlayerInbox(parent,name,reports)
	local menu = parent:submenu("from "..name)
	while menu:active() and gReports[name] == reports do
		for i,v in ipairs(reports) do
			if menu:option("about "..v[1],nil,"reason:\n"..v[2]) and F_Dismiss(menu) and gReports[name] == reports and reports[i] == v then
				SendNetworkEvent("moderator_tools:DismissReport",name,v[1],i)
			end
		end
		menu:draw()
		Wait(0)
	end
end
function F_Dismiss(menu)
	while menu:active() do
		menu:draw("[DISMISS?]")
		Wait(0)
		if menu:left() then
			return false
		elseif menu:right() then
			return true
		end
	end
	return false
end
function F_BanIp(menu)
	local text = F_TypeStringSmallBox(menu,"ip: ")
	if text then
		local start,stop = string.find(text,"%d+.%d+.%d+.%d+")
		if start then
			SendNetworkEvent("moderator_tools:BanIpByString",string.sub(text,start,stop))
			return
		end
	end
	menu:alert("Expected valid ipv4.")
	SoundPlay2D("WrongBtn")
end

-- request permissions
SendNetworkEvent("moderator_tools:RequestPermission")
