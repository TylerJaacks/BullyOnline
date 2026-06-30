require("utility/texture")

-- current activity
local gCurrentId
local gCurrentInfo
local gCurrentOwner = false

-- nearby activity
local gNearbyAny = false
local gNearbyAlpha = 0
local gNearbySwitch = false -- switch asap
local gNearbySwitched = false
local gNearbyTexture

-- activity array
local gPanel = false -- the panel is active
local gIndex = 1
local gCount = 0
local gOffset = 0
local gShown = 5
local gActivities = {} --[[
	{
		id = id, -- (set by the activity system to a unique string)
		title = "Rat Wars",
		description = "Compete in a competitive first person shooter where you play as a rat!",
		area = 0,
		center = {270, -110, 7},
		range = 8,
		players = 2, -- (set by the activity system to the player count)
		max_players = 16,
		timer_base = GetSyncTimer(),
		timer_ms = 60000 * 1.5,
		no_dismiss = true,
		warp_pos = {270, -110, 7, 0},
		warp_range = 1,
	}
]]

-- controller stuff
local gControlsNow = {}
local gControlsLast = {}
local gControlsDelay = {}

-- panel textures
local gBorder
local gCircle
local gIconTextures = {}
local gDismissTexture
local gWarpTexture

-- miscellaneous
local gWarpThread
local gCanSkip = false
local gCanSwitch = true -- if switching ui should be used
local gCanSwitchButton = true -- if switching button can be pressed
local gDelayNext

-- network events
RegisterNetworkEventHandler("activity:SetActivity",function(id,info,owner)
	gCurrentId = id
	gCurrentInfo = info
	gCurrentOwner = owner or false
	gDelayNext = GetAccurateTimer()
end)
RegisterNetworkEventHandler("activity:AddActivity",function(id,info)
	for _,v in ipairs(gActivities) do
		if v.id == id then
			return
		end
	end
	info.id = id -- on the client, info also contains an id
	table.insert(gActivities,1,info)
	gCount = gCount + 1
	F_LoadIcon(info)
end)
RegisterNetworkEventHandler("activity:UpdateActivity",function(id,info)
	if info then
		info.id = id
		if gCurrentId == id then
			gCurrentInfo = info
		end
	end
	for i,v in ipairs(gActivities) do
		if v.id == id then
			if info then
				gActivities[i] = info
				F_LoadIcon(info)
			else
				F_RemoveActivity(i)
			end
			return
		end
	end
end)
RegisterNetworkEventHandler("activity:AllowSwitch",function(allow)
	gCanSwitch = allow or false
	gCanSwitchButton = true
end)
RegisterNetworkEventHandler("activity:AllowSkip",function()
	gCanSkip = true
end)
RegisterNetworkEventHandler("activity:NotifyActivity",function(str)
	if dsl.chat then
		dsl.chat.Say(str)
	end
end)

-- register panel
RegisterLocalEventHandler("radar:Open",function(f_register)
	gBorder = dsl.radar.GetBorder()
	f_register("ACTIVITIES",-1)
end)

-- exports
function exports.CanStart()
	if gDelayNext and GetAccurateTimer() - gDelayNext >= 2000 then
		gDelayNext = nil
	end
	return not gDelayNext and gCurrentId == nil
end
function exports.IsPlaying()
	return gCurrentId ~= nil
end

-- cleanup
function MissionCleanup()
	if gWarpThread then
		AreaDisableCameraControlForTransition(false)
		CameraFade(0,1)
	end
end

-- main
function main()
	local controls
	SendNetworkEvent("activity:InitScript")
	CreateThread("T_LeaveCurrent")
	CreateThread("T_SwitchNearby")
	while true do
		local alpha = F_GetAlpha()
		if alpha ~= 0 then
			if not gPanel then
				F_LoadIcons()
				gCircle = CopyTexture(CreateTexture("circle.png"),"D3DFMT_DXT5")
				gDismissTexture = GetInputTexture(9,0)
				gWarpTexture = GetInputTexture(6,0)
				controls = RegisterLocalEventHandler("ControllerUpdating",CB_ControllerUpdating)
				gPanel = true
			end
			if gCount > 0 then
				F_UpdateControls()
			end
			F_DrawActivities(alpha/255)
		elseif gPanel then
			gCircle = nil
			gIconTextures = {}
			gControlsNow = {}
			gControlsLast = {}
			gControlsDelay = {}
			RemoveEventHandler(controls)
			controls = nil
			gPanel = false
		end
		if gCanSkip and gCanSwitch and gCurrentId and IsKeyBeingPressed("F1") then
			SendNetworkEvent("activity:SkipQueue")
			gCanSkip = false
		end
		Wait(0)
	end
end
function T_LeaveCurrent()
	while true do
		if gCurrentId and gCanSwitch and gCurrentInfo.center and gCurrentInfo.range then
			local x1,y1,z1 = PlayerGetPosXYZ()
			local x2,y2,z2 = unpack(gCurrentInfo.center)
			local dx,dy,dz = x2-x1,y2-y1,z2-z1
			if dx*dx+dy*dy+dz*dz >= gCurrentInfo.range*gCurrentInfo.range or (gCurrentInfo.area and AreaGetVisible() ~= gCurrentInfo.area) then
				SendNetworkEvent("activity:SetActivity")
				SoundPlay2D("WrongBtn")
				gCanSwitch = false
			end
		end
		Wait(0)
	end
end
function T_SwitchNearby()
	local none = {title = "None"}
	local near_event
	while true do
		local alpha = 1
		if dsl.radar then
			alpha = 1 - dsl.radar.GetAlpha()
		end
		if dsl.f2menu and dsl.f2menu.IsOpen() then
			alpha = 0
		end
		gNearbyAny = false
		if not gWarpThread and gCanSwitch and alpha > 0 then
			local x1,y1,z1 = PlayerGetPosXYZ()
			local area = AreaGetVisible()
			local nearby,array = 0,{}
			SetTextFormatting(2)
			for _,v in ipairs(gActivities) do
				if v.center and v.range and (not v.area or v.area == area) then
					local x2,y2,z2 = unpack(v.center)
					local dx,dy,dz = x2-x1,y2-y1,z2-z1
					if dx*dx+dy*dy+dz*dz < v.range*v.range then
						if not near_event then
							near_event = RegisterLocalEventHandler("ControllerUpdating",CB_NearbyButtons)
							gNearbyTexture = GetInputTexture(6,0)
							gNearbySwitched = false
							gNearbySwitch = false
						end
						if not gNearbyAny then
							if gNearbyAlpha ~= 1 then
								gNearbyAlpha = gNearbyAlpha + GetFrameTime() / 0.1
								if gNearbyAlpha > 1 then
									gNearbyAlpha = 1
								end
							end
							gNearbyAny = true
						end
						nearby = nearby + 1
						array[nearby] = v.id
						F_DrawNearby(v,nearby,gCurrentId == v.id,alpha*gNearbyAlpha)
					end
				end
				if not gNearbySwitch and gNearbySwitched and gCanSwitchButton --[[and not gCurrentOwner]] and gNearbyAlpha == 1 then
					local index = 0
					for i,v in ipairs(array) do
						if v == gCurrentId then
							index = i
							break
						end
					end
					if index < nearby then
						SendNetworkEvent("activity:SetActivity",array[index+1])
						SoundPlay2D("NavDwn")
					else
						SendNetworkEvent("activity:SetActivity")
						SoundPlay2D("NavInvalid")
					end
					gCanSwitchButton = false
				end
			end
			if nearby > 0 then
				SetTextFont("Georgia")
				SetTextBold()
				SetTextColor(255,255,255,255*alpha*gNearbyAlpha)
				SetTextOutline()
				SetTextAlign("L","B")
				SetTextPosition(0.5-0.62/GetDisplayAspectRatio(),0.7)
				SetTextHeight(0.05)
				DrawText("Activities Nearby")
				F_DrawNearby(none,0,gCurrentId == nil,alpha*gNearbyAlpha)
			end
		end
		if near_event and not gNearbyAny then
			gNearbyAlpha = 0
			gNearbyTexture = nil
			RemoveEventHandler(near_event)
			near_event = nil
		end
		Wait(0)
	end
end
function F_GetAlpha()
	if dsl.radar then
		return dsl.radar.GetPanelAlpha("ACTIVITIES") * 255
	end
	return 0
end
function F_LoadIcons()
	local texture
	local f_set = function(icon)
		if type2(icon) ~= "texture" then
			error("invalid texture",2)
		end
		texture = icon
	end
	for _,v in ipairs(gActivities) do
		if not gIconTextures[v.id] then
			RunLocalEvent("activity:LoadIcon",v.id,f_set)
			if texture then
				gIconTextures[v.id] = texture
				texture = nil
			end
		end
	end
end
function F_LoadIcon(v)
	local texture
	local f_set = function(icon)
		if type2(icon) ~= "texture" then
			error("invalid texture",2)
		end
		texture = icon
	end
	if not gIconTextures[v.id] then
		RunLocalEvent("activity:LoadIcon",v.id,f_set)
		if texture then
			gIconTextures[v.id] = texture
		end
	end
end

-- controls
function CB_NearbyButtons(c)
	if c == 0 then
		gNearbySwitched = gNearbySwitch
		if not gPanel and IsButtonPressed(6,0) then
			SetButtonPressed(6,0,false)
			gNearbySwitch = true
		else
			gNearbySwitch = false
		end
	end
end
function CB_ControllerUpdating(c)
	if c == 0 then
		for _,b in ipairs({0,1,2,3,6,9}) do
			gControlsLast[b] = gControlsNow[b]
			if IsButtonPressed(b,0) then
				if not gControlsNow[b] then
					gControlsNow[b] = GetAccurateTimer()
					gControlsDelay[b] = 350
				end
				SetButtonPressed(b,0,false)
			elseif gControlsNow[b] then
				gControlsNow[b] = nil
			end
		end
	end
end
function F_IsButtonBeingPressed(b)
	if gControlsNow[b] then
		if not gControlsLast[b] then
			return true
		elseif GetAccurateTimer() - gControlsNow[b] >= gControlsDelay[b] then
			gControlsNow[b] = GetAccurateTimer()
			gControlsDelay[b] = 100
			return true
		end
	end
	return false
end

-- warping
function T_WarpTransition(v)
	local started = GetAccurateTimer()
	local w = {area = v.area}
	w.x,w.y,w.z,w.h = unpack(v.warp_pos)
	if v.warp_range then
		local h = math.random() * math.pi * 2
		local d = math.random() * v.warp_range
		w.x,w.y = w.x-math.sin(h)*d,w.y+math.cos(h)*d
	end
	if not RunLocalEvent("activity:WarpTo",v.id,w) or type(w.x) ~= "number" or type(w.y) ~= "number" or type(w.z) ~= "number" or type(w.area) ~= "number" then
		gWarpThread = nil
		return
	elseif AreaGetVisible() == w.area then
		local dist = DistanceBetweenCoords3d(w.x,w.y,w.z,PlayerGetPosXYZ())
		if dist < 10 then
			if dist >= 5 then
				if dsl.radar then
					dsl.radar.Close()
				end
				PlayerSetPosSimple(w.x,w.y,w.z)
			end
			gWarpThread = nil
			return
		end
	end
	CameraFade(650,0)
	Wait(650)
	PlayerSetPosXYZArea(w.x,w.y,w.z,w.area)
	AreaDisableCameraControlForTransition(true)
	while AreaIsLoading() or IsStreamingBusy() or GetAccurateTimer() - started < 1000 do
		Wait(0)
	end
	AreaDisableCameraControlForTransition(false)
	if dsl.radar then
		dsl.radar.Close()
	end
	if type(w.h) == "number" then
		PedFaceHeading(gPlayer,w.h,0)
	end
	PlayerSetPosXYZ(w.x,w.y,w.z)
	CameraFade(650,1)
	gWarpThread = nil
end

-- update
function F_UpdateControls()
	local v = gActivities[gIndex]
	if v.warp_pos and not gWarpThread and not VehicleIsValid(VehicleFromDriver(gPlayer)) and F_IsButtonBeingPressed(6,0) and not AreaIsLoading() and (not v.players or not v.max_players or v.players < v.max_players) then
		gWarpThread = CreateThread("T_WarpTransition",v)
		SoundPlay2D("ButtonDown")
	elseif not v.no_dismiss and F_IsButtonBeingPressed(9,0) then
		F_RemoveActivity(gIndex)
		SoundPlay2D("ButtonDown")
	elseif gCount > 1 then
		if F_IsButtonBeingPressed(2) then
			gIndex = gIndex - 1
			if gIndex < 1 then
				gIndex = gCount
			end
			F_UpdateOffset()
			SoundPlay2D("NavUp")
		elseif F_IsButtonBeingPressed(3) then
			gIndex = gIndex + 1
			if gIndex > gCount then
				gIndex = 1
			end
			F_UpdateOffset()
			SoundPlay2D("NavDwn")
		end
	end
end
function F_UpdateOffset()
	if gCount <= gShown then
		gOffset = 0
	elseif gIndex - gOffset > gShown then
		gOffset = gIndex - gShown
	elseif gIndex <= gOffset then
		gOffset = gIndex - 1
	end
end
function F_RemoveActivity(index)
	table.remove(gActivities,index)
	gCount = gCount - 1
	if gCount > 0 then
		if index < gIndex or gIndex > gCount then
			gIndex = gIndex - 1
		end
		if index < gIndex and gOffset > 0 then
			gOffset = gOffset - 1
		end
	end
	F_UpdateOffset()
end

-- drawing
function F_DrawNearby(v,index,active,alpha)
	local ar = GetDisplayAspectRatio()
	local x,y = 0.5-0.6/ar,0.7+index*0.037
	local color = 1
	if not active then
		color = 0.8
	elseif --[[not gCurrentOwner and]] gNearbyTexture then
		local w = 0.035 * GetTextureDisplayAspectRatio(gNearbyTexture)
		DrawTexture(gNearbyTexture,x-w-0.002/ar,y,w,0.035,255,255,255,255*alpha)
	end
	DrawRectangle(x,y,0.6/ar,0.035,0,0,0,150*alpha)
	SetTextFont("Georgia")
	SetTextBold()
	if active then
		SetTextColor(255,200,50,255*alpha)
		SetTextOutline()
	else
		SetTextColor(240,240,240,255*alpha)
		SetTextShadow()
	end
	SetTextAlign("L","T")
	SetTextPosition(x+0.005/ar,y)
	SetTextHeight(0.03)
	DrawText(v.title)
	if v.timer_ms then
		local seconds = math.max(0,math.ceil((v.timer_ms-(GetSyncTimer()-v.timer_base))/1000))
		SetTextFont("Georgia")
		SetTextBold()
		if seconds < 10 then
			SetTextColor(255*color,60*color,60*color,255*alpha)
		else
			SetTextColor(230*color,230*color,230*color,255*alpha)
		end
		SetTextShadow()
		SetTextAlign("R","T")
		SetTextPosition(x+(0.6-0.005)/ar,y)
		SetTextHeight(0.03/2)
		DrawText("[%d:%.2d]",math.floor(seconds/60),math.mod(seconds,60))
	end
	if v.players then
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(255*color,255*color,255*color,255*alpha)
		SetTextShadow()
		SetTextAlign("R","B")
		SetTextPosition(x+(0.6-0.005)/ar,y+0.035)
		SetTextHeight(0.03/2)
		if v.max_players then
			DrawText("Players: "..v.players.." / "..v.max_players)
		else
			DrawText("Players: "..v.players)
		end
	end
end
function F_DrawActivities(alpha)
	local scrollbar = 0
	local rounding = 0.005
	local ar = GetDisplayAspectRatio()
	local w = 0.7 / ar
	local h = 0.7
	DrawRectangle(0.5-w*0.5,0.5-h*0.5,w,h,49,85,90,230*alpha)
	if gBorder then
		local w = w * 1.09
		local h = h * 1.09
		DrawTexture(gBorder,0.5-w*0.5,0.495-h*0.5,w,h,255,255,255,255*alpha)
	end
	if gCount > gShown then
		scrollbar = 0.03
	end
	if gCurrentId then
		F_DrawCurrent(alpha,w,h)
		return
	end
	for i = 1,gShown do
		local v = gActivities[gOffset+i]
		if v then
			local color = 1
			local icon = gIconTextures[v.id]
			local y = 0.5 - h * 0.45 + (i - 1) * 0.115
			local w = w * 0.95
			local x = 0.5 - w * 0.5
			local h = 0.1
			if gOffset + i == gIndex then
				F_DrawRounded(rounding,0.5-w*0.5,y,w-scrollbar/ar,h,0,0,0,200*alpha)
				F_DrawRounded_2(rounding,0.5-w*0.5,y,w-scrollbar/ar,h,255,200,50,255*alpha)
			else
				F_DrawRounded(rounding,0.5-w*0.5,y,w-scrollbar/ar,h,0,0,0,150*alpha)
				color = 0.8
			end
			x = x + rounding / ar
			w = w - (rounding * 2) / ar
			h = h - rounding * 2
			y = y + rounding
			if icon then
				DrawTexture(icon,x,y,h/ar,h,255*color,255*color,255*color,255*alpha)
			end
			x = x + (h + 0.002) / ar
			w = w - (h + 0.004 + scrollbar) / ar
			if v.title then
				SetTextFont("Georgia")
				SetTextBold()
				SetTextColor(255*color,200*color,50*color,255*alpha)
				SetTextOutline()
				SetTextAlign("L","T")
				SetTextPosition(x,y)
				SetTextHeight(h*0.35) -- 35% title, 65% description (height)
				DrawText(v.title)
			end
			if v.description then
				SetTextFont("Georgia")
				SetTextBold()
				SetTextColor(230*color,230*color,230*color,255*alpha)
				SetTextAlign("L","T")
				SetTextPosition(x,y+h*0.35)
				SetTextHeight(h*0.18)
				SetTextWrapping(w*0.8) -- 80% remaining width is description
				SetTextClipping(nil,h*0.65)
				DrawText(v.description)
			end
			if v.players then
				local off = 0.002
				SetTextFont("Georgia")
				SetTextBold()
				SetTextColor(230*color,230*color,230*color,255*alpha)
				SetTextAlign("R","T")
				SetTextPosition(x+w-off/ar,y+off)
				SetTextHeight(h*0.15)
				SetTextWrapping(w*0.8) -- 80% remaining width is description
				SetTextClipping(nil,h*0.65)
				if v.max_players then
					DrawText("Players: "..v.players.." / "..v.max_players)
				else
					DrawText("Players: "..v.players)
				end
			end
			if v.timer_base and v.timer_ms then
				local off = 0.002
				local seconds = math.max(0,math.ceil((v.timer_ms-(GetSyncTimer()-v.timer_base))/1000))
				SetTextFont("Georgia")
				SetTextBold()
				if seconds < 10 then
					SetTextColor(255*color,60*color,60*color,255*alpha)
				else
					SetTextColor(230*color,230*color,230*color,255*alpha)
				end
				SetTextAlign("R","T")
				SetTextPosition(x+w-off/ar,y+off*2+h*0.15)
				SetTextHeight(h*0.15)
				DrawText("%d:%.2d",math.floor(seconds/60),math.mod(seconds,60))
			end
			if gOffset + i == gIndex then
				if not v.no_dismiss then
					local off = 0.002
					local tar = GetTextureDisplayAspectRatio(gDismissTexture)
					DrawTexture(gDismissTexture,x+w-(h*0.2)*tar,y+h-off-h*0.2,(h*0.2)*tar,h*0.2,255,255,255,255*alpha)
					SetTextFont("Georgia")
					SetTextBold()
					SetTextColor(230*color,230*color,230*color,255*alpha)
					SetTextAlign("R","B")
					SetTextPosition(x+w-(off+h*0.2)*tar,y+h-off)
					SetTextHeight(h*0.2)
					DrawText("Dismiss")
				end
				if v.warp_pos and not VehicleIsValid(VehicleFromDriver(gPlayer)) and (not v.players or not v.max_players or v.players < v.max_players) then
					local off = 0.002
					local tar = GetTextureDisplayAspectRatio(gWarpTexture)
					DrawTexture(gWarpTexture,x+w-(h*0.2)*tar,y+h-off*2-(h*0.2)*2,(h*0.2)*tar,h*0.2,255,255,255,255*alpha)
					SetTextFont("Georgia")
					SetTextBold()
					SetTextColor(230*color,230*color,230*color,255*alpha)
					SetTextAlign("R","B")
					SetTextPosition(x+w-(off+h*0.2)*tar,y+h-off*2-h*0.2)
					SetTextHeight(h*0.2)
					DrawText("Warp")
				end
			end
		end
	end
	if gCount > gShown then
		local pad = 0.003
		local y = 0.5 - h * 0.45
		local w = w * 0.95
		local x = 0.5 - w * 0.5
		local h = 0.1 * gShown + 0.015 * (gShown - 1)
		scrollbar = scrollbar * 0.8
		F_DrawRounded(rounding,x+w-scrollbar/ar,y,scrollbar/ar,h,0,0,0,150*alpha)
		F_DrawRounded(rounding,x+w-(scrollbar-pad)/ar,y+pad+h*(1-(gShown/gCount))*((gIndex-1)/(gCount-1)),(scrollbar-pad*2)/ar,h*(gShown/gCount)-pad*2,255,200,50,200*alpha)
	end
	SetTextFont("Georgia")
	SetTextBold()
	SetTextColor(255,200,50,255*alpha)
	SetTextShadow()
	SetTextAlign("R","B")
	SetTextPosition(0.5+w*0.5-0.02/ar,0.5+h*0.5-0.02)
	if gCount > 0 then
		SetTextHeight(0.04)
		DrawText(gIndex.." / "..gCount)
	else
		SetTextHeight(0.02)
		DrawText("No activities available.\nFind stuff to do in the world!")
	end
end
function F_DrawCurrent(alpha,w,h)
	if gCurrentInfo.title then
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(255,200,50,255*alpha)
		SetTextOutline()
		SetTextAlign("C","T")
		SetTextPosition(0.5,0.5-h*0.3)
		SetTextHeight(0.04)
		SetTextClipping(w*0.98)
		DrawText(gCurrentInfo.title)
	end
	if gCurrentInfo.description then
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(230,230,230,255*alpha)
		SetTextAlign("C","T")
		SetTextPosition(0.5,0.5-h*0.3+0.05)
		SetTextHeight(0.02)
		SetTextWrapping(w*0.9)
		DrawText(gCurrentInfo.description)
	end
	if gCurrentInfo.players then
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(230,230,230,255*alpha)
		SetTextShadow()
		SetTextAlign("C","T")
		SetTextPosition(0.5,0.5+h*0.1)
		SetTextHeight(0.03)
		if gCurrentInfo.max_players then
			DrawText("Players: "..gCurrentInfo.players.." / "..gCurrentInfo.max_players)
		else
			DrawText("Players: "..gCurrentInfo.players)
		end
	end
	if gCurrentInfo.timer_base and gCurrentInfo.timer_ms then
		local seconds = math.max(0,math.ceil((gCurrentInfo.timer_ms-(GetSyncTimer()-gCurrentInfo.timer_base))/1000))
		if seconds > 0 then
			SetTextFont("Georgia")
			SetTextBold()
			if seconds < 10 then
				SetTextColor(255,80,80,255*alpha)
			else
				SetTextColor(230,230,230,255*alpha)
			end
			SetTextShadow()
			SetTextAlign("C","T")
			SetTextPosition(0.5,0.5+h*0.1+0.035)
			SetTextHeight(0.025)
			DrawText("%d:%.2d",math.floor(seconds/60),math.mod(seconds,60))
		end
	end
end
function F_DrawRounded(size,x,y,w,h,r,g,b,a)
	local ar = GetDisplayAspectRatio()
	DrawRectangle(x+size/ar,y,w-(size*2)/ar,size,r,g,b,a) -- top (cut corners)
	DrawRectangle(x,y+size,w,h-size*2,r,g,b,a) -- center (full width)
	DrawRectangle(x+size/ar,y+h-size,w-(size*2)/ar,size,r,g,b,a) -- bottom (cut corners)
	SetTextureBounds(gCircle,0,0,0.5,0.5)
	DrawTexture(gCircle,x,y,size/ar,size,r,g,b,a) -- top left
	SetTextureBounds(gCircle,0.5,0,1,0.5)
	DrawTexture(gCircle,x+w-size/ar,y,size/ar,size,r,g,b,a) -- top right
	SetTextureBounds(gCircle,0,0.5,0.5,1)
	DrawTexture(gCircle,x,y+h-size,size/ar,size,r,g,b,a) -- bottom left
	SetTextureBounds(gCircle,0.5,0.5,1,1)
	DrawTexture(gCircle,x+w-size/ar,y+h-size,size/ar,size,r,g,b,a) -- bottom right
end
function F_DrawRounded_2(size,x,y,w,h,r,g,b,a)
	local ar = GetDisplayAspectRatio()
	DrawRectangle(x+size/ar,y,w-(size*2)/ar,size,r,g,b,a) -- top (cut corners)
	DrawRectangle(x+size/ar,y+h-size,w-(size*2)/ar,size,r,g,b,a) -- bottom (cut corners)
	DrawRectangle(x,y+size,size/ar,h-size*2,r,g,b,a) -- left
	DrawRectangle(x+w-size/ar,y+size,size/ar,h-size*2,r,g,b,a) -- right
	SetTextureBounds(gCircle,0,0,0.5,0.5)
	DrawTexture(gCircle,x,y,size/ar,size,r,g,b,a) -- top left
	SetTextureBounds(gCircle,0.5,0,1,0.5)
	DrawTexture(gCircle,x+w-size/ar,y,size/ar,size,r,g,b,a) -- top right
	SetTextureBounds(gCircle,0,0.5,0.5,1)
	DrawTexture(gCircle,x,y+h-size,size/ar,size,r,g,b,a) -- bottom left
	SetTextureBounds(gCircle,0.5,0.5,1,1)
	DrawTexture(gCircle,x+w-size/ar,y+h-size,size/ar,size,r,g,b,a) -- bottom right
end

-- utility
function F_GetIcon(index)
	local width,height = GetTextureResolution(gIconTextures)
	local rows = math.floor(width/ICON_SIZE)
	local columns = math.floor(height/ICON_SIZE)
	local x,y = math.mod(index,columns),math.floor(index/columns)
	return x/columns,y/rows,(x+1)/columns,(y+1)/rows
end
