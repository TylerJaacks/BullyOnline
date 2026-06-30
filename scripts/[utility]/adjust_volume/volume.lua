RegisterLocalEventHandler("f2menu:Open",function(f_add)
	f_add({
		name = "Volume Settings",
		description = "Adjust the game's volume.",
		thread = M_VolumeSettings,
	})
end)
function M_VolumeSettings(parent,selected)
	local volume = {"Music","Speech","Ambient","Effects"}
	local menu = parent:submenu(selected.name,selected.description)
	while menu:active() do
		for v = 1,4 do
			if menu:option(volume[v],"["..math.floor(GetVolumeSetting(v)*100).."%]") then
				O_AdjustVolume(menu,v)
			end
		end
		menu:draw()
		Wait(0)
	end
end
function O_AdjustVolume(menu,v)
	local backup = GetVolumeSetting(v)
	local value = math.floor(backup*100)
	while menu:active() do
		menu:draw("> "..value.."% <")
		Wait(0)
		if menu:up() then
			value = value + 5
			if value > 200 then
				value = 200
			end
			F_UpdateVolume(v,value/100)
		elseif menu:down() then
			value = value - 5
			if value < 0 then
				value = 0
			end
			F_UpdateVolume(v,value/100)
		elseif menu:left() then
			break
		elseif menu:right() then
			return
		end
	end
	F_UpdateVolume(v,backup)
end
function F_UpdateVolume(v,value)
	if v == 2 then
		SetVolumeSetting(0,value) -- Speech also sets Cutscene
	elseif v == 4 then
		--SetVolumeSetting(3,value) -- Effects also sets Ambient
		SetVolumeSetting(5,value) -- Effects also sets Unknown
	end
	return SetVolumeSetting(v,value)
end
