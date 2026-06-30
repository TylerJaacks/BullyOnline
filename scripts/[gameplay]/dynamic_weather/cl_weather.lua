gWeathers = {[0] = "Sunny","Cloudy","Rainy","Foggy","ExtraSunny","Hurricane"}

RegisterNetworkEventHandler("dynamic_weather:Admin",function(dynamic)
	if GetConfigBoolean(GetScriptConfig(),"admin_command",false) then
		SetCommand("weather",CB_WeatherCommand,"Usage: weather [type | \"release\"]\nGet, set, or release the current weather.")
	end
	if GetConfigBoolean(GetScriptConfig(),"admin_f2menu",false) then
		RegisterLocalEventHandler("f2menu:Open",CB_F2MenuOpen)
	end
	gDynamic = dynamic
end)
RegisterNetworkEventHandler("dynamic_weather:Dynamic",function(dynamic)
	gDynamic = dynamic
end)
function F_GetWeather()
	local a = WeatherGetNow()
	local b = WeatherGetNext()
	if a == b then
		return gWeathers[a] or tostring(a)
	end
	return (gWeathers[a] or a).." -> "..(gWeathers[b] or b).." ("..math.floor(WeatherGetTransition()*100).."%)"
end
function CB_WeatherCommand(weather)
	if weather then
		local name = string.lower(weather)
		if name == "release" then
			if not gDynamic then
				SendNetworkEvent("dynamic_weather:Release")
			end
			PrintOutput("releasing weather")
			return
		end
		for w,n in pairs(gWeathers) do
			if string.lower(n) == name then
				weather = w
				break
			end
		end
		weather = tonumber(weather)
		if gWeathers[weather] then
			SendNetworkEvent("dynamic_weather:Set",weather)
			PrintOutput("setting weather: "..gWeathers[weather])
		elseif weather then
			PrintError("invalid weather: "..weather)
		else
			PrintError("invalid weather: \""..name.."\"")
		end
		return
	end
	PrintOutput("current weather: "..F_GetWeather()..".")
end
function CB_F2MenuOpen(f_add)
	f_add({
		name = "Set Weather",
		description = "(admin only)\nControl the weather.",
		thread = M_SetWeather,
	})
end
function M_SetWeather(parent,selected)
	local menu = parent:submenu(selected.name)
	while menu:active() do
		for w = 0,5 do
			if menu:option("["..w.."] "..gWeathers[w]) then
				SendNetworkEvent("dynamic_weather:Set",w)
			end
		end
		if not gDynamic and menu:option("< release weather >") then
			SendNetworkEvent("dynamic_weather:Release")
		end
		menu:help("current: "..F_GetWeather())
		menu:draw()
		Wait(0)
	end
end

SendNetworkEvent("dynamic_weather:Init")
