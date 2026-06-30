-- chance for changing weather
CHANCE_PER_INTERVAL = GetConfigNumber(GetScriptConfig(),"change_chance_per_interval",15)
CHANCE_INTERVAL_MS = GetConfigNumber(GetScriptConfig(),"change_chance_interval_ms",90000)

-- chances for each weather type
WEATHER_CHANCES = {}
for value in AllConfigStrings(GetScriptConfig(),"dynamic_weather") do
	local a,b = string.find(value,",%s*")
	local weather,weight
	if a then
		weather = tonumber(string.sub(value,1,a-1))
		weight = tonumber(string.sub(value,b+1))
	end
	if weather and weight then
		table.insert(WEATHER_CHANCES,{weight,weather})
	else
		PrintError("invalid dynamic_weather configured")
	end
end

-- globals
gCurrent = 0
gDynamic = true
gPlayers = {}

-- events
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterNetworkEventHandler("dynamic_weather:Init",function(player)
	if DoesPlayerHaveRole(player,"admin") then
		SendNetworkEvent(player,"dynamic_weather:Admin",gDynamic)
		gPlayers[player] = true
	end
end)
RegisterNetworkEventHandler("dynamic_weather:Set",function(player,weather)
	if gPlayers[player] and type(weather) == "number" and math.floor(weather) == weather and weather >= 0 and weather <= 5 then
		for player in pairs(gPlayers) do
			SendNetworkEvent(player,"dynamic_weather:Dynamic",false)
		end
		WeatherSet(weather)
		gCurrent = weather
		gDynamic = false
	end
end)
RegisterNetworkEventHandler("dynamic_weather:Release",function(player)
	if gPlayers[player] then
		for player in pairs(gPlayers) do
			SendNetworkEvent(player,"dynamic_weather:Dynamic",true)
		end
		gDynamic = true
	end
end)

-- main
function main()
	if gDynamic then
		gCurrent = F_GetRandomWeather()
		WeatherSet(gCurrent)
	end
	while true do
		Wait(CHANCE_INTERVAL_MS)
		if gDynamic and math.random(100) <= CHANCE_PER_INTERVAL then
			local transition = F_GetRandomWeather(gCurrent)
			WeatherTransition(gCurrent,transition)
			gCurrent = transition
		end
	end
end
function F_GetRandomWeather(exclude)
	local weight = 0
	for _,w in ipairs(WEATHER_CHANCES) do
		if w[2] ~= exclude then
			weight = weight + w[1]
		end
	end
	weight = math.random(weight)
	for _,w in ipairs(WEATHER_CHANCES) do
		if w[2] ~= exclude then
			if weight <= w[1] then
				return w[2]
			end
			weight = weight - w[1]
		end
	end
end
