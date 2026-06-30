LoadScript("crosshairs.lua")

BACKGROUND_ASPECT = 16 / 9 -- background is resized to cover screen
LAYOUT_ASPECT = 16 / 9 -- layout is resized to fit screen
CROSSHAIR_COUNT = table.getn(CROSSHAIR_SIZES)
CROSSHAIR_SIZE = 128
MAP_WIDTH = 640 -- size of individual images in maps.png
MAP_HEIGHT = 360

RAT_CLASSES = {"RAT","JUNKIE","SPEEDY","FAT","FOCUSED","BLOODTHIRSTY"}
CLASS_DESCRIPTIONS = {
	JUNKIE = {"3x adrenaline duration","without adrenaline: -15% handling speed, -20% recoil control"},
	SPEEDY = {"+25% handling speed","-20% max health"},
	FAT = {"+25% max health","-40% handling speed"},
	FOCUSED = {"while aiming: +30% recoil control, +10% weapon zoom","-10% handling speed"},
	BLOODTHIRSTY = {"+15% health recovery from kills","-10% max health"},
}

gFrame = {0,0,1,1}
gOptions = {}
gButtonsNow = {}
gButtonsLast = {}

gReady = false -- if we're ready to play
gVoteReady = false -- if set, gVoteMaps will be set
gVoteMap = 0 -- what map we voted for (or 0)
gMapImages = CopyTexture(CreateTexture("images/maps.png"),"D3DFMT_DXT5")

gReadyCountdown = -1
gPlayerReady = {}
gPlayerNames = {}
gPlayerList = {}

gClassOption = {}

-- disable stuff
RegisterLocalEventHandler("ControllerUpdating",function(c)
	if c == 0 then
		for b,v in pairs(gButtonsNow) do
			gButtonsLast[b] = v
		end
		if IsUsingJoystick(0) then
			for b = 0,15 do
				gButtonsNow[b] = IsButtonPressed(b,0)
			end
		else
			gButtonsNow[0] = IsKeyBeingPressed("LEFT",0) or IsKeyBeingPressed("A",0)
			gButtonsNow[1] = IsKeyBeingPressed("RIGHT",0) or IsKeyBeingPressed("D",0)
			gButtonsNow[2] = IsKeyBeingPressed("UP",0) or IsKeyBeingPressed("W",0)
			gButtonsNow[3] = IsKeyBeingPressed("DOWN",0) or IsKeyBeingPressed("S",0)
			gButtonsNow[4] = false
			gButtonsNow[5] = false
			gButtonsNow[6] = false
			gButtonsNow[7] = IsKeyBeingPressed("RETURN",0) or IsKeyBeingPressed("LSHIFT",0)
			gButtonsNow[8] = IsKeyBeingPressed("ESCAPE",0) or IsKeyBeingPressed("SPACE",0)
			gButtonsNow[9] = false
			gButtonsNow[10] = false
			gButtonsNow[11] = false
			gButtonsNow[12] = false
			gButtonsNow[13] = false
			gButtonsNow[14] = false
			gButtonsNow[15] = false
		end
		ZeroController(0)
	end
end)
RegisterLocalEventHandler("ControllersUpdated",function()
	ZeroController(0)
end)
RegisterLocalEventHandler("chat:StartTyping",function()
	return true
end)
RegisterLocalEventHandler("chat:UpdateDisplay",function()
	return true
end)
RegisterLocalEventHandler("f2menu:Open",function()
	return true
end)

-- network events
RegisterNetworkEventHandler("rat_wars:SetClass",function(class)
	gClassOption[1] = F_GetClassName(class)
	gRatClass = class
end)
RegisterNetworkEventHandler("rat_wars:PlayerList",function(id,name,color,kills)
	if not name then
		gPlayerNames[id] = nil
	elseif dsl.role_colors then
		gPlayerNames[id] = {id,name,F_GetKillString(kills),dsl.role_colors.GetColorFromIndex(color)}
	else
		gPlayerNames[id] = {id,name,F_GetKillString(kills),230,230,230}
	end
	gPlayerReady[id] = nil
	gPlayerList = {}
	for _,v in pairs(gPlayerNames) do
		table.insert(gPlayerList,v)
	end
	table.sort(gPlayerList,function(a,b)
		return string.lower(a[1]) < string.lower(b[1])
	end)
	gPlayerList.n = table.getn(gPlayerList)
end)
RegisterNetworkEventHandler("rat_wars:PlayerReady",function(id,ready)
	gPlayerReady[id] = ready
end)
RegisterNetworkEventHandler("rat_wars:ReadyTimer",function(duration)
	if duration then
		gReadyCountdown = duration
		gReadyStarted = GetSyncTimer()
	else
		gReadyCountdown = -1
		gReadyStarted = nil
	end
end)
RegisterNetworkEventHandler("rat_wars:VoteMaps",function(maps)
	gVoteReady = true
	gVoteMaps = {}
	for i,v in ipairs(maps) do
		gVoteMaps[i] = {uv = {F_GetMapUV(v[1]-1)},votes = v[2]}
	end
end)

-- controls utility
function F_IsControlBeingPressed(button)
	return gButtonsNow[button] and not gButtonsLast[button]
end
function F_IsControlPressed(button)
	return gButtonsNow[button]
end

-- setup / cleanup
function MissionSetup()
	if dsl.first_person and dsl.first_person.IsActive() then
		dsl.first_person.Stop()
	end
	if dsl.f2menu and dsl.f2menu.IsOpen() then
		dsl.f2menu.Close()
	end
	if dsl.nametags then
		dsl.nametags.SetHidden(true)
	end
	if dsl.radar then
		dsl.radar.DisableRadar(true)
	end
	if dsl.chat then
		dsl.chat.Hide()
	end
end
function MissionCleanup()
	if dsl.nametags then
		dsl.nametags.SetHidden(false)
	end
	if dsl.radar then
		dsl.radar.DisableRadar(false)
	end
end

-- main
function main()
	local background = F_GetLobbyImage()
	local index = 1 -- option index
	local map = 1
	gClassOption = {F_GetClassName(gRatClass),CB_RatClass}
	table.insert(gOptions,{"READY UP",CB_ReadyUp,gReady})
	table.insert(gOptions,gClassOption)
	table.insert(gOptions,{""})
	table.insert(gOptions,{"HOLD TO AIM",CB_HoldToAim,gSettings.aiming})
	table.insert(gOptions,{"CONTROLLER ASSIST",CB_ControllerAssist,gSettings.assist})
	table.insert(gOptions,{"CENTER DOT",CB_CenterDot,gSettings.crosshair,CROSSHAIR_COUNT})
	table.insert(gOptions,{"CHANGE COLOR",CB_DotColor})
	table.insert(gOptions,{""})
	table.insert(gOptions,{"LEAVE GAME",CB_LeaveGame})
	F_UpdateCrosshairUV(gSettings.crosshair)
	while true do
		gOptions[1][1] = F_GetReadyUpText()
		gFrame = {F_GetCenterFrame(LAYOUT_ASPECT)}
		F_DrawBackground(background,BACKGROUND_ASPECT)
		F_DrawOptions(index)
		if gOptions[index] == gClassOption then
			F_DrawClass(gRatClass)
		end
		if gVoteReady then
			if gOptions[index] then
				F_DrawMaps(0)
			else
				F_DrawMaps(map)
			end
		end
		F_DrawPlayers()
		Wait(0)
		if F_IsControlBeingPressed(2) then
			repeat
				index = index - 1
				if index < 1 then
					index = table.getn(gOptions)
					if gVoteReady then
						index = index + 1
					end
				end
			until not gOptions[index] or gOptions[index][1] ~= ""
			SoundPlay2D("NavUp")
		elseif F_IsControlBeingPressed(3) then
			repeat
				index = index + 1
				if not gOptions[index] and (not gVoteReady or not gOptions[index-1]) then
					index = 1
				end
			until not gOptions[index] or gOptions[index][1] ~= ""
			SoundPlay2D("NavUp")
		elseif F_IsControlBeingPressed(0) then
			if gVoteReady and not gOptions[index] then
				map = map - 1
				if map < 1 then
					map = table.getn(gVoteMaps)
				end
				SoundPlay2D("NavUp")
			end
		elseif F_IsControlBeingPressed(1) then
			if gVoteReady and not gOptions[index] then
				map = map + 1
				if not gVoteMaps[map] then
					map = 1
				end
				SoundPlay2D("NavUp")
			end
		elseif F_IsControlBeingPressed(7) then
			local option = gOptions[index]
			if option then
				if option[3] ~= nil then
					if type(option[3]) ~= "number" then
						option[3] = not option[3]
					elseif option[3] < option[4] then
						option[3] = option[3] + 1
					else
						option[3] = 0
					end
				end
				if option[2] then
					option[2](option[3])
				end
			elseif gVoteMap ~= map then
				SendNetworkEvent("rat_wars:VoteMap",map)
				gVoteMap = map
			end
			SoundPlay2D("ButtonDown")
		end
	end
end
function F_DrawBackground(background,aspect)
	local w,h = GetDisplayResolution()
	if w / h < aspect then
		w = ((h - w / aspect) * aspect) / w
		DrawTexture(background,-w*0.5,0,w+1,1,255,255,255,255)
	elseif w / h > aspect then
		h = ((w - h * aspect) / aspect) / h
		DrawTexture(background,0,-h*0.5,1,h+1,255,255,255,255)
	else
		DrawTexture(background,0,0,1,1,255,255,255,255)
	end
end
function F_DrawOptions(index)
	local x,y = 0.15/LAYOUT_ASPECT,0.1
	for i,v in ipairs(gOptions) do
		if v[3] ~= nil then
			local size = 0.0025
			local x,y,w,h = x,y+0.0125+(i-1)*0.047,0.04/LAYOUT_ASPECT,0.04
			if v[3] then
				local size = 0.01
				local x,y,w,h = x+(size*0.5)/LAYOUT_ASPECT,y+size*0.5,w-size/LAYOUT_ASPECT,h-size
				if type(v[3]) ~= "number" then
					F_DrawRectangle(x,y,w,h,255,200,50,255)
				elseif v[3] > 0 then
					local rgb = CROSSHAIR_COLORS[gSettings.crosshair_color]
					if rgb then
						local r,g,b = unpack(rgb)
						local size = CROSSHAIR_PREVIEWS[gSettings.crosshair]
						if size then
							x,y,w,h = x-w*((size-1)*0.5),y-h*((size-1)*0.5),w*size,h*size
						end
						F_DrawTexture(gCrosshairs,x,y,w,h,r,g,b,255)
					end
				end
			end
			F_DrawRectangle(x,y,w,size,230,230,230,255) -- top
			F_DrawRectangle(x,y+h-size,w,size,230,230,230,255) -- bottom
			F_DrawRectangle(x,y+size,size/LAYOUT_ASPECT,h-size*2,230,230,230,255) -- left
			F_DrawRectangle(x+w-size/LAYOUT_ASPECT,y+size,size/LAYOUT_ASPECT,h-size*2,230,230,230,255) -- right
		end
		SetTextFont("Palatino")
		if i == index then
			SetTextBold()
			SetTextColor(255,200,50,255)
		else
			SetTextColor(230,230,230,255)
		end
		SetTextShadow()
		SetTextAlign("L","T")
		SetTextHeight(F_GetHeight(0.045))
		SetTextPosition(F_GetPosition(x+0.045/LAYOUT_ASPECT,y+(i-1)*0.047))
		DrawText(v[1])
	end
end
function F_DrawClass(class)
	local description = CLASS_DESCRIPTIONS[class]
	if description then
		local height = F_GetHeight(0.02)
		for i,v in ipairs(description) do
			SetTextFont("Georgia")
			SetTextBold()
			if i == 1 then
				SetTextColor(50,230,50,255)
			else
				SetTextColor(230,50,50,255)
			end
			SetTextShadow()
			SetTextAlign("L","T")
			SetTextHeight(height)
			SetTextPosition(F_GetPosition(0.5/LAYOUT_ASPECT,0.21+height*(i-1)))
			DrawText(v)
		end
	end
end
function F_DrawMaps(map)
	local size = 0.005
	local height = 0.2
	local width = height * ((MAP_WIDTH / MAP_HEIGHT) / LAYOUT_ASPECT)
	local x,y = 0.15/LAYOUT_ASPECT,0.9-height
	local count = 0
	for _,v in ipairs(gVoteMaps) do
		count = math.max(count,v.votes)
	end
	for i,v in ipairs(gVoteMaps) do
		local x,y,w,h = x+(i-1)*width*1.02,y,width,height
		if i == map then
			F_DrawRectangle(x,y,w,h,255,200,50,255)
		else
			F_DrawRectangle(x,y,w,h,230,230,230,255)
		end
		SetTextureBounds(gMapImages,unpack(v.uv))
		F_DrawTexture(gMapImages,x+(size*0.5)/LAYOUT_ASPECT,y+size*0.5,w-size/LAYOUT_ASPECT,h-size,255,255,255,255)
		if gVoteMap == i then
			local size = 0.02
			F_DrawRectangle(x+0.005/LAYOUT_ASPECT,y+h-(size+0.005),size/LAYOUT_ASPECT,size,250,200,50,255)
		end
		SetTextFont("Georgia")
		SetTextBold()
		if v.votes == count then
			SetTextColor(250,200,50,255)
		else
			SetTextColor(230,230,230,255)
		end
		SetTextShadow()
		SetTextAlign("R","B")
		SetTextHeight(F_GetHeight(0.02))
		SetTextPosition(F_GetPosition(x+w-0.008/LAYOUT_ASPECT,y+h-0.008))
		DrawText("Votes: "..v.votes)
	end
end
function F_DrawPlayers()
	local padding = 0.005
	local space = 0.002
	local width = 0.45 / LAYOUT_ASPECT
	local height = 0.035 * (1 - 0.4 * math.min(1,gPlayerList.n/32))
	local x,y = 1-0.15/LAYOUT_ASPECT,0.1
	SetTextFont("Palatino")
	SetTextBold()
	SetTextColor(230,230,230,255)
	SetTextShadow()
	SetTextAlign("R","T")
	SetTextHeight(F_GetHeight(0.045))
	SetTextPosition(F_GetPosition(x,y))
	DrawText("PLAYERS ("..gPlayerList.n..")")
	y = y + 0.065
	for i,v in ipairs(gPlayerList) do
		if gPlayerReady[v[1]] then
			local padding = 0.012
			F_DrawRectangle(x+(space+padding*0.5)/LAYOUT_ASPECT,y+(i-1)*(height+space)+padding*0.5,(height-padding)/LAYOUT_ASPECT,height-padding,255,200,50,255)
		end
		F_DrawRectangle(x-width,y+(i-1)*(height+space),width,height,0,0,0,100)
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(v[4],v[5],v[6],255)
		SetTextAlign("R","B")
		SetTextHeight(F_GetHeight(height-padding*2))
		SetTextPosition(F_GetPosition(x-padding/LAYOUT_ASPECT,y+padding+height*0.75+(i-1)*(height+space)))
		SetTextClipping(width*0.78-(padding*2)/LAYOUT_ASPECT)
		DrawText(v[2])
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(200,200,200,255)
		SetTextAlign("L","B")
		if gPlayerList.n >= 12 or string.len(v[3]) < 6 then
			SetTextHeight(F_GetHeight(height*0.9-padding*2))
		else
			SetTextHeight(F_GetHeight(height*0.75-padding*2))
		end
		SetTextPosition(F_GetPosition(x-width+padding/LAYOUT_ASPECT,y+padding+height*0.75+(i-1)*(height+space)))
		SetTextClipping(width*0.22-(padding*2)/LAYOUT_ASPECT)
		DrawText("["..v[3].."]")
	end
end

-- options
function CB_ReadyUp(ready)
	if ready then
		SendNetworkEvent("rat_wars:ReadyUp",true)
	else
		SendNetworkEvent("rat_wars:ReadyUp")
	end
end
function CB_RatClass()
	for i,v in ipairs(RAT_CLASSES) do
		if v == gRatClass then
			SendNetworkEvent("rat_wars:ChangeClass",RAT_CLASSES[i+1] or RAT_CLASSES[1])
			return
		end
	end
end
function CB_ControllerAssist(assist)
	gSettings.assist = assist
	SavePersistentDataTables()
end
function CB_CenterDot(index)
	gSettings.crosshair = index
	F_UpdateCrosshairUV(index)
	SavePersistentDataTables()
end
function CB_DotColor()
	gSettings.crosshair_color = math.mod(gSettings.crosshair_color,table.getn(CROSSHAIR_COLORS)) + 1
end
function CB_HoldToAim(aiming)
	gSettings.aiming = aiming
	SavePersistentDataTables()
end
function CB_LeaveGame()
	SendNetworkEvent("rat_wars:LeaveLobby")
end

-- utility
function F_GetClassName(class)
	local index = 0
	for i,v in ipairs(RAT_CLASSES) do
		if v == class then
			index = i
			break
		end
	end
	if class == "RAT" then
		return "STANDARD RAT ["..index.." / "..table.getn(RAT_CLASSES).."]"
	end
	return class.." RAT ["..index.." / "..table.getn(RAT_CLASSES).."]"
end
function F_DrawRectangle(x,y,w,h,r,g,b,a)
	local fx,fy,fw,fh = unpack(gFrame)
	return DrawRectangle(fx+fw*x,fy+fh*y,fw*w,fh*h,r,g,b,a)
end
function F_DrawTexture(texture,x,y,w,h,r,g,b,a)
	local fx,fy,fw,fh = unpack(gFrame)
	return DrawTexture(texture,fx+fw*x,fy+fh*y,fw*w,fh*h,r,g,b,a)
end
function F_GetPosition(x,y)
	local fx,fy,fw,fh = unpack(gFrame)
	return fx+fw*x,fy+fh*y
end
function F_GetHeight(h)
	return h * gFrame[4]
end
function F_GetCenterFrame(ar)
	local w,h = GetDisplayResolution()
	if w / h > ar then
		local extra = (w - h * ar) / w
		return extra*0.5,0,1-extra,1
	elseif w / h < ar then
		local extra = (h - w / ar) / h
		return 0,extra*0.5,1,1-extra
	end
	return 0,0,1,1
end
function F_GetLobbyImage()
	local screens = {}
	for name in AllConfigStrings(GetScriptConfig(),"client_file") do
		if string.find(name,"^images/lobby/") then
			table.insert(screens,name)
		end
	end
	return CopyTexture(CreateTexture(screens[math.random(table.getn(screens))]),"D3DFMT_DXT5")
end
function F_GetMapUV(index)
	local w,h = GetTextureResolution(gMapImages)
	local columns = math.floor(w/MAP_WIDTH)
	local rows = math.floor(h/MAP_HEIGHT)
	local x = math.mod(index,columns)
	local y = math.floor(index/columns)
	return x/columns,y/rows,(x+1)/columns,(y+1)/rows
end
function F_UpdateCrosshairUV(index)
	if index > 0 then
		local w,h = GetTextureResolution(gCrosshairs)
		local columns = math.floor(w/CROSSHAIR_SIZE)
		local rows = math.floor(h/CROSSHAIR_SIZE)
		local x = math.mod(index-1,columns)
		local y = math.floor((index-1)/columns)
		SetTextureBounds(gCrosshairs,x/columns,y/rows,(x+1)/columns,(y+1)/rows)
	end
end
function F_GetKillString(count)
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
function F_GetReadyUpText()
	if gReadyCountdown ~= -1 then
		local passed = GetSyncTimer() - gReadyStarted
		if passed < gReadyCountdown then
			local seconds = math.ceil((gReadyCountdown-passed)/1000)
			if seconds < 60 then
				return string.format("READY UP ("..seconds..")")
			end
			return string.format("READY UP (%d:%.2d)",math.floor(seconds/60),math.mod(seconds,60))
		end
		return "READY UP (0)"
	end
	return "READY UP"
end
