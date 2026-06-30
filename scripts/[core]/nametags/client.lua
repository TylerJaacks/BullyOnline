gAllow = true
gScripts = {} -- [script] = true if a script is blocking nametags
gPlayers = {}
gHiddenPeds = {}
gPlayerColor = {230,230,230}

FADE_TIME = GetConfigNumber(GetScriptConfig(),"fade_ms",300) / 1000
MAX_DISTANCE = GetConfigNumber(GetScriptConfig(),"max_distance",10)
TEXT_SCALE = GetConfigNumber(GetScriptConfig(),"text_scale",1.8)
SCALE_FACTOR = GetConfigNumber(GetScriptConfig(),"scale_factor",0.65)
ONLY_TARGET = GetConfigBoolean(GetScriptConfig(),"only_when_target",false)
ONLY_SHOULDER = GetConfigBoolean(GetScriptConfig(),"only_over_shoulder",false)

-- main
function main()
	local hidden = false
	while true do
		if PedGetFlag(gPlayer,2) and not VehicleIsValid(VehicleFromDriver(gPlayer)) then
			if not hidden then
				SendNetworkEvent("nametags:HidePlayer",true)
				hidden = true
			end
		elseif hidden then
			SendNetworkEvent("nametags:HidePlayer")
			hidden = false
		end
		if gAllow and not next(gScripts) and not IsPauseMenuActive() and not IsMapMenuActive() then
			local x1,y1,z1 = CameraGetXYZ()
			for _,v in pairs(gPlayers) do
				if IsSyncPedValid(v.ped) and IsSyncEntityActive(v.ped) then
					local x2,y2,z2 = F_GetPosition(v)
					local dx,dy,dz = x2-x1,y2-y1,z2-z1
					local distance = dx*dx+dy*dy+dz*dz
					if distance < MAX_DISTANCE * MAX_DISTANCE and F_ShouldShow(v) then
						if v.alpha ~= 1 then -- fade in
							if FADE_TIME == 0 then
								v.alpha = 1
							else
								v.alpha = math.min(1,v.alpha+GetFrameTime()/FADE_TIME)
							end
						end
					elseif v.alpha ~= 0 then -- fade out
						if FADE_TIME == 0 then
							v.alpha = 0
						else
							v.alpha = math.max(0,v.alpha-GetFrameTime()/FADE_TIME)
						end
					end
					if v.alpha ~= 0 then
						local sx,sy = GetScreenCoords(x2,y2,z2)
						if sx then
							local r,g,b = unpack(v.color)
							SetTextFont("Georgia")
							SetTextBold()
							SetTextColor(r,g,b,255*v.alpha)
							SetTextShadow()
							SetTextAlign("C","B")
							SetTextScale(TEXT_SCALE*((1-SCALE_FACTOR)+SCALE_FACTOR*math.max(0,1-math.sqrt(distance)/MAX_DISTANCE)))
							SetDrawLayer("POST_WORLD") -- draw under hud and most other scripts
							SetTextPosition(sx,sy)
							DrawText(v.name)
						else
							v.alpha = 0 -- reset because the tag is off screen
						end
					end
				end
			end
		end
		Wait(0)
	end
end
function F_GetPosition(v)
	local px,py,pz
	local real = PedFromSyncPed(v.ped)
	if PedIsValid(real) and dsl.fakecars then
		local fake = dsl.fakecars.GetFakePed(real)
		if PedIsValid(fake) then
			real = fake
		end
	end
	if PedIsValid(real) then
		local bx,by,bz = PedGetPosXYZ(real)
		px,py,pz = PedGetHeadPos(real)
		if px == 0 then
			px,py,pz = bx,by,bz+v.height
		else
			v.height = pz - bz -- save height for when there's no head pos
		end
	else
		px,py,pz = GetSyncEntityPos(v.ped)
		pz = pz + v.height
	end
	return px,py,pz+0.3
end
function F_ShouldShow(v)
	if ONLY_TARGET then
		local ped = PedFromSyncPed(v.ped)
		if not PedIsValid(ped) or PedGetTargetPed(gPlayer) ~= ped then
			return false
		end
	end
	if ONLY_SHOULDER and CameraGetActive() ~= 13 then
		return false
	end
	return not gHiddenPeds[v.ped]
end
function F_ResetAlpha()
	for _,v in pairs(gPlayers) do
		v.alpha = 0
	end
end

-- exports
function exports.SetHidden(yes)
	local script = GetCurrentScript()
	if yes then
		if not next(gScripts) then
			F_ResetAlpha()
		end
		gScripts[script] = true
	else
		gScripts[script] = nil
	end
end
function exports.GetPedName(sped)
	for _,v in pairs(gPlayers) do
		if v.ped == sped then
			return v.name
		end
	end
end
function exports.GetPedColor(sped)
	for _,v in pairs(gPlayers) do
		if v.ped == sped then
			return unpack(v.color)
		end
	end
	if sped == GetSyncPlayerPed() then
		return unpack(gPlayerColor)
	end
	return 230,230,230
end

-- script cleanup
RegisterLocalEventHandler("ScriptDestroyed",function(script)
	gScripts[script] = nil
end)

-- menu option
if GetConfigBoolean(GetScriptConfig(),"add_f2menu_toggle") then
	local persist = GetPersistentDataTable("Xx_Yubari_xX") -- .hide_nametags = true
	local option = {name = "Show Nametags",right = "[ON]",description = "Toggle player nametag visibility."}
	if persist.hide_nametags then
		option.right = "[OFF]"
		gAllow = false
	end
	function option.func()
		persist.hide_nametags = gAllow or nil
		SavePersistentDataTables()
		gAllow = not gAllow
		if gAllow then
			F_ResetAlpha()
			option.right = "[ON]"
		else
			option.right = "[OFF]"
		end
	end
	RegisterLocalEventHandler("f2menu:Open",function(f_add)
		f_add(option)
	end)
end

-- pause tracker
RegisterLocalEventHandler("GameBeingUnpaused",function()
	F_ResetAlpha()
end)

-- player tracker
RegisterLocalEventHandler("sync:DeletePed",function(ped)
	for id,v in pairs(gPlayers) do
		if v.ped == ped then
			gPlayers[id] = nil
		end
	end
end)
RegisterNetworkEventHandler("nametags:SetPlayer",function(id,ped,name,color)
	if dsl.role_colors then
		color = {dsl.role_colors.GetColorFromIndex(color)}
	else
		color = {230,230,230}
	end
	gPlayers[ped] = {ped = ped,name = name,color = color,alpha = 0,height = 1.6}
end)
RegisterNetworkEventHandler("nametags:SetColor",function(color)
	if dsl.role_colors then
		gPlayerColor = {dsl.role_colors.GetColorFromIndex(color)}
	end
end)

-- hidden tracker
RegisterNetworkEventHandler("nametags:HidePeds",function(peds)
	gHiddenPeds = {}
	for _,ped in ipairs(peds) do
		gHiddenPeds[ped] = true
	end
end)
RegisterNetworkEventHandler("nametags:HidePed",function(ped,hide)
	gHiddenPeds[ped] = hide or nil
end)

-- initialize
SendNetworkEvent("nametags:RequestPlayers")
