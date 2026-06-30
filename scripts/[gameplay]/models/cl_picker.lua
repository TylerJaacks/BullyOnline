LoadScript("characters.lua")
require("utility/texture")

HIDE_HUD_COMPS = {0,4,11}
TEXTURE_SIZE = 64
RULES_TIMER = 15000
SHOW_RULES = true

gPreviewPed = -1
gPreviewModel = 0
gTransition = false
gPictures = CopyTexture(CreateTexture("pictures.png"),"D3DFMT_DXT5")

gCurrentHint = gCharacters[1]
gMoneySound = false
gDelayString = ""
gShowDelay = false

gControlsLast = {}
gControlsNow = {}

gMenu = {}
gIndex = 1
gCount = 0
gOffset = 0
gShown = 10

-- events
RegisterLocalEventHandler("f2menu:Open",function()
	return true
end)
RegisterLocalEventHandler("chat:StartTyping",function()
	return true
end)
RegisterLocalEventHandler("chat:UpdateDisplay",function()
	return true
end)
RegisterLocalEventHandler("spawner:Unfade",function()
	return gTransition -- don't unfade spawner when doing transition
end)
RegisterLocalEventHandler("sync:SuppressPed",function(ped)
	return ped == gPreviewPed
end)
RegisterLocalEventHandler("ControllerUpdating",function(c)
	if c == 0 then
		for c,v in pairs(gControlsNow) do
			gControlsLast[c] = v
		end
		if IsUsingJoystick(0) then
			gControlsNow.up = IsButtonPressed(2,0)
			gControlsNow.down = IsButtonPressed(3,0)
			gControlsNow.select = IsButtonPressed(7,0)
			gControlsNow.cancel = IsButtonPressed(8,0)
		else
			gControlsNow.up = IsKeyPressed("W",0) or IsKeyPressed("UP",0)
			gControlsNow.down = IsKeyPressed("S",0) or IsKeyPressed("DOWN",0)
			gControlsNow.select = IsKeyPressed("RETURN",0)
			gControlsNow.cancel = IsKeyPressed("ESCAPE",0)
			SetKeyPressed("W",0,false)
			SetKeyPressed("UP",0,false)
			SetKeyPressed("S",0,false)
			SetKeyPressed("DOWN",0,false)
			SetKeyPressed("RETURN",0,false)
			SetKeyPressed("ESCAPE",0,false)
		end
		SetButtonPressed(4,0,false)
	end
end)
RegisterLocalEventHandler("NativeScriptLoaded",function(name,env)
	if name == "AreaScripts/Funhouse.lua" then
		env.CameraFade = F_FunhouseFade
	end
end)

-- networked
RegisterNetworkEventHandler("models:BoughtCharacter",function(id)
	gOwnedChars[id] = true
	gMoneySound = true
end)

-- main / cleanup
function main()
	F_Setup()
	F_UpdateDelayString()
	SoundPlayInteractiveStreamLocked("MS_Ambient01.rsm",0.5,500,500)
	if SHOW_RULES and gFirstPick then
		F_ShowRules()
	end
	CreateAdvancedThread("PRE_FADE",T_Interface)
	ToggleHUDMoneyVisibility(true)
	gMoneySound = false
	while true do
		if not IsPauseMenuActive() and not IsMapMenuActive() then
			F_Menu()
		end
		F_Peds()
		F_Camera()
		if gMoneySound then
			SoundPlay2D("BuyItem")
			gMoneySound = false
		end
		Wait(0)
	end
	F_Cleanup()
end
function MissionCleanup()
	if dsl.radar then
		dsl.radar.DisableRadar(false)
	end
	if PedIsValid(gPreviewPed) then
		PedDelete(gPreviewPed)
	end
	for _,c in ipairs(HIDE_HUD_COMPS) do
		ToggleHUDComponentVisibility(c,true)
	end
	ToggleHUDMoneyVisibility(false)
	SoundStopInteractiveStream()
	UnpauseGameClock()
	if gTransition then
		AreaDisableCameraControlForTransition(false)
		CameraFade(0,1)
	end
	CameraReset()
	CameraDefaultFOV()
	CameraReturnToPlayer()
	PlayerSetControl(1)
end

-- delay string
function F_UpdateDelayString()
	if gDelaySwitch then
		local delay = ""
		local days,hours,minutes = math.floor(gDelayHours/24),math.mod(gDelayHours,24),gDelayMinutes
		if days > 0 then
			delay = delay.." "..days.." d"
		end
		if hours > 0 then
			delay = delay.." "..hours.." h"
		end
		if minutes > 0 or not (days > 0 or hours > 0) then
			delay = delay.." "..minutes.." m"
		end
		gDelayString = string.sub(delay,2)
	end
end

-- rules page
function F_ShowRules()
	local rules = CreateTexture("rules.png")
	local started = GetAccurateTimer()
	local texture
	while not F_IsControlReleased("select") or GetAccurateTimer() - started < RULES_TIMER do
		local remain = math.ceil((RULES_TIMER - (GetAccurateTimer() - started)) / 1000)
		local x,y = F_DrawRules(rules,1)
		if remain <= 0 then
			if not texture then
				if IsUsingJoystick(0) then
					texture = GetInputTexture(7,0)
				else
					texture = GetHudTexture("Button_Enter")
				end
			end
			if texture then
				local height = 0.02
				local width = height * GetTextureDisplayAspectRatio(texture)
				DrawTexture(texture,x-width,y-height,width,height,255,255,255,255)
			end
		else
			SetTextFont("Georgia")
			SetTextBold()
			SetTextColor(200,200,200,255)
			SetTextPosition(x,y)
			SetTextAlign("R","B")
			DrawText(remain)
		end
		F_Peds()
		F_Camera()
		Wait(0)
	end
end

-- core stuff
function F_Setup()
	CreateAdvancedThread("POST_WORLD",T_Mirror)
	RegisterLocalEventHandler("PedUpdateMatrix",CB_PedUpdateMatrix)
	if dsl.f2menu then
		dsl.f2menu.Close()
	end
	if dsl.freecam then
		dsl.freecam.Stop()
	end
	if dsl.radar then
		dsl.radar.DisableRadar(true)
	end
	for _,c in ipairs(HIDE_HUD_COMPS) do
		ToggleHUDComponentVisibility(c,false)
	end
	PauseGameClock()
	PlayerSetHealth(PedGetMaxHealth(gPlayer))
	for _,char in ipairs(gCharacters) do
		if (not gFirstPick or char.starter) and (not char.hidden or not char.locked or gUnlockedChars[char.id]) then
			table.insert(gMenu,char)
		end
	end
	gCount = table.getn(gMenu)
	assert(gCount >= 1,"no characters")
	gIndex = F_GetCharIdMenuIndex(gInitialId) or 1
	if gIndex == 1 then
		gOffset = 0
	elseif gIndex > gCount - gShown then
		gOffset = gCount - gShown
	else
		gOffset = gIndex - 2
	end
	F_UpdateSelection()
end
function F_Menu()
	if F_IsControlPressed("select") then
		local char = gMenu[gIndex]
		if not gFirstPick and F_IsCurrentChar(char.id) then
			SendNetworkEvent("models:CancelPicker")
		elseif gFirstPick or gOwnedChars[char.id] then -- attempt switch
			if gDelaySwitch then
				if not gShowDelay then
					CreateThread("T_Delay")
					gShowDelay = true
				end
				SoundPlay2D("WrongBtn")
			else
				SendNetworkEvent("models:SwitchCharacter",char.id)
			end
		elseif (not char.locked or gUnlockedChars[char.id]) and PlayerGetMoney() >= char.price * 100 then
			SendNetworkEvent("models:BuyCharacter",char.id)
		else
			SoundPlay2D("WrongBtn")
		end
	elseif not gFirstPick and F_IsControlPressed("cancel") then
		SendNetworkEvent("models:CancelPicker")
	elseif gCount >= 2 then
		if F_IsControlPressed("down") then
			gIndex = gIndex + 1
			if gIndex > gCount then
				gIndex = 1
			end
			F_UpdateSelection()
			SoundPlay2D("NavDwn")
		elseif F_IsControlPressed("up") then
			gIndex = gIndex - 1
			if gIndex < 1 then
				gIndex = gCount
			end
			F_UpdateSelection()
			SoundPlay2D("NavDwn")
		end
	end
end
function F_Peds()
	if not PedIsValid(gPreviewPed) or not PedIsModel(gPreviewPed,gPreviewModel) then
		if PedIsValid(gPreviewPed) then
			PedDelete(gPreviewPed)
		end
		gPreviewPed = PedCreateXYZ(gPreviewModel,-741.87,-539.08,14.17)
		PedIgnoreAttackCone(gPreviewPed,true)
		PedIgnoreAttacks(gPreviewPed,true)
		PedIgnoreStimuli(gPreviewPed,true)
		PedClearAllWeapons(gPreviewPed)
	end
	if not PedMePlaying(gPreviewPed,"DEFAULT_KEY",true) then
		PedSetActionNode(gPreviewPed,"/GLOBAL","")
	end
	if SoundSpeechPlaying(gPlayer) then
		SoundStopCurrentSpeechEvent(gPlayer)
	end
	if AreaGetVisible() == 37 then
		PedSetPosSimple(gPlayer,-745.79,-531.91,7.93)
		PedSetPosSimple(gPreviewPed,-741.87,-539.08,14.17)
		PedFaceHeading(gPreviewPed,13.4,0)
	elseif not AreaIsLoading() then
		gTransition = true
		CameraFade(0,0)
		AreaDisableCameraControlForTransition(true)
		PlayerSetPosXYZArea(-745.79,-531.91,7.93,37)
		while AreaIsLoading() or IsStreamingBusy() do
			Wait(0)
		end
		AreaDisableCameraControlForTransition(false)
		CameraFade(1000,1)
		gTransition = false
	end
	PedSetUsesCollisionScripted(gPreviewPed,true)
	PedSetEffectedByGravity(gPreviewPed,false)
	PlayerSetControl(0)
end
function F_Camera()
	CameraSetXYZ(-742.98,-536.90,11.97,-740.72,-546.37,14.23)
	if IsUsingWidescreenPatch() then
		CameraSetFOV(85)
	else
		CameraSetFOV(105)
	end
end
function F_Cleanup()
	gTransition = true
	PlayerSetControl(0)
	CameraFade(1000,0)
	Wait(1000)
	PlayerSetPosXYZArea(312.23,-72.66,5.33,89.2,0)
	AreaDisableCameraControlForTransition(true)
	while AreaIsLoading() or IsStreamingBusy() do
		Wait(0)
	end
	AreaDisableCameraControlForTransition(false)
	Wait(500)
	CameraFade(1000,1)
	gTransition = false
end

-- menu utility
function T_Delay()
	local timer = GetAccurateTimer()
	while GetAccurateTimer() - timer < 3000 do
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(255,50,50,255)
		SetTextOutline()
		SetTextAlign("C","T")
		SetTextPosition(0.5,0.2)
		SetTextScale(1.2)
		DrawText("You must wait before switching again.\nSwitch cooldown: "..gDelayString..".")
		Wait(0)
	end
	gShowDelay = false
end
function F_UpdateSelection()
	if gCount <= gShown then
		gOffset = 0
	elseif gOffset > gIndex - 1 then
		gOffset = gIndex - 1 -- scroll up
	elseif gOffset < gIndex - gShown then
		gOffset = gIndex - gShown -- scroll down
	end
	gPreviewModel = gMenu[gIndex].variants[1].model
end

-- funhouse stuff
function T_Mirror()
	local screen,cw,ch
	while true do
		local nw,nh = GetDisplayResolution()
		if nw ~= cw or nh ~= ch then
			screen = nil
			screen = CreateRenderTarget(nw,nh)
			cw,ch = nw,nh
		end
		DrawBackBufferOntoTarget(screen)
		SetRendererAlphaBlending(false)
		ClearDisplay()
		DrawTexture(screen,1,1,-1,-1,255,255,255,255)
		SetRendererAlphaBlending(true)
		Wait(0)
	end
end
function F_FunhouseFade(duration,direction)
	if not gTransition then
		CameraFade(duration,direction)
	end
end
function CB_PedUpdateMatrix(ped)
	if ped == gPreviewPed then
		local scale = mat3()
		scale[1][1] = -1.5
		scale[2][2] = 1.5
		scale[3][3] = -1.5
		PedSetMatrix(ped,PedGetMatrix(ped)*scale)
	end
end

-- ui metrics
O_WIDTH = 0.5
O_HEIGHT = 0.1
O_SHOWN = 10
O_BORDER = 0.004
UI_SCROLL = 0.006
UI_INFO_WIDTH = 0.5
UI_INFO_HEIGHT = 0.2
UI_INFO_PAD = 0.01

-- ui drawing
function T_Interface()
	while true do
		if not IsPauseMenuActive() and not IsMapMenuActive() then
			local ar = GetDisplayAspectRatio()
			for i = 1,O_SHOWN do
				local char = gMenu[gOffset+i]
				if char then
					F_Interface(gOffset+i == gIndex,char,ar,0,(i-1)*O_HEIGHT)
				end
			end
			if gCount > gShown then
				local pad = 0.002
				DrawRectangle(O_WIDTH/ar,0,UI_SCROLL/ar,1,0,0,0,200)
				DrawRectangle((O_WIDTH+pad)/ar,pad+(1-(gShown/gCount))*((gIndex-1)/(gCount-1)),(UI_SCROLL-pad*2)/ar,gShown/gCount-pad*2,255,200,50,255)
			end
			DrawRectangle(1-(UI_INFO_PAD+UI_INFO_WIDTH)/ar,1-(UI_INFO_PAD+UI_INFO_HEIGHT),UI_INFO_WIDTH/ar,UI_INFO_HEIGHT,0,0,0,150)
			SetTextFont("Georgia")
			SetTextBold()
			SetTextColor(230,230,230,255)
			SetTextShadow()
			SetTextAlign("L","T")
			SetTextPosition(1-UI_INFO_WIDTH/ar,1-UI_INFO_HEIGHT)
			SetTextWrapping((UI_INFO_WIDTH-UI_INFO_PAD*2)/ar)
			SetTextScale(0.7)
			DrawText("Current Character: "..F_GetCurrentCharName().."\nOwned Characters: "..F_GetOwnedCharCount().."\n\n"..F_Information())
		end
		Wait(0)
	end
end
function F_Interface(selected,char,ar,x,y)
	local status = "unlocked" -- "unlocked", "locked", or "owned"
	local r,g,b,a = 0,0,0,100
	if selected then
		r,g,b,a = 255,200,50,255
		DrawRectangle(x,y,O_WIDTH/ar,O_HEIGHT,0,0,0,180)
	else
		DrawRectangle(x,y,O_WIDTH/ar,O_HEIGHT,0,0,0,150)
	end
	DrawRectangle(x,y,O_WIDTH/ar,O_BORDER,r,g,b,a) -- top
	DrawRectangle(x,y+O_HEIGHT-O_BORDER,O_WIDTH/ar,O_BORDER,r,g,b,a) -- bottom
	DrawRectangle(x,y+O_BORDER,O_BORDER/ar,O_HEIGHT-O_BORDER*2,r,g,b,a) -- left
	DrawRectangle(x+(O_WIDTH-O_BORDER)/ar,y+O_BORDER,O_BORDER/ar,O_HEIGHT-O_BORDER*2,r,g,b,a) -- right
	F_DrawIcon(char.icon,x+O_BORDER/ar,y+O_BORDER,(O_HEIGHT-O_BORDER*2)/ar,O_HEIGHT-O_BORDER*2,255,255,255,255)
	if not selected then
		r,g,b,a = 230,230,230,255
	end
	SetTextFont("Georgia")
	SetTextBold()
	SetTextColor(r,g,b,a)
	if selected then
		SetTextOutline()
	else
		SetTextShadow()
	end
	SetTextAlign("L","T")
	SetTextPosition(x+O_HEIGHT/ar,y+O_BORDER*2)
	SetTextScale(1.2)
	DrawText(char.name)
	SetTextFont("Georgia")
	SetTextBold()
	SetTextAlign("R","B")
	SetTextPosition(x+(O_WIDTH-O_BORDER*2)/ar,y+O_HEIGHT-O_BORDER*2)
	SetTextScale(0.9)
	if selected then
		SetTextOutline()
	else
		SetTextShadow()
	end
	if F_IsCurrentChar(char.id) then
		SetTextColor(255,200,50,255)
		DrawText("(current)")
	elseif gFirstPick then
		SetTextColor(180,180,180,255)
		DrawText("(free)")
	elseif gOwnedChars[char.id] then
		SetTextColor(180,180,180,255)
		DrawText("(owned)")
	elseif char.locked and not gUnlockedChars[char.id] then
		SetTextColor(230,50,50,255)
		DrawText("(locked)")
	elseif char.price == 0 then
		SetTextColor(180,180,180,255)
		DrawText("(free)")
	elseif PlayerGetMoney() >= char.price * 100 then
		SetTextColor(50,230,50,255)
		DrawText("$"..char.price)
	else
		SetTextColor(230,50,50,255)
		DrawText("$"..char.price)
	end
end
function F_Information()
	local str
	if gFirstPick then
		str = "Welcome to Bully Online! Your first character is free, then you can buy more later on.\n\nKeep in mind you're limited to \"starter\" models for your first pick."
	else
		str = "You can switch to a different owned character every few days. Choose carefully!"
	end
	if gDelaySwitch then
		str = str.."\n\nSwitch cooldown: "..gDelayString.."."
	end
	return str
end

-- character utility
function F_IsCurrentChar(id)
	local model = PedGetModelId(gPlayer)
	for _,var in ipairs(gCurrentHint.variants) do
		if var.model == model then
			return gCurrentHint.id == id
		end
	end
	for _,char in ipairs(gCharacters) do
		for _,var in ipairs(char.variants) do
			if var.model == model then
				return char.id == id
			end
		end
	end
	return false
end
function F_GetCurrentCharName()
	local model = PedGetModelId(gPlayer)
	for _,var in ipairs(gCurrentHint.variants) do
		if var.model == model then
			return gCurrentHint.name
		end
	end
	for _,char in ipairs(gCharacters) do
		for _,var in ipairs(char.variants) do
			if var.model == model then
				gCurrentHint = char
				return char.name
			end
		end
	end
	return "Ped Model "..model
end
function F_GetCharIdMenuIndex(id)
	local model = PedGetModelId(gPlayer)
	for index,char in ipairs(gMenu) do
		if char.id == id then
			return index
		end
	end
end
function F_GetOwnedCharCount()
	local count = 0
	for _ in pairs(gOwnedChars) do
		count = count + 1
	end
	return count
end

-- icon utility
function F_DrawIcon(index,x,y,w,h,r,g,b,a)
	local width,height = GetTextureResolution(gPictures)
	local rows = width / TEXTURE_SIZE
	local columns = height / TEXTURE_SIZE
	local row = math.mod(index,rows)
	local column = math.floor(index/rows)
	SetTextureBounds(gPictures,row/rows,column/columns,(row+1)/rows,(column+1)/columns)
	return DrawTexture(gPictures,x,y,w,h,r,g,b,a)
end

-- control utility
function F_IsControlPressed(control)
	local holding = {}
	function F_IsControlPressed(control)
		if gControlsNow[control] and not gControlsLast[control] then
			holding[control] = GetTimer() + 300
			return true
		elseif holding[control] then
			if not gControlsNow[control] then
				holding[control] = nil
			elseif GetTimer() >= holding[control] then
				holding[control] = GetTimer() + 55
				return true
			end
		end
		return false
	end
	return F_IsControlPressed(control)
end
function F_IsControlReleased(control)
	return not gControlsNow[control] and gControlsLast[control]
end
