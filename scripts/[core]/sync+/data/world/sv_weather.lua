-- SYNC+ | chapter | Xx_Yubari_xX
--  provides server side weather sync

gDimensions = setmetatable({},{__mode = "k"})
gPlayers = {}

gTransition = GetConfigNumber(GetScriptConfig(),"weather_trans_ms",1800) / 60

-- api
RegisterFunction("WeatherGet",function()
	local weather = gDimensions[GetSyncActiveDimension()]
	if weather then
		if (GetSyncTimer() - weather.when) / 1000 >= gTransition * 0.5 then
			return weather.next
		end
		return weather.last
	end
	return 0
end)
RegisterFunction("WeatherSet",function(a)
	local dimension = GetSyncActiveDimension()
	if type(a) ~= "number" then
		typerror(1,"number")
	elseif not (a >= 0 and a <= 5) then
		argerror(1,"invalid weather")
	end
	a = math.floor(a)
	gDimensions[dimension] = {
		when = GetSyncTimer(),
		last = a,
		next = a,
	}
	F_UpdateDimension(dimension)
end)
RegisterFunction("WeatherTransition",function(a,b)
	local dimension = GetSyncActiveDimension()
	if type(a) ~= "number" then
		typerror(1,"number")
	elseif not (a >= 0 and a <= 5) then
		argerror(1,"invalid weather")
	elseif type(b) ~= "number" then
		typerror(2,"number")
	elseif not (b >= 0 and b <= 5) then
		argerror(2,"invalid weather")
	end
	gDimensions[dimension] = {
		when = GetSyncTimer(),
		last = math.floor(a),
		next = math.floor(b),
	}
	F_UpdateDimension(dimension)
end)

-- exports
function exports.InheritWeather()
	local dimension = GetSyncActiveDimension()
	local main = GetSyncMainDimension()
	if dimension ~= main then
		gDimensions[dimension] = gDimensions[main]
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
RegisterNetworkEventHandler("sync+:GetWeather",function(player)
	F_SetDimension(player,GetSyncEntityDimension(GetSyncPlayerPed(player)))
end)

-- utility
function F_UpdateDimension(dimension)
	local weather = gDimensions[dimension]
	local ms,a,b = 0,0,0
	if weather then
		ms,a,b = GetSyncTimer()-weather.when,weather.last,weather.next
	end
	for player,di in pairs(gPlayers) do
		if di == dimension then
			if weather then
				SendNetworkEvent(player,"sync+:SetWeather",ms,a,b)
			else
				SendNetworkEvent(player,"sync+:SetWeather")
			end
		end
	end
end
function F_SetDimension(player,dimension)
	if gPlayers[player] ~= dimension then
		local weather = gDimensions[dimension]
		if weather then
			SendNetworkEvent(player,"sync+:SetWeather",GetSyncTimer()-weather.when,weather.last,weather.next)
		else
			SendNetworkEvent(player,"sync+:SetWeather")
		end
		gPlayers[player] = dimension
	end
end
