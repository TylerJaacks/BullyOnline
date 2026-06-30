MAX_BLOCKS = 2000

gPlayers = {}

-- commands
SetCommand("say",function(text)
	if text then
		for player,data in pairs(gPlayers) do
			if not data.silent then
				SendNetworkEvent(player,"chat:ServerMessage",text)
			end
		end
	else
		PrintError("expected message")
	end
end,true)
SetCommand("say_as",function(who,...)
	local text
	if not who then
		PrintError("expected player name")
		return
	end
	for _,v in ipairs(arg) do
		if text then
			text = text.." "..v
		else
			text = v
		end
	end
	if not text then
		PrintError("expected message")
		return
	end
	for player,data in pairs(gPlayers) do
		local name = GetPlayerName(player)
		if string.lower(name) == string.lower(who) then
			local r,g,b = unpack(data.color)
			for player,data in pairs(gPlayers) do
				if not data.blocks[string.lower(name)] and not data.silent and data.global then
					SendNetworkEvent(player,"chat:PlayerMessage",name,text,r,g,b)
				end
			end
			return
		end
	end
	for player,data in pairs(gPlayers) do
		if not data.blocks[string.lower(name)] and not data.silent and data.global then
			SendNetworkEvent(player,"chat:PlayerMessage",who,text,255,213,3)
		end
	end
end)

-- exports
function exports.Say(text)
	text = tostring(text)
	for player,data in pairs(gPlayers) do
		if not data.silent and IsPlayerValid(player) then
			SendNetworkEvent(player,"chat:ServerMessage",text)
		end
	end
end
function exports.SayAs(player,text)
	local data = gPlayers[player]
	if data and IsPlayerValid(player) then
		local name = GetPlayerName(player)
		text = tostring(text)
		for player,data in pairs(gPlayers) do
			if not data.blocks[string.lower(name)] and not data.silent and data.global and IsPlayerValid(player) then
				SendNetworkEvent(player,"chat:PlayerMessage",name,text,unpack(data.color))
			end
		end
	end
end

-- core
RegisterLocalEventHandler("PlayerConnected",function(player)
	if IsPlayerValid(player,false) then
		local name = GetPlayerName(player)
		for player,data in pairs(gPlayers) do
			if not data.blocks[string.lower(name)] and not data.silent and data.status then
				SendNetworkEvent(player,"chat:PlayerJoined",name)
			end
		end
		F_InitPlayer(player)
	end
end)
RegisterLocalEventHandler("PlayerDropped",function(player)
	-- it's possible to drop without fully connecting, so we'll make sure they did connect to send this message
	if gPlayers[player] then
		local name = GetPlayerName(player)
		gPlayers[player] = nil
		for player,data in pairs(gPlayers) do
			if not data.blocks[string.lower(name)] and not data.silent and data.status then
				SendNetworkEvent(player,"chat:PlayerLeft",name)
			end
		end
	end
	for other,data in pairs(gPlayers) do
		if data.reply == player then
			data.reply = nil
		end
	end
end)
RegisterNetworkEventHandler("chat:SendMessage",function(player,message)
	-- check the message is okay because we shouldn't fully trust messages from players
	local data = gPlayers[player]
	if data and not data.silent and F_CheckMessage(message) then
		local found,finish,user = string.find(message,"^@(%S+)%s+")
		if found and string.len(message) > finish then
			F_SendPlayerWhisper(player,string.lower(user),string.sub(message,finish+1))
		elseif data.global then
			local id = GetPlayerId(player)
			local r,g,b = unpack(data.color)
			local name = GetPlayerName(player)
			for player,data in pairs(gPlayers) do
				if not data.blocks[string.lower(name)] and not data.silent and data.global then
					if data.moderator then
						SendNetworkEvent(player,"chat:PlayerMessage","["..id.."] "..name,message,r,g,b)
					else
						SendNetworkEvent(player,"chat:PlayerMessage",name,message,r,g,b)
					end
				end
			end
			if GetConfigBoolean(GetScriptConfig(),"log_chat",false) then
				PrintOutput(name..": "..message)
			end
		else
			SendNetworkEvent(player,"chat:DenyMessage")
		end
	end
end)

-- commands
RegisterNetworkEventHandler("chat:SendWhisper",function(player,user,message)
	local data = gPlayers[player]
	if data and not data.silent and type(user) == "string" and F_CheckMessage(message) then
		F_SendPlayerWhisper(player,string.lower(user),message)
	end
end)
RegisterNetworkEventHandler("chat:SendReply",function(player,message)
	local data = gPlayers[player]
	if data and not data.silent and type(message) == "string" then
		if data.reply then
			F_SendPlayerWhisper(player,data.reply,message)
		else
			SendNetworkEvent(player,"chat:DenyReply")
		end
	end
end)
RegisterNetworkEventHandler("chat:BlockUser",function(player,user)
	local data = gPlayers[player]
	if data and type(user) == "string" then
		user = string.lower(user)
		if not data.blocks[user] then
			local count = 0
			for _ in pairs(data.blocks) do
				count = count + 1
			end
			if count < MAX_BLOCKS and GetPlayerName(player) ~= user and F_AllowBlock(user) then
				SendNetworkEvent(player,"chat:SetBlock",user,true)
				data.blocks[user] = true
				F_SavePlayer(player)
			else
				SendNetworkEvent(player,"chat:SetBlock",user)
			end
		end
	end
end)
RegisterNetworkEventHandler("chat:UnblockUser",function(player,user)
	local data = gPlayers[player]
	if data and type(user) == "string" then
		user = string.lower(user)
		if data.blocks[user] then
			SendNetworkEvent(player,"chat:SetBlock",user)
			data.blocks[user] = nil
			F_SavePlayer(player)
		end
	end
end)

-- preferences
RegisterNetworkEventHandler("chat:InitPreferences",function(player)
	local data = gPlayers[player]
	if data then
		local users = {}
		for user in pairs(data.blocks) do
			table.insert(users,user)
		end
		SendNetworkEvent(player,"chat:SetBlocks",users)
		for k,v in pairs({silent="SetSilent",global="SetGlobal",direct="SetDirect",status="SetStatus"}) do
			if data[k] then
				SendNetworkEvent(player,"chat:"..v,true)
			else
				SendNetworkEvent(player,"chat:"..v)
			end
		end
	end
end)
RegisterNetworkEventHandler("chat:SetSilent",function(player,on)
	local data = gPlayers[player]
	if data then
		data.silent = on ~= nil
		SendNetworkEvent(player,"chat:SetSilent",on)
		F_SavePlayer(player)
	end
end)
RegisterNetworkEventHandler("chat:SetGlobal",function(player,on)
	local data = gPlayers[player]
	if data then
		data.global = on ~= nil
		SendNetworkEvent(player,"chat:SetGlobal",on)
		F_SavePlayer(player)
	end
end)
RegisterNetworkEventHandler("chat:SetDirect",function(player,on)
	local data = gPlayers[player]
	if data then
		data.direct = on ~= nil
		SendNetworkEvent(player,"chat:SetDirect",on)
		F_SavePlayer(player)
	end
end)
RegisterNetworkEventHandler("chat:SetStatus",function(player,on)
	local data = gPlayers[player]
	if data then
		data.status = on ~= nil
		SendNetworkEvent(player,"chat:SetStatus",on)
		F_SavePlayer(player)
	end
end)

-- safety
function F_AllowBlock(user)
	for v in AllConfigStrings(GetScriptConfig(),"forbid_block") do
		if string.lower(v) == user then
			return false
		end
	end
	return true
end
function F_CheckMessage(message)
	return type(message) == "string" and string.find(message,"%S") and string.len(message) <= GetConfigNumber(GetScriptConfig(),"max_message_length",100) and RunLocalEvent("chat:SendMessage",player,message)
end

-- utility
function F_InitPlayer(player)
	local account = GetPlayerAccountTable(player,"chat")
	gPlayers[player] = {
		color = {F_GetPlayerColor(player)},
		moderator = F_IsPlayerModerator(player),
		silent = false,
		account = account,
		global = account.global ~= false,
		direct = account.direct ~= false,
		status = account.status ~= false,
		blocks = account.blocks or {}, -- {[user] = true}
		-- .reply = player
	}
end
function F_SavePlayer(player)
	local data = gPlayers[player]
	local account = data.account
	if account then
		account.global = data.global
		account.direct = data.direct
		account.status = data.status
		account.blocks = data.blocks
		SavePlayerAccountTable(player)
	end
end
function F_GetPlayerColor(player)
	if dsl.role_colors then
		return dsl.role_colors.GetColor(player)
	end
	return 230,230,230
end
function F_IsPlayerModerator(player)
	for role in AllConfigStrings(GetScriptConfig(),"see_id_role") do
		if DoesPlayerHaveRole(player,role) then
			return true
		end
	end
	return false
end
function F_SendPlayerWhisper(player,user,message) -- TODO: should limit if unique usernames aren't enforced
	local data = gPlayers[player]
	local r,g,b = unpack(data.color)
	local name = GetPlayerName(player)
	if data.direct then
		for recipient,data in pairs(gPlayers) do
			local rname = GetPlayerName(recipient)
			if string.lower(rname) == user or recipient == user then
				local blocked = data.blocks[string.lower(name)]
				if not blocked and not data.silent and data.direct then
					SendNetworkEvent(player,"chat:DirectMessage",name,message,r,g,b,rname)
					SendNetworkEvent(recipient,"chat:DirectMessage",name,message,r,g,b)
					data.reply = player
				elseif blocked then -- ghost block
					SendNetworkEvent(player,"chat:DirectMessage",name,message,r,g,b,rname)
				else
					SendNetworkEvent(player,"chat:DenyDirect",true)
				end
				return
			end
		end
		SendNetworkEvent(player,"chat:DenyDirect")
	else
		SendNetworkEvent(player,"chat:DenyMessage",true)
	end
end

-- init (for restarting scripts)
for player in AllPlayers() do
	F_InitPlayer(player)
end
