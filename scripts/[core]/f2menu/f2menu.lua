require("utility/menu")

local gOptions -- table of options, can stay set when inactive if no history
local gOrganized -- can only be set when gOptions is set *and* the menu is active
local gMainMenu -- main menu object if created
local gRunningSub -- currently running script and thread

local gMenuOrder
local gMenuCategorized = {}
local gMenuHistory = {}

local gDescriptions = {} -- {[name] = description} for categories

local gCustomStyles = {} -- styles.lua

local gReplacePause = false
local gForcePause = false
local gPauseLast = false
local gPauseNow = false

StartScript("styles.lua",setmetatable({styles = gCustomStyles},{__index = _G}))

-- Main.
function main()
	local key = GetConfigString(GetScriptConfig(),"menu_key")
	gReplacePause = GetConfigBoolean(GetScriptConfig(),"menu_replace_pause",false)
	if not IsKeyValid(key) then
		PrintWarning("invalid key set in config")
		if not gReplacePause then
			StopCurrentScriptCollection()
			return
		end
	end
	F_LoadCategories()
	gMenuOrder = F_LoadOrder()
	while true do
		if (IsKeyBeingPressed(key) or (gPauseNow and not gPauseLast)) and (gOrganized or not (IsPauseMenuActive() or IsMapMenuActive())) then
			F_SetActive(not gOrganized)
		end
		if gOrganized and not (gRunningSub and IsThreadRunning(gRunningSub[2])) and not F_UpdateMenu(gMainMenu) then
			assert(gMenuHistory[1],"exited main menu")
			F_PopHistory()
			gMainMenu:draw()
		end
		Wait(0)
	end
end
function F_LoadCategories()
	for path in AllConfigStrings(GetScriptConfig(),"menu_order") do
		local name = path
		local slash = string.find(name,"/",1,true)
		while slash do
			name = string.sub(name,slash+1)
			slash = string.find(name,"/",1,true)
		end
		gMenuCategorized[string.lower(name)] = path -- Example = Test/Path/Example
	end
	for value in AllConfigStrings(GetScriptConfig(),"category_description") do
		local found,last,name = string.find(value,"(.-), ")
		if found then
			gDescriptions[name] = string.gsub(string.sub(value,last+1),"\\n","\n")
		end
	end
end
function F_LoadOrder(category)
	local order = {}
	local count = 1
	local name_start = 1
	if category then
		name_start = string.len(category) + 2
	end
	for name in AllConfigStrings(GetScriptConfig(),"menu_order") do
		if not category or string.find(name,category.."/",1,true) == 1 then
			name = string.sub(name,name_start)
			local slash = string.find(name,"/",1,true)
			if slash then
				name = string.sub(name,1,slash-1)
			end
			order[string.lower(name)] = count
			count = count + 1
		end
	end
	order[1] = count
	return order
end
function F_SetActive(active)
	if active then
		local options = F_SetupOptions()
		if options then
			if not gMenuHistory[1] then
				gOptions = options -- history tables should never point to old options, so only refresh when no history
				gOrganized = F_SortOptions()
				if not gMainMenu then
					gMainMenu = F_SetupMenu()
				end
			else
				F_PopHistory()
			end
			SoundPlay2D("ButtonDown")
		end
	else
		if gMenuHistory[1] or (gRunningSub and IsThreadRunning(gRunningSub[2])) then
			F_PushHistory()
		else
			gOptions = nil -- options must stay if there's history for proper cleanup
		end
		gOrganized = nil
		RunLocalEvent("f2menu:Close")
		SoundPlay2D("ButtonDown")
	end
end
function F_SetupOptions()
	local options = {scripts = {}}
	local function f_add(option)
		if type(option) ~= "table" then
			typerror(1,"table")
		elseif not f_add then
			error("you can only add options during the f2menu:Open event",2)
		end
		options.scripts[option] = GetCurrentScript()
		table.insert(options,option)
	end
	if GetConfigBoolean(GetScriptConfig(),"menu_appearance") then
		f_add({name = "Menu Appearance",thread = M_StyleMenu,description = "Change the menu's appearance.",priority = -10})
	end
	if gReplacePause and GetConfigBoolean(GetScriptConfig(),"menu_allow_pause") then
		f_add({name = "Game Settings",func = O_PauseGame,description = "Access the normal pause menu.",priority = -11})
	end
	if not RunLocalEvent("f2menu:Open",f_add) then
		options = nil -- cancel
	end
	f_add = nil
	-- gOptions always contains *all* options, but gOrganized only contains root level ones
	return options
end
function F_SortOptions(category)
	local organized = {}
	local categories = {}
	local name_start = 1
	if category then
		name_start = string.len(category) + 2
	end
	for _,o in ipairs(gOptions) do
		local path = gMenuCategorized[string.lower(o.name)]
		if path then
			if not category or string.find(path,category.."/",1,true) == 1 then
				local name = string.sub(path,name_start)
				local slash = string.find(name,"/",1,true)
				if slash then
					name = string.sub(name,1,slash-1)
					if not categories[name] then
						slash = string.find(path,"/",name_start,true)
						if slash then
							path = string.sub(path,1,slash-1)
						end
						table.insert(organized,{path = path,name = name,func = O_BrowseCategory,description = gDescriptions[name]})
						categories[name] = true
					end
				else
					table.insert(organized,o) -- categorized option
				end
			end
		elseif not category then
			table.insert(organized,o) -- root level option
		end
	end
	table.sort(organized,function(a,b)
		local an = string.lower(tostring(a.name))
		local bn = string.lower(tostring(b.name))
		local ao = gMenuOrder[an] or gMenuOrder[1]
		local bo = gMenuOrder[bn] or gMenuOrder[1]
		local ap = a.priority
		local bp = b.priority
		if ao ~= bo then
			return ao < bo -- first sort by menu_order,
		end
		if ap ~= bp then
			if type(ap) ~= "number" then
				ap = 0
			end
			if type(bp) ~= "number" then
				bp = 0
			end
			return ap > bp -- then by priority,
		end
		return an < bn -- then by name.
	end)
	return organized
end
function F_SetupMenu()
	local menu = CreateMenu(GetConfigString(GetScriptConfig(),"menu_name"))
	local style = GetPersistentDataTable("Xx_Yubari_xX").f2menu_style
	local starts = {n = 0}
	if not style then
		style = GetConfigString(GetScriptConfig(),"menu_style")
	end
	if not menu:style(style) then
		local func = gCustomStyles[style]
		if func then
			menu.draw_style = func()
		end
	end
	for start in AllConfigStrings(GetScriptConfig(),"menu_start") do
		table.insert(starts,start)
	end
	if starts.n ~= 0 then
		menu:alert((string.gsub(starts[math.random(starts.n)],"\\n","\n")))
	end
	menu.can_exit = false
	return menu
end
function F_UpdateMenu(menu)
	if not menu:active() then
		return false
	end
	for _,o in ipairs(gOrganized) do
		if menu:option(o.name,o.right,o.description) then
			if type(o.func) == "function" then
				xpcall(function()
					local s = gOptions.scripts[o]
					if s then
						CallFunctionFromScript(s,o.func,menu,o)
					else
						o.func(menu,o)
					end
				end,PrintError)
				if gMainMenu ~= menu then
					return F_UpdateMenu(gMainMenu)
				end
			end
			if type(o.thread) == "function" then
				local s = gOptions.scripts[o]
				gRunningSub = {s,CallFunctionFromScript(s,CreateAdvancedThread,"PRE_GAME",T_RunThread,o.thread,menu,o)}
			end
			menu:draw()
			menu.update = false
			return true
		end
	end
	menu:draw()
	return true
end

-- Categories.
function F_PushHistory()
	table.insert(gMenuHistory,{gMainMenu,gMenuOrder,gOrganized})
end
function F_PopHistory()
	gMainMenu,gMenuOrder,gOrganized = unpack(table.remove(gMenuHistory))
end

-- Thread.
function T_RunThread(main,menu,option)
	local thread = coroutine.create(main)
	local status,message = coroutine.resume(thread,menu,option)
	while coroutine.status(thread) == "suspended" do
		Wait(GetThreadWait())
		while not gOrganized do -- wait while hidden
			Wait(0)
		end
		status,message = coroutine.resume(thread)
	end
	if not status then
		PrintError(message)
	end
	gRunningSub = nil
end

-- Cleanup.
RegisterLocalEventHandler("ScriptDestroyed",function(script)
	if gOptions then
		for o,s in pairs(gOptions.scripts) do
			if s == script then
				for _,h in ipairs(gMenuHistory) do
					F_RemoveOption(h[3],o) -- gOrganized from history
				end
				if gOrganized then
					F_RemoveOption(gOrganized,o)
				end
				F_RemoveOption(gOptions,o)
				gOptions.scripts[o] = nil
			end
		end
	end
end)
RegisterLocalEventHandler("ScriptShutdown",function(script)
	if script == GetCurrentScript() then
		if gRunningSub then
			TerminateThread(gRunningSub[2]) -- terminate thread running in other script
		end
		if gOrganized then
			RunLocalEvent("f2menu:Close")
		end
		RunLocalEvent("f2menu:Shutdown")
	end
end)
function F_RemoveOption(options,option)
	local i = 1
	while options[i] do
		if options[i] == option then
			table.remove(options,i)
		else
			i = i + 1
		end
	end
end

-- Pause.
RegisterLocalEventHandler("ControllerUpdating",function(c)
	if c == 0 then
		if gReplacePause then
			if gForcePause then
				SetButtonPressed(5,0,true)
				gForcePause = false
				gPauseLast = false
				gPauseNow = false
				return
			end
			gPauseLast = gPauseNow
			gPauseNow = IsButtonPressed(5,0)
		end
		if gPauseNow or gOrganized then
			SetButtonPressed(5,0,false) -- no pausing while f2menu is open or replacing pause button
		end
	end
end)

-- Disable Radar.
RegisterLocalEventHandler("radar:Open",function()
	if gOrganized then
		return true
	end
end)

-- Integrated Options.
function O_BrowseCategory(parent,option)
	F_PushHistory()
	gMainMenu = gMainMenu:submenu(option.name,option.description)
	gMenuOrder = F_LoadOrder(option.path)
	gOrganized = F_SortOptions(option.path)
end
function O_PauseGame()
	if gOrganized then
		F_SetActive(false)
	end
	gForcePause = true
end
function M_StyleMenu(parent,option)
	local menu = parent:submenu(option.name,option.description)
	local styles = {"default","alternate","opaque"}
	local custom = {}
	for name,func in pairs(gCustomStyles) do
		table.insert(custom,{name,func})
	end
	table.sort(custom,function(a,b)
		return string.lower(a[1]) < string.lower(b[1])
	end)
	while menu:active() do
		for _,v in ipairs(custom) do
			if menu:option(v[1]) then
				local ds = v[2]()
				F_SetStyle(v[1])
				for _,h in ipairs(gMenuHistory) do
					h[1].draw_style = ds
				end
				parent.draw_style = ds
				menu.draw_style = ds
			end
		end
		for _,v in ipairs(styles) do
			if menu:option(v) then
				F_SetStyle(v)
				for _,h in ipairs(gMenuHistory) do
					h[1]:style(v)
				end
				parent:style(v)
				menu:style(v)
			end
		end
		menu:draw()
		Wait(0)
	end
end
function F_SetStyle(v)
	if v == GetConfigString(GetScriptConfig(),"menu_style") then
		GetPersistentDataTable("Xx_Yubari_xX").f2menu_style = nil
	else
		GetPersistentDataTable("Xx_Yubari_xX").f2menu_style = v
	end
	SavePersistentDataTables()
end

-- Exported Functions.
function exports.IsOpen()
	return gOrganized ~= nil
end
function exports.Close()
	if gOrganized then
		F_SetActive(false)
	end
end
