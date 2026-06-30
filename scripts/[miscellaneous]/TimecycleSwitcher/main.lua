-- timecycle switcher  --
--        - derpy54320 --

require("utility/timecycle")

-- setup
function MissionSetup()
	gSelection = 0 -- gets changed in RefreshOptions
	RefreshOptions()
end
function RefreshOptions()
	local cfg = GetScriptConfig()
	gOptions = {
		{
			name = "default",
			priority = 0,
			scale = 0,
		},
	}
	if GetConfigBoolean(cfg,"include_ps2") then
		table.insert(gOptions,{
			name = "PS2",
			dats = LoadTimecycleDATS("DEFAULT/TIMECYC?.DAT"),
			priority = 0,
			scale = 0,
		})
	end
	if GetConfigBoolean(cfg,"include_pcsb") then
		table.insert(gOptions,{
			name = "SB",
			dats = LoadTimecycleDATS("DEFAULT/sbtimecyc?.dat"),
			priority = 0,
			scale = 0,
		})
	end
	for path in FindFiles("CUSTOM/*") do
		if path.directory then
			for _,v in ipairs({"TIMECYC?.dat","SBTIMECYC?.dat"}) do
				local files = "CUSTOM/"..path.name.."/"..v
				if FindFile(files) then
					table.insert(gOptions,{
						name = path.name,
						dats = LoadTimecycleDATS(files),
						priority = 1,
						scale = 0,
					})
				end
			end
		end
	end
	table.sort(gOptions,function(a,b)
		if a.priority ~= b.priority then
			return a.priority < b.priority
		end
		return string.upper(a.name) < string.upper(b.name)
	end)
	if gSelection == 0 then
		local default = GetPersistentDataTable("derpy54320").tc_switcher
		gSelection = 1
		if type(default) == "string" then
			default = string.lower(default)
			for i,v in ipairs(gOptions) do
				if string.lower(v.name) == default then
					gSelection = i
				end
			end
		end
	elseif not gOptions[gSelection] then
		gSelection = table.getn(gOptions)
	end
end

-- cleanup
function MissionCleanup()
	RestoreTimecycles()
end

-- main
function main()
	local interacted
	local showing = 0
	local key = GetConfigString(GetScriptConfig(),"switch_key")
	if key and not IsKeyValid(key) then
		PrintWarning("invalid switch_key: "..key)
		key = nil
	end
	ApplyOption(gOptions[gSelection]) -- apply default
	while not SystemIsReady() do
		Wait(0)
	end
	while true do
		if key and IsKeyBeingPressed(key) then
			SoundPlay2D("ButtonDown")
			if interacted then
				gSelection = math.mod(gSelection,table.getn(gOptions)) + 1
				ApplyOption(gOptions[gSelection])
				SaveOption(gOptions[gSelection])
			end
			interacted = GetTimer()
		elseif interacted and GetTimer() - interacted >= 3000 then
			interacted = nil
		end
		if interacted then
			showing = math.min(1,showing+GetFrameTime()/0.1)
		elseif showing ~= 0 then
			showing = math.max(0,showing-GetFrameTime()/0.1)
		end
		ScaleOptions(gOptions,gSelection)
		if showing ~= 0 then
			DrawOptions(gOptions,gSelection,showing)
		end
		Wait(0)
	end
end
function ApplyOption(option)
	RestoreTimecycles()
	if option.dats then
		ApplyTimecycleDATS(option.dats)
	end
	RunLocalEvent("TimecycleSwitcher:Apply",option.name)
end
function SaveOption(option)
	local data = GetPersistentDataTable("derpy54320") -- .tc_switcher = "name"
	if data.tc_switcher ~= option then
		if option.dats then
			data.tc_switcher = option.name
		else
			data.tc_switcher = nil
		end
		SavePersistentDataTables()
	end
end

-- drawing
function ScaleOptions(options,selected)
	for i,v in ipairs(options) do
		if i == selected then
			v.scale = math.min(1,v.scale+GetFrameTime()/0.1)
		elseif v.scale ~= 0 then
			v.scale = math.max(0,v.scale-GetFrameTime()/0.2)
		end
	end
end
function DrawOptions(options,selected,showing)
	local space = 0.2 / GetDisplayAspectRatio()
	local offset = (table.getn(options) - 1) / 2
	local y = 0.03 * (-1 + 2 * showing)
	for i,v in ipairs(options) do
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(210,210,210,255)
		SetTextOutline()
		SetTextAlign("C","C")
		SetTextPosition(0.5+((i-1)-offset)*space,y)
		SetTextScale(1+v.scale)
		DrawText("["..v.name.."]")
	end
end
