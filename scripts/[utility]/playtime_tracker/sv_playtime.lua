gPlayers = {}

RegisterNetworkEventHandler("playtime_tracker:RequestPlaytime",function(player)
	F_UpdatePlaytime(player,F_GetPlayer(player))
end)
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)

function main()
	local last = GetAccurateTimer()
	while true do
		local timer = GetAccurateTimer()
		if timer - last >= 60000 then
			F_AddMinutes(1)
			last = timer
		end
		Wait(0)
	end
end
function F_AddMinutes(add)
	local count = 0
	local players = {}
	for player in AllPlayers() do
		count = count + 1
		players[count] = player
	end
	for index,player in ipairs(players) do
		if IsPlayerValid(player,false) then
			local data = F_GetPlayer(player)
			if data.account then
				local total = data.account.minutes + add
				data.account.hours = data.account.hours + math.floor(total/60)
				data.account.minutes = math.mod(total,60)
				SavePlayerAccountTable(player)
			end
			data.minutes = data.minutes + add
			F_UpdatePlaytime(player,data)
		end
		if index < count then
			Wait(0)
		end
	end
end
function F_GetPlayer(player)
	local data = gPlayers[player]
	if not data then
		local account = GetPlayerAccountTable(player,"playtime_tracker")
		if account and not next(account) then
			account.hours = 0
			account.minutes = 0
			account.events = {} -- [event] = {hours, minutes}
		end
		data = {
			account = account,
			minutes = 0, -- this session
			events = {}, -- this session: [event] = minutes
		}
		gPlayers[player] = data
	end
	return data
end
function F_UpdatePlaytime(player,data)
	if data.account then
		SendNetworkEvent(player,"playtime_tracker:UpdatePlaytime",data.account.hours*60+data.account.minutes)
	else
		SendNetworkEvent(player,"playtime_tracker:UpdatePlaytime",data.minutes)
	end
end
function F_HasPassed(eh,em,th,tm)
	-- event hours > target hours
	-- *or* event hours is the same and event minutes > target minutes
	return eh > th or (eh == th and em >= tm)
end
function F_TimeUntil(eh,em,th,tm)
	if not F_HasPassed(eh,em,th,tm) then
		local hours = th - eh
		local minutes = tm - em
		if minutes < 0 then
			hours = hours - 1
			minutes = minutes + 60
		end
		return false,hours,minutes
	end
	return true
end

function exports.MarkEvent(player,event)
	if IsPlayerValid(player,false) and type(event) == "string" then
		local data = F_GetPlayer(player)
		if data.account then
			data.account.events[event] = {data.account.hours,data.account.minutes}
			SavePlayerAccountTable(player)
		end
		data.events[event] = data.minutes
		return true
	end
	return false
end
function exports.ClearEvent(player,event)
	if IsPlayerValid(player,false) and type(event) == "string" then
		local data = F_GetPlayer(player)
		if data.account then
			data.account.events[event] = nil
			SavePlayerAccountTable(player)
		end
		data.events[event] = nil
		return true
	end
	return false
end
function exports.PassedEvent(player,event,hours,minutes)
	if type(hours) ~= "number" or math.floor(hours) ~= hours or hours < 0 then
		argerror(2,"invalid hour count")
	elseif type(minutes) ~= "number" or math.floor(minutes) ~= minutes or minutes < 0 then
		argerror(3,"invalid minute count")
	elseif IsPlayerValid(player,false) then
		local h,m
		local data = F_GetPlayer(player)
		if data.account then
			local when = data.account.events[event]
			if when then
				h,m = unpack(when)
			end
		else
			m = data.events[event]
			if m then
				h = math.floor(m/60)
				m = math.mod(m,60)
			end
		end
		if h then
			minutes = minutes + m
			hours = hours + h + math.floor(minutes/60)
			minutes = math.mod(minutes,60)
			if data.account then
				return F_TimeUntil(data.account.hours,data.account.minutes,hours,minutes)
			end
			return F_TimeUntil(math.floor(data.minutes/60),math.mod(data.minutes,60),hours,minutes)
		end
	end
	return false
end
function exports.PassedPlaytime(player,hours,minutes)
	if type(hours) ~= "number" or math.floor(hours) ~= hours or hours < 0 then
		argerror(2,"invalid hour count")
	elseif type(minutes) ~= "number" or math.floor(minutes) ~= minutes or minutes < 0 then
		argerror(3,"invalid minute count")
	elseif IsPlayerValid(player,false) then
		local data = F_GetPlayer(player)
		if data.account then
			return F_HasPassed(data.account.hours,data.account.minutes,hours,minutes)
		end
		return F_HasPassed(math.floor(data.minutes/60),math.mod(data.minutes,60),hours,minutes)
	end
	return false
end
