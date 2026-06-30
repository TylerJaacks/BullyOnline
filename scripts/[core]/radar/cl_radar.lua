local FADE_SECS = 0.15
local STAY_ON_MS = 500
local FULL_ALPHA = 0.9

local PAD_MOVE_SPEED = 4.0
local MOUSE_MOVE_SPEED = 0.0008

local PAD_ZOOM_SCALE = 40
local MOUSE_ZOOM_SCALE = 0.3

local MIN_ZOOM_LEVEL = 2
local MAX_ZOOM_LEVEL = 16
local DEFAULT_ZOOM_LEVEL = 8

local SHRINK_PLAYER_LIST = 16
local MAXIMUM_PLAYER_LIST = 32
local PLAYER_LIST_ALPHA = 0.9
local PLAYER_LIST_SIZE = 0.05
local PLAYER_LIST_OFF_X = 0
local PLAYER_LIST_OFF_Y = 0

local PANEL_SLIDE_SPEED = 5.5

local ROLE_COLOR_RATIO = 0.8 -- how much of the color of a player blip is determined by the role color [0.0, 1.0]

local gDisableRadar = {} -- {[script] = true} for scripts disabling radar
local gHidePeds = {} -- [sped] = {[script] = true} for peds that scripts want hidden

local gButtonPressed -- if the button is pressed, stays on slightly after releasing
local gPlayerNames = {}
local gPlayers = {}

local gRadarBounds = {-759.8806,839.3895,-838.8997,761.6238}
local gRadarPosition = {0.5,0.5,0,0,1,1,0} -- cx, cy, rx, ry, rw, rh, heading
local gRadarAlpha = 0
local gRadarAspect = 4/3
local gRadarOffset = {0,0}
local gRadarScale = DEFAULT_ZOOM_LEVEL

local gStayOpen = false -- keep gButtonPressed true until another distinct press
local gButtonDown = false -- used to track the actual button press
local gButtonLast = false

local gPanels = {[0] = {"MAP",0}} -- { [offset] = {name, hint [, script]} }
local gPanelNames = {MAP = 0}
local gPanelOffset = 0
local gPanelShown = 0
local gPanelMin = 0
local gPanelMax = 0

local gPanelButtonLeftLast = false
local gPanelButtonLeftNow = false
local gPanelButtonRightLast = false
local gPanelButtonRightNow = false

local gBackground = CreateTexture("textures/background.png")
local gBorder = CreateTexture("textures/border.png")
local gCenter = CreateTexture("textures/player.png")
local gList = {
	CreateTexture("textures/players_top_2.png"),
	CreateTexture("textures/players_middle_2.png"),
	CreateTexture("textures/players_bottom_2.png"),
	bg = {
		CreateTexture("textures/players_top_2_bg.png"),
		CreateTexture("textures/players_middle_2_bg.png"),
		CreateTexture("textures/players_bottom_2_bg.png"),
	}
}

-- pause detection
function F_IsPaused()
	return IsPauseMenuActive()-- or (dsl.f2menu and dsl.f2menu.IsOpen())
end

-- radar main
function main()
	local thread
	local target,tw,th
	local persist = GetPersistentDataTable("Xx_Yubari_xX") -- .radar = {...}
	local pressed = false
	if not persist.radar then
		persist.radar = {}
	end
	persist = persist.radar
	CreateThread("T_Panels")
	while true do
		if gButtonPressed then
			if not pressed and RunLocalEvent("radar:Open",exports.RegisterPanel) then
				pressed = true
			end
			if pressed then
				gRadarAlpha = math.min(1,gRadarAlpha+GetFrameTime()/FADE_SECS)
			end
		elseif gRadarAlpha ~= 0 then
			local unpaused = not F_IsPaused()
			if unpaused then
				gRadarAlpha = math.max(0,gRadarAlpha-GetFrameTime()/FADE_SECS)
			else
				gRadarAlpha = 0
			end
			if pressed and gRadarAlpha == 0 then
				if unpaused and F_GetPanelFocus() == 0 then
					if IsUsingJoystick(0) then
						if not persist.taught_controller then
							persist.taught_controller = true
							SavePersistentDataTables()
							CreateThread("T_ControllerTutorial",persist)
						end
					elseif not persist.taught_mouse then
						persist.taught_mouse = true
						SavePersistentDataTables()
						CreateThread("T_MouseTutorial",persist)
					end
				end
				pressed = false
			end
		end
		if gRadarAlpha ~= 0 then
			local alpha = F_GetPanelAlpha(0)
			if thread then
				TerminateThread(thread)
			end
			thread = CreateAdvancedThread("PRE_FADE",function()
				local dw,dh = GetDisplayResolution()
				if tw ~= dw or th ~= dh then
					target = nil
					target = CreateRenderTarget(dw,dh)
					tw,th = dw,dh
				end
				DrawBackBufferOntoTarget(target)
				F_DrawEverything(alpha*FULL_ALPHA)
				SetRendererAlphaBlending(false)
				F_DrawGameWorld(target)
				SetRendererAlphaBlending(true)
				F_DrawBorder(alpha)
				if gPlayerNames[1] then
					F_DrawPlayers(alpha)
				end
				DrawRectangle(-0.01,-0.01,1.01,0.01,0,0,0,255)
				DrawRectangle(-0.01,-0.01,0.01,1.01,0,0,0,255)
			end)
		elseif thread then
			thread = nil
			target,tw,th = nil,nil,nil
			gRadarAlpha = 0
			gRadarOffset = {0,0}
			gRadarScale = DEFAULT_ZOOM_LEVEL
			F_ResetDefaultPanel()
			gStayOpen = false
		end
		Wait(0)
	end
end
function F_DrawEverything(alpha)
	local ar = GetDisplayAspectRatio()
	local cp,cr,ch = CameraGetRotation()
	local px,py = PlayerGetPosXYZ()
	local rh = 0.7
	local rw = rh / ar
	ch = ch + math.pi
	F_SetRadarPosition((1-rw)*0.5,(1-rh)*0.5,rw,rh)
	if dsl.freecam and dsl.freecam.IsActive() then
		local cx,cy = dsl.freecam.GetPosition()
		F_SetRadarCenter(cx,cy,ch)
	else
		F_SetRadarCenter(px,py,ch)
	end
	if AreaGetVisible() == 0 then
		F_DrawRadar(alpha)
	else
		DrawRectangle(0,0,1,1,50,50,50,alpha*255)
	end
	if IsSyncActive() then
		for sped in AllSyncPeds() do
			if not gHidePeds[sped] then
				local name
				local r1,g1,b1 = 200,200,200 -- blip color
				local r2,g2,b2 = 255,255,255 -- text color
				local x,y,z,h = GetSyncEntityPos(sped)
				if PedFromSyncPed(sped) == gPlayer then
					name = GetPlayerName()
					r1,g1,b1 = 255,255,255
				end
				if dsl.nametags then
					if not name then
						name = dsl.nametags.GetPedName(sped)
					end
					r2,g2,b2 = dsl.nametags.GetPedColor(sped)
				end
				if name then
					r1,g1,b1 = r1+(r2-r1)*ROLE_COLOR_RATIO,g1+(g2-g1)*ROLE_COLOR_RATIO,b1+(b2-b1)*ROLE_COLOR_RATIO
					F_DrawMarker(gCenter,name,x,y,math.deg(ch-h),r1,g1,b1,r2,g2,b2,alpha*255)
				end
			end
		end
	else
		F_DrawMarker(gCenter,name,px,py,math.deg(ch-PedGetHeading(gPlayer)),255,255,255,255,255,255,alpha*255)
	end
end
function F_DrawGameWorld(target)
	local cx,cy,rx,ry,rw,rh = unpack(gRadarPosition)
	rx = rx - rw * ((gRadarAspect - 1) * 0.5)
	rw = rw * gRadarAspect
	F_DrawPartialScreen(target,0,0,1,ry)
	F_DrawPartialScreen(target,0,ry+rh,1,1-(ry+rh))
	F_DrawPartialScreen(target,0,0,rx,1)
	F_DrawPartialScreen(target,rx+rw,0,1-(rx+rw),1)
end
function F_DrawPartialScreen(target,x,y,w,h)
	SetTextureBounds(target,x,y,x+w,y+h)
	DrawTexture(target,x,y,w,h,255,255,255,255)
end
function F_DrawBorder(alpha)
	local cx,cy,rx,ry,rw,rh = unpack(gRadarPosition)
	local expand_w = 0.1 / GetDisplayAspectRatio()
	local expand_h = 0.07
	local offset_y = -0.005
	rx = rx - rw * ((gRadarAspect - 1) * 0.5)
	rw = rw * gRadarAspect
	DrawTexture(gBorder,rx-expand_w*0.5,ry+offset_y-expand_h*0.5,rw+expand_w,rh+expand_h,255,255,255,alpha*255)
end
function F_DrawPlayers(alpha)
	local cx,cy,rx,ry,rw,rh = unpack(gRadarPosition)
	local name_height = (gPlayerNames[SHRINK_PLAYER_LIST] and 0.3 or 0.4) * PLAYER_LIST_SIZE
	local name_padding = 0.06 * PLAYER_LIST_SIZE
	local height = table.getn(gPlayerNames) * (name_height + name_padding)
	local ar = GetTextureDisplayAspectRatio(gList[1])
	rx = rx - rw * ((gRadarAspect - 1) * 0.5)
	rw = rw * gRadarAspect
	rx = rx + rw + (0.3 * PLAYER_LIST_SIZE) / GetDisplayAspectRatio() + PLAYER_LIST_OFF_X
	ry = ry + rh * (3.8 * PLAYER_LIST_SIZE) + PLAYER_LIST_OFF_Y
	DrawTexture(gList.bg[1],rx,ry,PLAYER_LIST_SIZE*ar,PLAYER_LIST_SIZE,255,255,255,alpha*PLAYER_LIST_ALPHA*255)
	DrawTexture(gList.bg[2],rx,ry+PLAYER_LIST_SIZE,PLAYER_LIST_SIZE*ar,height,255,255,255,alpha*PLAYER_LIST_ALPHA*255)
	DrawTexture(gList.bg[3],rx,ry+PLAYER_LIST_SIZE+height,PLAYER_LIST_SIZE*ar,PLAYER_LIST_SIZE-name_padding,255,255,255,alpha*PLAYER_LIST_ALPHA*255)
	DrawTexture(gList[1],rx,ry,PLAYER_LIST_SIZE*ar,PLAYER_LIST_SIZE,255,255,255,alpha*255)
	DrawTexture(gList[2],rx,ry+PLAYER_LIST_SIZE,PLAYER_LIST_SIZE*ar,height,255,255,255,alpha*255)
	DrawTexture(gList[3],rx,ry+PLAYER_LIST_SIZE+height,PLAYER_LIST_SIZE*ar,PLAYER_LIST_SIZE-name_padding,255,255,255,alpha*255)
	for i,v in ipairs(gPlayerNames) do
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(v.rgb[1],v.rgb[2],v.rgb[3],alpha*255)
		SetTextAlign("L","T")
		SetTextPosition(rx+(0.84*PLAYER_LIST_SIZE)/GetDisplayAspectRatio(),ry+(0.96*PLAYER_LIST_SIZE)+(i-1)*(name_height+name_padding))
		SetTextHeight(name_height)
		SetTextClipping(PLAYER_LIST_SIZE*ar-(1.7*PLAYER_LIST_SIZE)/GetDisplayAspectRatio())
		DrawText(v.name)
	end
end

-- radar tutorial
function T_ControllerTutorial()
	TutorialShowString("Press ~SHOW_MAP~ to show the map, and use ~rstick~ to look around.",4000)
	Wait(4000)
	TutorialShowString("While the map is open, use ~MANUAL_LOCK~ / ~FIRE_WEAPON~ to zoom.",4000)
	Wait(4000)
	TutorialShowString("Switch panels using ~SCROLL_WEAPL~ / ~SCROLL_WEAPR~.",4000)
end
function T_MouseTutorial()
	local t,v = GetInputHardware(12,0)
	if t == "mouse_button" and v == 0 then
		TutorialShowString("Hold ~SHOW_MAP~ to show the map, and ~FIRE_WEAPON~ to drag.",4000)
	else
		TutorialShowString("Hold ~SHOW_MAP~ to show the map, and left mouse to drag.",4000)
	end
	Wait(4000)
	TutorialShowString("Switch panels using Q / E.",4000)
end

-- radar utility
function F_SetRadarPosition(x,y,w,h)
	gRadarPosition[3] = x
	gRadarPosition[4] = y
	gRadarPosition[5] = w
	gRadarPosition[6] = h
end
function F_SetRadarCenter(cx,cy,h)
	gRadarPosition[1] = (cx - gRadarBounds[1]) / (gRadarBounds[2] - gRadarBounds[1])
	gRadarPosition[2] = (cy - gRadarBounds[4]) / (gRadarBounds[3] - gRadarBounds[4])
	gRadarPosition[7] = h
end
function F_GetRadarOffset(x,y)
	local cx,cy,rx,ry,rw,rh,h = unpack(gRadarPosition)
	local px = (x - gRadarBounds[1]) / (gRadarBounds[2] - gRadarBounds[1])
	local py = (y - gRadarBounds[4]) / (gRadarBounds[3] - gRadarBounds[4])
	cx,cy = cx+gRadarOffset[1],cy+gRadarOffset[2]
	x,y = px-cx,py-cy
	return rx + rw * (cx + (x * math.cos(h) - y * math.sin(h)) * gRadarScale + (0.5 - cx)),
		ry + rh * (cy + (x * math.sin(h) + y * math.cos(h)) * gRadarScale + (0.5 - cy))
end

-- radar drawing
function F_DrawRadar(alpha)
	local grid = 20
	local cx,cy,rx,ry,rw,rh,h = unpack(gRadarPosition)
	cx,cy = cx+gRadarOffset[1],cy+gRadarOffset[2]
	if cx < 0 or cx > 1 then
		if cx < 0 then
			gRadarOffset[1] = gRadarOffset[1] + (0 - cx)
		else
			gRadarOffset[1] = gRadarOffset[1] - (cx - 1)
		end
		cx = gRadarPosition[1] + gRadarOffset[1]
	end
	if cy < 0 or cy > 1 then
		if cy < 0 then
			gRadarOffset[2] = gRadarOffset[2] + (0 - cy)
		else
			gRadarOffset[2] = gRadarOffset[2] - (cy - 1)
		end
		cy = gRadarPosition[2] + gRadarOffset[2]
	end
	for y = -10,29 do
		for x = -10,29 do
			local tx,ty,tsize = x/grid,y/grid,(1/grid)*gRadarScale
			local dx,dy = tx-cx,ty-cy
			local radar
			if x >= 0 and x < grid and y >= 0 and y < grid then
				radar = F_GetRadar(x+y*grid)
			end
			tx = cx + (dx * math.cos(h) - dy * math.sin(h)) * gRadarScale + (0.5 - cx)
			ty = cy + (dx * math.sin(h) + dy * math.cos(h)) * gRadarScale + (0.5 - cy)
			if radar then
				DrawTexture2(radar,rx+rw*tx,ry+rh*ty,rw*tsize,rh*tsize,math.deg(h),255,255,255,alpha*255)
			else
				DrawTexture2(gBackground,rx+rw*tx,ry+rh*ty,rw*tsize,rh*tsize,math.deg(h),50,50,50,alpha*255)
			end
		end
	end
end
function F_DrawMarker(texture,text,x,y,h,r1,g1,b1,r2,g2,b2,a)
	x,y = F_GetRadarOffset(x,y)
	if x > 0 and x < 1 and y > 0 and y < 1 then
		local size = 0.002 * gRadarScale
		DrawTexture2(texture,x,y,size*GetTextureDisplayAspectRatio(texture),size,h,r1,g1,b1,a)
		if text ~= nil then
			SetTextFont("Arial")
			SetTextBlack()
			SetTextColor(r2,g2,b2,a)
			SetTextHeight(0.01 * (1 + ((gRadarScale - MIN_ZOOM_LEVEL) / (MAX_ZOOM_LEVEL - MIN_ZOOM_LEVEL)) * 1.5))
			SetTextOutline()
			SetTextAlign("C","B")
			SetTextPosition(x,y-size*0.55)
			DrawText(text)
		end
	end
end

-- radar textures
function F_GetRadar(i)
	local textures = {}
	function F_GetRadar(i)
		if textures[i] == nil then
			local status,texture = pcall(CreateTexture,"textures/"..F_GetName(i)..".png")
			textures[i] = status and texture or false
		end
		return textures[i] or nil
	end
	return F_GetRadar(i)
end
function F_GetRadar(i) -- new
	local texture = CopyTexture(CreateTexture("textures/radar.png"),"D3DFMT_DXT5")
	local w,h = GetTextureResolution(texture)
	function F_GetRadar(i)
		local x = math.mod(i,20)
		local y = math.floor(i/20)
		if x >= 2 then
			x = (x - 2) / 18
			y = y / 20
			SetTextureBounds(texture,x,y,x+(1/18),y+(1/20))
			return texture
		end
	end
	return F_GetRadar(i)
end
function F_GetName(i)
	if i < 100 then
		return string.format("radar%02d",i)
	end
	return "radar"..i
end

-- radar exports
function exports.ShouldAllowMouse()
	return F_GetPanelAlpha(0) == 0
end
function exports.DisableRadar(yes)
	local script = GetCurrentScript()
	if type(yes) ~= "boolean" then
		typerror(1,"boolean")
	elseif yes then
		gButtonPressed = nil
		gStayOpen = false
	end
	gDisableRadar[script] = yes or nil
end
function exports.GetBorder()
	return gBorder
end
function exports.GetAlpha()
	return gRadarAlpha
end
function exports.IsActive()
	return gButtonPressed or gRadarAlpha ~= 0
end
function exports.Close()
	gButtonPressed = nil
	gStayOpen = false
end

-- panel system
function T_Panels()
	local thread
	while true do
		if gButtonPressed then
			if gPanelButtonLeftNow and not gPanelButtonLeftLast then
				F_SlideLeftPanel()
			elseif gPanelButtonRightNow and not gPanelButtonRightLast then
				F_SlideRightPanel()
			end
		end
		if gPanelShown < gPanelOffset then
			gPanelShown = gPanelShown + GetFrameTime() * PANEL_SLIDE_SPEED
			if gPanelShown > gPanelOffset then
				gPanelShown = gPanelOffset
			end
		elseif gPanelShown > gPanelOffset then
			gPanelShown = gPanelShown - GetFrameTime() * PANEL_SLIDE_SPEED
			if gPanelShown < gPanelOffset then
				gPanelShown = gPanelOffset
			end
		end
		if gRadarAlpha ~= 0 then
			if thread then
				TerminateThread(thread)
			end
			thread = CreateAdvancedThread("PRE_FADE",function()
				for offset = gPanelMin,gPanelMax do
					local alpha = 1 - math.min(1,math.abs(offset-gPanelShown)-1)
					if alpha > 0 then
						SetTextFont("Arial")
						SetTextBlack()
						SetTextColor(249,174,29,255*math.min(1,alpha)*gRadarAlpha)
						SetTextOutline()
						SetTextAlign("C","C")
						SetTextPosition(0.5+(offset-gPanelShown)*0.15,0.08)
						SetTextScale(1.5 - (math.abs(offset-gPanelShown)) * 0.7)
						DrawText(gPanels[offset][1])
					end
				end
			end)
		end
		Wait(0)
	end
end
function F_SlideLeftPanel()
	gStayOpen = true
	if gPanelOffset > gPanelMin then
		gPanelOffset = gPanelOffset - 1
		SoundPlay2D("ButtonDown")
	else
		SoundPlay2D("NavInvalid")
	end
end
function F_SlideRightPanel()
	gStayOpen = true
	if gPanelOffset < gPanelMax then
		gPanelOffset = gPanelOffset + 1
		SoundPlay2D("ButtonDown")
	else
		SoundPlay2D("NavInvalid")
	end
end
function F_ResetDefaultPanel()
	gPanelOffset = 0
	gPanelShown = 0
end
function F_GetPanelAlpha(offset)
	local mult = 1 - math.abs(offset - gPanelShown) * 2
	if mult > 0 then
		return mult * gRadarAlpha
	end
	return 0
end
function F_GetPanelFocus()
	local shown = math.abs(gPanelShown)
	if shown - math.floor(shown) < 0.5 then
		if gPanelShown < 0 then
			return math.ceil(gPanelShown)
		end
		return math.floor(gPanelShown)
	elseif gPanelShown < 0 then
		return math.floor(gPanelShown)
	end
	return math.ceil(gPanelShown)
end
function F_RegisterPanel(name,hint,script)
	local offset = 0
	local p = gPanels[gPanelNames[name]]
	if p then
		return p[2] == hint and p[3] == script
	end
	for _,p in pairs(gPanels) do
		if p[2] == hint then
			return false
		end
	end
	p = gPanels[offset]
	while p and math.abs(p[2]) < math.abs(hint) do
		if hint < 0 then
			offset = offset - 1 -- keep looking left for somewhere to insert
		else
			offset = offset + 1 -- or right
		end
		p = gPanels[offset]
	end
	if gPanels[offset] then
		if hint < 0 then
			for i = gPanelMin,offset do
				gPanels[i-1] = gPanels[i] -- slide panels left since we're inserting
			end
		else
			for i = gPanelMax,offset,-1 do
				gPanels[i+1] = gPanels[i] -- or right
			end
		end
	end
	if hint < 0 then
		gPanelMin = gPanelMin - 1 -- adjust limits
	else
		gPanelMax = gPanelMax + 1
	end
	gPanels[offset] = {name,hint,script}
	gPanelNames[name] = offset
	return true
end
function F_UnregisterPanel(offset)
	local p = gPanels[offset]
	if p then
		if offset < 0 then
			for i = offset,gPanelMin,-1 do
				gPanels[i] = gPanels[i-1]
			end
			gPanelMin = gPanelMin + 1
			if gPanelOffset < gPanelMin then
				gPanelOffset = gPanelMin
			end
		else
			for i = offset,gPanelMax do
				gPanels[i] = gPanels[i+1]
			end
			gPanelMax = gPanelMax - 1
			if gPanelOffset > gPanelMax then
				gPanelOffset = gPanelMax
			end
		end
		gPanelNames[p[1]] = nil
	end
end

-- panel exports
function exports.RegisterPanel(name,offset)
	if type(name) ~= "string" then
		typerror(1,"number")
	elseif type(offset) ~= "number" then
		typerror(2,"number")
	end
	return F_RegisterPanel(name,offset,GetCurrentScript())
end
function exports.UnregisterPanel(name)
	local offset = gPanelNames[name]
	if offset then
		F_UnregisterPanel(offset)
	end
end
function exports.ShowPanel(name)
	local offset = gPanelNames[name]
	if offset then
		gButtonPressed = GetTimer()
		gStayOpen = true
		gPanelOffset = offset
		gPanelShown = offset
		return true
	end
	return false
end
function exports.GetPanelAlpha(name)
	local offset = gPanelNames[name]
	if offset then
		return F_GetPanelAlpha(offset)
	end
	return 0
end

-- hidden speds
RegisterLocalEventHandler("sync:DeletePed",function(sped)
	gHidePeds[sped] = nil
end)
RegisterLocalEventHandler("ScriptDestroyed",function(script)
	gDisableRadar[script] = nil
	for sped,scripts in pairs(gHidePeds) do
		scripts[script] = nil
		if not next(scripts) then
			gHidePeds[sped] = nil
		end
	end
end)
function exports.HideSyncPed(sped)
	local script = GetCurrentScript()
	local scripts = gHidePeds[sped]
	if scripts then
		scripts[script] = true
	else
		gHidePeds[sped] = {[script] = true}
	end
end
function exports.UnhideSyncPed(sped)
	local scripts = gHidePeds[sped]
	if scripts then
		scripts[GetCurrentScript()] = nil
		if not next(scripts) then
			gHidePeds[sped] = nil
		end
	end
end
function exports.UnhideSyncPeds()
	local script = GetCurrentScript()
	for sped,scripts in pairs(gHidePeds) do
		scripts[script] = nil
		if not next(scripts) then
			gHidePeds[sped] = nil
		end
	end
end

-- player names
RegisterNetworkEventHandler("radar:UpdatePlayers",function(players)
	gPlayers = players
	F_SortNames()
end)
RegisterNetworkEventHandler("radar:UpdatePlayer",function(id,name,color)
	if name then
		gPlayers[id] = {name,color}
	else
		gPlayers[id] = nil
	end
	F_SortNames()
end)
function F_SortNames()
	gPlayerNames = {}
	for _,v in pairs(gPlayers) do
		if dsl.role_colors then
			local index = v[2]
			if index == 0 then
				index = 33
			end
			table.insert(gPlayerNames,{name = v[1],role = index,rgb = {dsl.role_colors.GetColorFromIndex(v[2])}})
		else
			table.insert(gPlayerNames,{name = v[1],role = 0,rgb = {230,230,230}})
		end
	end
	table.sort(gPlayerNames,function(a,b)
		if a.role ~= b.role then
			return a.role < b.role
		end
		return string.lower(a.name) < string.lower(b.name)
	end)
	if gPlayerNames[MAXIMUM_PLAYER_LIST+1] then
		local count = 0
		while gPlayerNames[MAXIMUM_PLAYER_LIST+1] do
			table.remove(gPlayerNames)
			count = count + 1
		end
		gPlayerNames[MAXIMUM_PLAYER_LIST] = {name = "< "..count.." more players online >",rgb = {230,230,230}}
	end
end

-- panel cleanup
RegisterLocalEventHandler("ScriptDestroyed",function(s)
	local cleaning = true
	while cleaning do
		cleaning = false
		for offset = gPanelMin,gPanelMax do
			if gPanels[offset][3] == s then
				F_UnregisterPanel(offset)
				cleaning = true
				break
			end
		end
	end
end)

-- disable f2menu
RegisterLocalEventHandler("f2menu:Open",function()
	if gRadarAlpha ~= 0 then
		return true
	end
end)

-- custom controls
RegisterLocalEventHandler("ControllerUpdating",function(c)
	if c == 0 then
		local pressed = IsButtonPressed(4,0)
		if next(gDisableRadar) or F_IsPaused() then
			gButtonPressed = nil
			pressed = false
		elseif pressed then
			if not gButtonDown then
				if not gButtonPressed then
					if IsUsingJoystick(0) then
						gStayOpen = true
					end
					gButtonPressed = GetTimer()
				elseif gStayOpen then
					gButtonPressed = nil
				end
			end
		elseif gButtonPressed and not gStayOpen and GetTimer() - gButtonPressed >= STAY_ON_MS then
			gButtonPressed = nil
		end
		gButtonDown = pressed
		if gButtonPressed and gRadarAlpha ~= 0 then
			if F_GetPanelAlpha(0) ~= 0 then
				if IsUsingJoystick(0) then
					if IsButtonPressed(10,0) then
						gRadarScale = gRadarScale - (gRadarScale / 10) * GetFrameTime() * PAD_ZOOM_SCALE
						if gRadarScale < MIN_ZOOM_LEVEL then
							gRadarScale = MIN_ZOOM_LEVEL
						end
					elseif IsButtonPressed(12,0) then
						gRadarScale = gRadarScale + (gRadarScale / 10) * GetFrameTime() * PAD_ZOOM_SCALE
						if gRadarScale > MAX_ZOOM_LEVEL then
							gRadarScale = MAX_ZOOM_LEVEL
						end
					end
					SetButtonPressed(10,0,false) -- disable lock / fire
					SetButtonPressed(12,0,false)
				else
					gRadarScale = gRadarScale + (gRadarScale / 10) * GetFrameTime() * GetMouseScroll() * MOUSE_ZOOM_SCALE
					if gRadarScale < MIN_ZOOM_LEVEL then
						gRadarScale = MIN_ZOOM_LEVEL
					elseif gRadarScale > MAX_ZOOM_LEVEL then
						gRadarScale = MAX_ZOOM_LEVEL
					end
					SetButtonPressed(11,0,false) -- likely to be scroll wheel, so disable weapon switching
					SetButtonPressed(12,0,false) -- but also weapon fire
					SetButtonPressed(13,0,false)
				end
			end
			if IsUsingJoystick(0) then
				gPanelButtonLeftLast = gPanelButtonLeftNow
				gPanelButtonLeftNow = IsButtonPressed(11,0)
				SetButtonPressed(11,0,false)
				gPanelButtonRightLast = gPanelButtonRightNow
				gPanelButtonRightNow = IsButtonPressed(13,0)
				SetButtonPressed(13,0,false)
			else
				gPanelButtonLeftLast = gPanelButtonLeftNow
				gPanelButtonLeftNow = IsKeyPressed("Q",0)
				SetKeyPressed("Q",0,false)
				gPanelButtonRightLast = gPanelButtonRightNow
				gPanelButtonRightNow = IsKeyPressed("E",0)
				SetKeyPressed("E",0,false)
			end
		end
		if pressed then
			SetButtonPressed(4,0,false) -- no normal map
		end
	end
end)
RegisterLocalEventHandler("ControllersUpdated",function()
	if gButtonPressed and F_GetPanelAlpha(0) ~= 0 then
		local sx,sy
		local h = -gRadarPosition[7]
		if IsUsingJoystick(0) then
			local frame = GetFrameTime() * -PAD_MOVE_SPEED
			sx = GetStickValue(18,0) * frame
			sy = GetStickValue(19,0) * frame
		else
			local frame = MOUSE_MOVE_SPEED
			sx,sy = GetMouseInput()
			sx,sy = sx*frame,sy*frame
			if IsMousePressed(0) then
				sx = -sx
				sy = -sy
			else
				sx,sy = 0,0
			end
		end
		if WasMirrorMode() then
			sx = -sx
		end
		gRadarOffset[1] = gRadarOffset[1] + (sx * math.cos(h) - sy * math.sin(h)) / gRadarScale
		gRadarOffset[2] = gRadarOffset[2] + (sx * math.sin(h) + sy * math.cos(h)) / gRadarScale
		SetStickValue(18,0,0)
		SetStickValue(19,0,0)
	end
end)

-- request players
SendNetworkEvent("radar:RequestPlayers")
