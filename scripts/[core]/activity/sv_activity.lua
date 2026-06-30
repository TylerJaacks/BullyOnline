NOTIFY_DELAY = 20000

gActivities = {}
gPlayers = {}

function exports.DoesActivityExist(id)
	local act = gActivities[id]
	if act and act.script == GetCurrentScript() then
		return true
	end
	return false
end
function exports.StartActivity(player,id,cb,arg,info)
	local data = gPlayers[player]
	if data and not data.activity and type(id) == "string" and (cb == nil or type(cb) == "function") and type(info) == "table" then
		local act = gActivities[id]
		if act then
			if act.script ~= GetCurrentScript() then
				return false
			end
			data.activity = act
			act.players[player] = true
			F_UpdatePlayers(act)
			SendNetworkEvent(player,"activity:SetActivity",id,act.info)
			if F_IsFull(act) and act.available then
				F_StartActivity(act)
				return true
			end
			for player in pairs(gPlayers) do
				SendNetworkEvent(player,"activity:UpdateActivity",id,act.info)
			end
			F_UpdatePlayerSwitch(player)
			return true
		end
		info.players = 1
		info.timer_base = GetSyncTimer()
		act = {
			listed = true, -- if it should be listed
			available = info.timer_ms ~= nil, -- if it should be joinable
			players = {[player] = true}, -- activity can only exist while there are players in it
			script = GetCurrentScript(), -- owning script
			info = info, -- data for the activity on the client ui
			cb = cb, -- function to call when the info timer expires
			arg = arg, -- argument for function
			id = id,
		}
		if info.announce then
			F_SayPlayerNotification(player,act)
			info.announce = false
		end
		gActivities[id] = act
		data.activity = act
		SendNetworkEvent(player,"activity:SetActivity",id,info,true)
		F_UpdatePlayerSwitch(player)
		if not info.hidden then
			for player in pairs(gPlayers) do
				SendNetworkEvent(player,"activity:AddActivity",id,info)
			end
		else
			act.listed = false
		end
		return true
	end
	return false
end
function exports.LeaveActivity(player,id)
	local act = gActivities[id]
	if act and act.players[player] and act.script == GetCurrentScript() then
		if IsPlayerValid(player,false) then
			gPlayers[player].activity = nil
		else
			gPlayers[player] = nil
		end
		F_RemovePlayer(act,player)
		if gPlayers[player] then
			SendNetworkEvent(player,"activity:SetActivity")
			F_UpdatePlayerSwitch(player)
		end
	end
end
function exports.StopActivity(id)
	local act = gActivities[id]
	if act and act.script == GetCurrentScript() then
		for player,data in pairs(gPlayers) do
			if not IsPlayerValid(player,false) then
				act.players[player] = nil
				gPlayers[player] = nil
			end
		end
		F_StopActivity(act)
	end
end

function F_StopActivity(act)
	for player in pairs(gPlayers) do
		SendNetworkEvent(player,"activity:UpdateActivity",act.id)
	end
	for player in pairs(act.players) do
		SendNetworkEvent(player,"activity:SetActivity")
		gPlayers[player].activity = nil
		F_UpdatePlayerSwitch(player)
	end
	gActivities[act.id] = nil
end
function F_UpdatePlayers(act)
	local count = 0
	for _ in pairs(act.players) do
		count = count + 1
	end
	act.info.players = count
end
function F_IsFull(act)
	return act.info.max_players and act.info.players >= act.info.max_players
end
function F_RemovePlayer(act,player)
	act.players[player] = nil
	if next(act.players) then
		F_UpdatePlayers(act)
		for player in pairs(gPlayers) do
			SendNetworkEvent(player,"activity:UpdateActivity",act.id,act.info)
		end
	else
		F_StopActivity(act)
	end
end
function F_StartActivity(act)
	if act.cb then
		local count = 1
		local players = {}
		for player in pairs(act.players) do
			if F_IsPlayerNearby(player,act) then
				players[count] = player
				count = count + 1
			end
		end
		CallFunctionFromScript(act.script,act.cb,players,act.arg)
	end
	act.listed = false
	act.available = false
	for player in pairs(gPlayers) do
		F_UpdatePlayerSwitch(player)
		SendNetworkEvent(player,"activity:UpdateActivity",act.id)
	end
end

CreateThread(function()
	while true do
		local current = GetSyncTimer()
		for _,act in pairs(gActivities) do
			local info = act.info
			if act.available and info.timer_ms and current - info.timer_base >= info.timer_ms then
				F_StartActivity(act)
			end
		end
		Wait(0)
	end
end)

RegisterLocalEventHandler("ScriptDestroyed",function(script)
	for _,act in pairs(gActivities) do
		if act.script == script then
			F_StopActivity(act)
		end
	end
end)
RegisterLocalEventHandler("PlayerDropped",function(player)
	local data = gPlayers[player]
	if data then
		gPlayers[player] = nil
		if data.activity then
			F_RemovePlayer(data.activity,player)
		end
	end
end)
RegisterNetworkEventHandler("activity:InitScript",function(player)
	local data = gPlayers[player]
	local skipper = false
	if data then -- double init? whatever - just reset them as if they dropped.
		gPlayers[player] = nil
		if data.activity then
			F_RemovePlayer(data.activity,player)
		end
	end
	for _,act in pairs(gActivities) do
		if act.listed then
			SendNetworkEvent(player,"activity:AddActivity",act.id,act.info)
		end
	end
	if DoesPlayerHaveRole(player,"admin") then
		SendNetworkEvent(player,"activity:AllowSkip")
		skipper = true
	end
	gPlayers[player] = {switch = true,skipper = skipper}
end)
RegisterNetworkEventHandler("activity:SetActivity",function(player,id)
	local data = gPlayers[player]
	if data then
		local act = gActivities[id]
		data.switch = false -- since client turned their can switch state off
		if not act then
			if data.activity and data.activity.available then
				F_RemovePlayer(data.activity,player)
				SendNetworkEvent(player,"activity:SetActivity")
				data.activity = nil
			end
		elseif F_IsPlayerNearby(player,act) and act.available and act ~= data.activity then -- activity being switched to must be available
			if data.activity then
				if not data.activity.available then -- activity being switched from must still be available
					F_UpdatePlayerSwitch(player)
					return
				end
				F_RemovePlayer(data.activity,player)
			end
			data.activity = act
			act.players[player] = true
			F_UpdatePlayers(act)
			SendNetworkEvent(player,"activity:SetActivity",id,act.info)
			if F_IsFull(act) then
				F_StartActivity(act)
				return
			end
			for player in pairs(gPlayers) do
				SendNetworkEvent(player,"activity:UpdateActivity",id,act.info)
			end
		end
		F_UpdatePlayerSwitch(player)
	end
end)
RegisterNetworkEventHandler("activity:SkipQueue",function(player)
	local data = gPlayers[player]
	if data and data.skipper then
		if data.activity and data.activity.available then
			F_StartActivity(data.activity)
		end
		SendNetworkEvent(player,"activity:AllowSkip")
	end
end)

function F_UpdatePlayerSwitch(player)
	local data = gPlayers[player]
	if not data.activity or data.activity.available then -- player can switch if they're not in an activity *or* the activity is available
		if not data.switch then
			SendNetworkEvent(player,"activity:AllowSwitch",true)
			data.switch = true
		end
	elseif data.switch then
		SendNetworkEvent(player,"activity:AllowSwitch")
		data.switch = false
	end
end
function F_IsPlayerNearby(player,act)
	local ped = GetSyncPlayerPed(player)
	local px,py,pz = GetSyncEntityPos(ped)
	local cx,cy,cz = unpack(act.info.center)
	local dx,dy,dz = px-cx,py-cy,pz-cz
	local range = act.info.range + 1
	if dx*dx+dy*dy+dz*dz < range*range then
		if act.info.area and GetSyncEntityArea(ped) ~= act.info.area then
			return false
		end
		return true
	end
	return false
end
function F_SayPlayerNotification(player,act)
	local data = gPlayers[player]
	local timer = GetAccurateTimer()
	if not data.notify or timer - data.notify >= NOTIFY_DELAY then
		if act.info.title then
			local str = "["..GetPlayerName(player).." started: "..act.info.title.."]"
			for player,data in pairs(gPlayers) do
				if not data.activity then
					SendNetworkEvent(player,"activity:NotifyActivity",str)
				end
			end
		end
		data.notify = timer
	end
end
