RegisterLocalizedText("RW_BLIP",40)
LoadScript("blips.lua")
LoadScript("hints.lua")
LoadScript("maps.lua")

FADE_TIME = 650
LOAD_TIME = 2750

gSettings = GetPersistentDataTable("Xx_Yubari_xX") -- .rat_wars = {...}
if not gSettings.rat_wars then
	gSettings.rat_wars = {}
end
gSettings = gSettings.rat_wars
gSettings.assist = gSettings.assist ~= false -- aim assist
gSettings.crosshair = gSettings.crosshair or 0
gSettings.crosshair_color = gSettings.crosshair_color or 1
gSettings.aiming = gSettings.aiming ~= false -- hold to aim

gAdmin = false
gLobby = false -- if set, gScript is also set (the script will only ever be the lobby script or playing script)
gPlaying = false -- if set, gScript and gTimer and gMap will also be set
gOnline = 0 -- "online" player count
gLoading = -1 -- -4 fade asap, -3 wait for server, -2 quit asap, -1 not faded, >= 0 area code
gStats = false -- waiting for stats (admin only)
gMusic = "intro" -- current music to be playing
gPlayingMusic = false

-- network events
RegisterNetworkEventHandler("rat_wars:SetAdmin",function()
	if not gAdmin then
		SetCommand("rat_wars_stats",CB_ShowStats,false,"Usage: rat_wars_stats\nPrint various stats to the console.")
	end
	gAdmin = true
end)
RegisterNetworkEventHandler("rat_wars:SetLobby",function(class)
	if class then
		if gLobby or gPlaying then
			TerminateScript(gScript)
			gPlaying = false
			gTimer = nil
			gMap = nil
		end
		gScript = StartScript("cl_lobby.lua")
		if gScript then
			local env = GetScriptEnvironment(gScript)
			env.gRatClass = class
			env.gSettings = gSettings
			env.gMaps = gMaps
		end
		gLobby = true
	elseif gLobby then
		if gLoading ~= -1 then
			PlayerSetControl(1)
			CameraFade(0,1)
		end
		TerminateScript(gScript)
		gLobby = false
		gScript = nil
	end
end)
RegisterNetworkEventHandler("rat_wars:SetPlaying",function(mtimer,timer,map)
	if timer then
		if gLobby or gPlaying then
			TerminateScript(gScript)
			gLobby = false
		end
		gScript = StartScript("cl_ratwars.lua")
		if gScript then
			local env = GetScriptEnvironment(gScript)
			env.gLateJoin = mtimer - timer
			env.gSettings = gSettings
			env.gDuration = timer
			env.gMaps = gMaps
			env.gMap = map
		end
		gPlaying = true
		gTimer = GetSyncTimer()
		gMusic = "intro"
		gMap = map
	elseif gPlaying then
		TerminateScript(gScript)
		gPlaying = false
		gScript = nil
		gTimer = nil
		gMap = nil
	end
end)
RegisterNetworkEventHandler("rat_wars:UpdateOnline",function(online)
	gOnline = online
end)
RegisterNetworkEventHandler("rat_wars:StartLoading",function()
	if gLoading == -1 then
		gLoading = -4
	end
end)
RegisterNetworkEventHandler("rat_wars:FinishLoading",function(area)
	if gLoading == -3 then
		if area then
			gLoading = area
		else
			gLoading = -2
		end
	end
end)
RegisterNetworkEventHandler("rat_wars:DisplayResults",function()
	gMusic = "results"
end)
RegisterNetworkEventHandler("rat_wars:PrintStats",function(stats)
	if gStats then
		local sorted,totals = {},{}
		for id,info in pairs(stats) do
			local x = {id = id}
			for k,v in pairs(info) do
				totals[k] = (totals[k] or 0) + v
				x[k] = v
			end
			table.insert(sorted,x)
		end
		table.sort(sorted,function(a,b)
			return a.id < b.id
		end)
		for _,info in ipairs(sorted) do
			local stuff = {}
			for k,v in pairs(info) do
				if k ~= "id" then
					table.insert(stuff,k..": "..F_GetStatString(v))
				end
			end
			table.sort(stuff)
			PrintOutput("["..info.id.."] "..table.concat(stuff,", "))
		end
		sorted = {}
		for k,v in pairs(totals) do
			table.insert(sorted,k..": "..F_GetStatString(v))
		end
		table.sort(sorted)
		PrintOutput("[total] "..table.concat(sorted,", "))
		gStats = false
	end
end)

-- local events
RegisterLocalEventHandler("activity:WarpTo",function(id,warp)
	if id == "rat_wars" then
		local a1 = AreaGetVisible()
		for _,b in ipairs(gBlips) do
			if b[4] == a1 then
				warp.x,warp.y,warp.z,warp.area = unpack(b)
				return
			end
		end
		if a1 == 0 then
			local nearest,distance
			local x1,y1,z1 = PlayerGetPosXYZ()
			for _,b in ipairs(gBlips) do
				local x2,y2,z2 = unpack(b.outside)
				local dx,dy,dz = x2-x1,y2-y1,z2-z1
				local dist = dx*dx+dy*dy+dz*dz
				if not nearest or dist < distance then
					nearest,distance = b,dist
				end
			end
			warp.x,warp.y,warp.z,warp.area = unpack(nearest)
			return
		end
		warp.x,warp.y,warp.z,warp.area = unpack(gBlips[math.random(table.getn(gBlips))])
	end
end)
RegisterLocalEventHandler("activity:LoadIcon",function(name,f_set)
	if name == "rat_wars" then
		f_set(CopyTexture(CreateTexture("images/activity.png"),"D3DFMT_DXT5"))
	end
end)
RegisterLocalEventHandler("f2menu:Open",function(f_add)
	if gAdmin then
		f_add({
			name = "Rat Wars",
			description = "(admin only)\nRat Wars admin stuff.",
			thread = M_RatWars,
		})
	end
end)

-- stats
function CB_ShowStats()
	if gStats then
		PrintError("already waiting for stats")
		return
	end
	SendNetworkEvent("rat_wars:RequestStats")
	gStats = true
end
function F_GetStatString(count)
	local str = string.format("%d",math.abs(count))
	local length = string.len(str)
	if count < 0 then
		str = string.sub(str,2)
	end
	while length > 3 do
		str = string.sub(str,1,length-3)..","..string.sub(str,length-2)
		length = length - 3
	end
	if count < 0 then
		return "-"..str
	end
	return str
end

-- f2menu
function M_RatWars(parent,selected)
	local menu = parent:submenu(selected.name)
	while gAdmin and menu:active() do
		if not gPlaying then
			if gLobby then
				if menu:option("Leave Lobby") then
					SendNetworkEvent("rat_wars:LeaveLobby")
				end
			elseif menu:option("Join Game") then
				SendNetworkEvent("rat_wars:StartGame")
			elseif menu:option("Go To Blip") then
				SendNetworkEvent("rat_wars:WarpBlip")
			end
		elseif menu:option("Finish Game") then
			SendNetworkEvent("rat_wars:FinishGame")
		elseif menu:option("Set Weapon") then
			M_SetWeapon(menu)
		end
		menu:help("\"I WANT THAT RAT BASTARD DEAD\"\ngLobby: "..tostring(gLobby).."\ngPlaying: "..tostring(gPlaying).."\ngLoading: "..gLoading)
		menu:draw()
		Wait(0)
	end
end
function M_SetWeapon(parent)
	local weapons = {}
	local menu = parent:submenu("Set Weapon","Give yourself a rat weapon.")
	for id in pairs(GetScriptEnvironment(gScript).gWeapons) do
		table.insert(weapons,id)
	end
	table.sort(weapons,function(a,b)
		return string.lower(a) < string.lower(b)
	end)
	while gAdmin and menu:active() do
		if menu:option("< none >") then
			SendNetworkEvent("rat_wars:SetWeapon")
		end
		for _,id in ipairs(weapons) do
			if menu:option(id) then
				SendNetworkEvent("rat_wars:SetWeapon",id)
			end
		end
		menu:draw()
		Wait(0)
	end
end
function O_SetRecoil(menu)
	local typing = StartTyping()
	if typing then
		while menu:active() do
			if not IsTypingActive(typing) then
				if not WasTypingAborted(typing) then
					local mult = tonumber(GetTypingString(typing))
					if mult >= 0 and mult < 1 / 0 then
						return mult
					end
				end
				break
			end
			menu:draw("> x"..GetTypingString(typing,true).." <")
			Wait(0)
		end
	end
end

-- cleanup
function MissionCleanup()
	if gLoading ~= -1 then
		PlayerSetControl(1)
		CameraFade(0,1)
	end
	if gPlayingMusic then
		SoundStopInteractiveStream()
	end
end

-- main
function main()
	local loading_index
	local loading_timer
	local loading_image
	local loading_hint
	local music_thread
	SendNetworkEvent("rat_wars:InitScript")
	while true do
		local nearest
		if dsl.activity and not dsl.activity.IsPlaying() and not gLobby and not gPlaying and gLoading == -1 then
			local a1 = AreaGetVisible()
			local x1,y1,z1 = PlayerGetPosXYZ()
			for i,b in ipairs(gBlips) do
				local x2,y2,z2,a2 = unpack(b)
				local dx,dy,dz = x2-x1,y2-y1,z2-z1
				local dist = dx*dx+dy*dy+dz*dz
				if a2 == a1 and dist < 30*30 and PlayerIsInAreaXYZ(x2,y2,z2,1,1) and dsl.activity.CanStart() then
					nearest = i
				end
			end
		end
		if nearest then
			if gOnline > 0 then
				ReplaceLocalizedText("RW_BLIP","~GRAPPLE~ Play Rat Wars! ("..gOnline.." online)")
			else
				ReplaceLocalizedText("RW_BLIP","~GRAPPLE~ Play Rat Wars!")
			end
			TextPrint("RW_BLIP",0.1,3)
		end
		if gLobby or gPlaying then
			if not music_thread then
				music_thread = CreateThread("T_PlayMusic")
			end
		elseif music_thread then
			SoundStopInteractiveStream()
			TerminateThread(music_thread)
			gPlayingMusic = false
			music_thread = nil
		end
		Wait(0)
		if loading_image then
			local alpha
			if loading_timer then
				local passed = (GetTimer() - loading_timer) / FADE_TIME
				if loading_index then
					alpha = math.min(1,passed) * 255
				elseif passed < 1 then
					alpha = (1 - passed) * 255
				end
			else
				alpha = 255 -- waiting for camera unfade
			end
			if alpha then
				SetDrawLayer("POST_FADE")
				F_DrawLoadingScreen(loading_image,alpha,loading_hint,math.max(0,255-(255-alpha)*1.8))
			else
				loading_timer = nil
				loading_image = nil
			end
		end
		if loading_index then
			local passed = (GetTimer() - loading_timer) / LOAD_TIME
			if passed < 1 then
				local ar = GetDisplayAspectRatio()
				local width,height = 0.45/ar,0.05
				DrawRectangle(0.1/ar,0.9-height,width,height,0,0,0,255)
				DrawRectangle(0.1/ar,0.9-height,width*passed,height,255,0,50,255)
			else
				SendNetworkEvent("rat_wars:StartGame",loading_index)
				loading_index = nil
				loading_timer = nil
			end
		elseif gLoading == -4 then
			loading_index = nil
			loading_timer = nil
			if not loading_image then
				loading_image = CopyTexture(CreateTexture("images/loading.png"),"D3DFMT_DXT5")
				loading_hint = gHints[math.random(table.getn(gHints))]
			end
			CameraFade(FADE_TIME,0)
			PlayerSetControl(0)
			gLoading = -3
		elseif gLoading ~= -1 then
			if gLoading ~= -3 and not AreaIsLoading() and (gLoading == -2 or (AreaGetVisible() == gLoading and F_InMapRadius(gMaps[gMap]))) then
				loading_timer = GetTimer()
				CameraFade(FADE_TIME,1)
				PlayerSetControl(1)
				gLoading = -1
			end
		elseif not gLobby and not gPlaying and nearest and PedMePlaying(gPlayer,"DEFAULT_KEY",true) and IsButtonBeingPressed(9,0) then
			loading_index = nearest
			loading_timer = GetTimer()
			loading_image = CopyTexture(CreateTexture("images/loading.png"),"D3DFMT_DXT5")
			loading_hint = gHints[math.random(table.getn(gHints))]
			CameraFade(FADE_TIME,0)
			PlayerSetControl(0)
			gLoading = -3
		end
	end
end
function F_InMapRadius(map)
	local x1,y1,z1 = unpack(map.center)
	local x2,y2,z2 = PlayerGetPosXYZ()
	local dx,dy,dz = x2-x1,y2-y1,z2-z1
	local dist = map.radius - 1
	return dx*dx+dy*dy+dz*dz < dist*dist
end
function F_DrawLoadingScreen(image,ialpha,hint,halpha)
	local ar = GetDisplayAspectRatio()
	local padding = 0.005
	local offset = 0.02
	local height = 0.2
	local width = (height * 4) / ar
	local y = 1 - (offset + height)
	local x = 1 - (offset / ar + width)
	DrawTexture(image,0,0,1,1,255,255,255,ialpha)
	DrawRectangle(x,y,width,height,0,0,0,halpha*0.4)
	SetTextFont("Constantia")
	SetTextColor(230,230,230,halpha)
	SetTextShadow()
	SetTextScale(1.25)
	SetTextPosition(x+padding/ar,y+padding)
	SetTextAlign("L","T")
	SetTextWrapping(width-(padding*2)/ar)
	DrawText(hint)
end

-- music
function T_PlayMusic()
	local started,playing
	local gameplay = false
	while true do
		local music = "MS_BikeRace01"
		local map = gMaps[gMap]
		if gPlaying then
			if not gameplay and GetSyncTimer() - gTimer >= 15000 then
				if gMusic == "intro" then
					gMusic = "gameplay"
				end
				gameplay = true
			end
			music = map.music[gMusic]
		end
		if music ~= playing or (gPlaying and map.music_replay > 0 and GetTimer() - started >= math.floor(map.music_replay * 1000)) then
			SoundPlayInteractiveStreamLocked(music..".rsm",0.5,500,500)
			gPlayingMusic = true
			started = GetTimer()
			playing = music
		end
		Wait(0)
	end
end
