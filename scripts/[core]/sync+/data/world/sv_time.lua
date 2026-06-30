-- SYNC+ | chapter | Xx_Yubari_xX
--  provides server side time sync

gDimensions = setmetatable({},{__mode = "k"}) -- [dimension] = {accurate_timer, minutes}
gPlayers = {}

gDefault = {
	when = GetSyncTimer(),
	base = math.mod(GetConfigNumber(GetScriptConfig(),"default_clock_hour",0)*60+GetConfigNumber(GetScriptConfig(),"default_clock_minute",0),1440),
	rate = GetConfigNumber(GetScriptConfig(),"default_clock_rate",60) / 60000,
}

-- api
RegisterFunction("ClockGet",function()
	local clock = gDimensions[GetSyncActiveDimension()]
	if clock then
		return F_GetClock(clock)
	end
	return F_GetClock(gDefault)
end)
RegisterFunction("ClockSet",function(hours,minutes)
	local dimension = GetSyncActiveDimension()
	local rate = gDefault.rate
	if type(hours) ~= "number" then
		typerror(1,"number")
	elseif minutes == nil then
		minutes = 0
	elseif type(minutes) ~= "number" then
		typerror(2,"number")
	end
	if gDimensions[dimension] then
		rate = gDimensions[dimension].rate
	end
	gDimensions[dimension] = {
		when = GetSyncTimer(),
		base = math.mod(math.max(0,math.floor(hours*60+minutes)),1440),
		rate = rate,
	}
	F_UpdateDimension(dimension)
end)
RegisterFunction("ClockSetTickRate",function(a,b)
	local dimension = GetSyncActiveDimension()
	local clock = gDimensions[dimension] or gDefault
	local rate = 0
	if type(a) ~= "number" then
		typerror(1,"number")
	elseif b == nil then
		b = a
	elseif type(b) ~= "number" then
		typerror(2,"number")
	end
	if a > 0 then
		rate = (a * (math.max(0,b) / a)) / 60000
	end
	gDimensions[dimension] = {
		when = GetSyncTimer(),
		base = clock.base + (GetSyncTimer() - clock.when) * clock.rate,
		rate = rate,
	}
	F_UpdateDimension(dimension)
end)

-- exports
function exports.InheritClock()
	local dimension = GetSyncActiveDimension()
	local main = GetSyncMainDimension()
	if dimension ~= main then
		gDimensions[dimension] = gDimensions[main] or gDefault
		F_UpdateDimension(dimension)
	end
end

-- players
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterLocalEventHandler("sync:SwapPlayer",function(player,ped)
	if gPlayers[player] then
		F_SetDimension(player,GetSyncEntityDimension(ped))
	end
end)
RegisterLocalEventHandler("sync:SwapDimension",function(ped)
	if IsSyncPedValid(ped) then
		local player = GetSyncPlayerFromPed(ped)
		if gPlayers[player] then
			F_SetDimension(player,GetSyncEntityDimension(ped))
		end
	end
end)
RegisterNetworkEventHandler("sync+:GetClock",function(player)
	F_SetDimension(player,GetSyncEntityDimension(GetSyncPlayerPed(player)))
end)

-- utility
function F_UpdateDimension(dimension)
	local minutes,rate = F_GetMinsRate(gDimensions[dimension])
	for player,di in pairs(gPlayers) do
		if di == dimension then
			SendNetworkEvent(player,"sync+:SetClock",minutes,rate)
		end
	end
end
function F_SetDimension(player,dimension)
	if gPlayers[player] ~= dimension then
		SendNetworkEvent(player,"sync+:SetClock",F_GetMinsRate(gDimensions[dimension] or gDefault))
		gPlayers[player] = dimension
	end
end
function F_GetMinsRate(clock)
	return clock.base + (GetSyncTimer() - clock.when) * clock.rate,clock.rate
end
function F_GetClock(clock)
	local minutes = clock.base + (GetSyncTimer() - clock.when) * clock.rate
	return math.mod(math.floor(minutes/60),24),math.mod(minutes,60)
end
