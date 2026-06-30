RegisterLocalizedText("RACING_BLIP",40)
LoadScript("races.lua")

local gAdmin = false
local gRequesting = false
local gPlaying

RegisterNetworkEventHandler("races:SetAdmin",function()
	gAdmin = true
end)
RegisterNetworkEventHandler("races:AllowRequest",function()
	gRequesting = false
end)
RegisterNetworkEventHandler("races:SetRace",function(index,spawn)
	if gPlaying then
		TerminateScript(gPlaying)
	end
	if index then
		gPlaying = StartScript("cl_race.lua")
		if gPlaying then
			local env = GetScriptEnvironment(gPlaying)
			local race = RACES[index]
			env.gSpawn = race.spawns[spawn]
			env.gRace = race
		end
	else
		gPlaying = nil
	end
end)
RegisterLocalEventHandler("f2menu:Open",function(f_add)
	if gAdmin then
		f_add({
			name = "Race Warps",
			description = "(admin only)\nWarp to race blips.",
			thread = M_Warps,
		})
	end
end)

function main()
	SendNetworkEvent("races:InitScript")
	while true do
		local nearest
		if not gPlaying and dsl.activity and not dsl.activity.IsPlaying() then
			local distance = 1
			local a1 = AreaGetVisible()
			local x1,y1,z1 = PlayerGetPosXYZ()
			for i,b in ipairs(RACES) do
				local x2,y2,z2 = unpack(b.blip)
				local dx,dy,dz = x2-x1,y2-y1,z2-z1
				local dist = dx*dx+dy*dy+dz*dz
				if b.area == a1 and dist < 30*30 and F_Available(b) and PlayerIsInAreaXYZ(x2,y2,z2,1,1) and dsl.activity.CanStart() and dist < distance then
					nearest,distance = i,dist
				end
			end
		end
		if nearest and not gRequesting then
			if IsButtonBeingPressed(9,0) and PedMePlaying(gPlayer,"DEFAULT_KEY",true) then
				SendNetworkEvent("races:StartRace",nearest)
				SoundPlay2D("RightBtn")
				gRequesting = true
			else
				ReplaceLocalizedText("RACING_BLIP","~GRAPPLE~ "..RACES[nearest].name)
				TextPrint("RACING_BLIP",0.1,3)
			end
		end
		Wait(0)
	end
end
function F_Available(race)
	local hour,minute = ClockGet()
	local open = race.start_time[1] * 60 + race.start_time[2]
	local close = race.end_time[1] * 60 + race.end_time[2]
	minute = hour * 60 + minute
	if open > close then
		return minute >= open or minute < close
	end
	return minute >= open and minute < close
end
function M_Warps(parent,selected)
	local menu = parent:submenu(selected.name)
	local races = F_Sort()
	local sorted = true
	menu.draw_style.menu_w_min = 0.95
	menu.draw_style.menu_w_max = 0.95
	while menu:active() do
		if menu:option("Race Sorting",sorted and "[ALPHABETICAL]" or "[SCRIPT]","Decide how races here should be organized.") then
			sorted = not sorted
			if sorted then
				races = F_Sort()
			else
				races = RACES
			end
		end
		for _,v in ipairs(races) do
			if menu:option(v.name,F_When(v),v.description) and not AreaIsLoading() then
				local x,y,z = unpack(v.blip)
				PlayerSetPosXYZArea(x,y,z,v.area)
				while AreaIsLoading() do
					menu:draw("[WARPING]")
					Wait(0)
				end
				for i,x in ipairs(RACES) do
					if x == v then
						SendNetworkEvent("races:ForceTime",i)
						break
					end
				end
			end
		end
		menu:draw()
		Wait(0)
	end
end
function F_Sort()
	local races = {}
	for _,v in ipairs(RACES) do
		table.insert(races,v)
	end
	table.sort(races,function(a,b)
		return string.lower(a.name) < string.lower(b.name)
	end)
	return races
end
function F_When(v)
	local open = v.start_time[1] * 60 + v.start_time[2]
	local close = v.end_time[1] * 60 + v.end_time[2]
	return "["..F_Time(open).." - "..F_Time(close).."]"
end
function F_Time(minutes)
	local h,m = math.floor(minutes/60),math.mod(minutes,60)
	if h >= 12 then
		if h >= 13 then
			h = h - 12
		end
		return string.format("%d:%.2d PM",h,m)
	end
	return string.format("%d:%.2d AM",h,m)
end
