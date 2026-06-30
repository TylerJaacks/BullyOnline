-- how to disable: call dsl.freecam.Stop(), then return true during the freecam:Activate event

MAXIMUM_PITCH = math.rad(89.9)
MAXIMUM_DISTANCE = 15
FINE_ROTATION = 0.8

gAdmin = false
gScript = GetCurrentScript()
gScripts = {}
gFOV = 90

gSettings = GetPersistentDataTable("Xx_Yubari_xX") -- .freecam = {}
if not gSettings.freecam then
	gSettings.freecam = {
		fine_rotation = false,
		move_3d = false,
		move_speed = 5,
		look_controller = 2.5,
		look_mouse = 0.03,
	}
end
gSettings = gSettings.freecam

gSpeedups = {5,15,40,70}
gSpeedups.n = table.getn(gSpeedups)

-- main
function F_Setup()
	local x,y,z = CameraGetXYZ()
	local p,r,h = CameraGetRotation()
	gPosition = {x,y,z}
	gRotation = {F_Rot(-(p-math.pi*0.5)),0,F_Rot(h+math.pi)}
	gControl = true
	gFollow = false
	gFocus = false
	gFocusDist = 5
	gSpeedup = 0
end
function T_Freecam()
	while true do
		if CameraGetActive() ~= 4 then
			CameraAllowChange(true)
		end
		F_UpdateCamera()
		CameraAllowChange(false)
		CameraSetFOV(gFOV)
		SoundSetAudioFocusCamera()
		Wait(0)
		if gControl then
			F_UpdateControls()
			PlayerSetControl(0)
		end
	end
end
function F_Cleanup()
	if gControl then
		PlayerSetControl(1)
	end
	if gFollow then
		PedSetUsesCollisionScripted(gPlayer,false)
		PedSetEffectedByGravity(gPlayer,true)
	end
	CameraAllowChange(true)
	CameraReset()
	CameraDefaultFOV()
	CameraReturnToPlayer()
	SoundSetAudioFocusPlayer()
end
function F_UpdateCamera()
	local cx,cy,cz = unpack(gPosition)
	local cp,cr,ch = unpack(gRotation)
	if gFocus then
		local fx,fy,fz = gFocus()
		local dx,dy,dz = fx-cx,fy-cy,fz-cz
		local dist = math.sqrt(dx*dx+dy*dy+dz*dz)
		if dist == 0 then
			gRotation[1] = 0
		else
			gRotation[1] = math.asin(dz/dist)
		end
		gRotation[3] = math.atan2(-dx,dy)
		cp,cr,ch = unpack(gRotation)
	end
	if gFollow then
		local ox,oy,oz = RotateVector(0,-2,0,cp,cr,ch,5)
		PedSetPosSimple(gPlayer,cx+ox,cy+oy,cz+oz-1)
		PedFaceHeading(gPlayer,math.deg(ch),0)
		PedSetUsesCollisionScripted(gPlayer,true)
		PedSetEffectedByGravity(gPlayer,false)
	end
	CameraSetXYZ(cx,cy,cz,cx-math.cos(cp)*math.sin(ch),cy+math.cos(cp)*math.cos(ch),cz+math.sin(cp))
end
function F_UpdateControls()
	local cx,cy,cz = unpack(gPosition)
	local cp,cr,ch = unpack(gRotation)
	local mspeed = GetFrameTime() * gSettings.move_speed
	local lspeed = GetFrameTime() * (math.pi * 0.5)
	local mx,my,mz,lx,ly
	if IsUsingJoystick(0) then
		mx,my,mz = -GetStickValue(16,0),GetStickValue(17,0),0
		if IsButtonPressed(13,0) then
			mz = 1
		end
		if IsButtonPressed(11,0) then
			mz = mz - 1
		end
		lx,ly = GetStickValue(18,0),GetStickValue(19,0)
		if IsButtonPressed(7,0) then
			if IsButtonBeingPressed(7,0) then
				gSpeedup = gSpeedup + 1
			end
			gSpeedupTimer = GetTimer()
		elseif IsButtonPressed(8,0) then
			if gSettings.fine_rotation then
				lspeed = lspeed * FINE_ROTATION
			end
			mspeed = mspeed * 0.2
		end
		lspeed = lspeed * gSettings.look_controller
		if gFocus then
			if IsButtonPressed(6,0) then
				gFocusDist = gFocusDist - GetFrameTime() * 4
				if gFocusDist < 1 then
					gFocusDist = 1
				end
			end
			if IsButtonPressed(9,0) then
				gFocusDist = gFocusDist + GetFrameTime() * 4
				if gFocusDist > 30 then
					gFocusDist = 30
				end
			end
		end
	else
		mx,my,mz = 0,0,0
		if IsKeyPressed("W",0) then
			my = 1
		end
		if IsKeyPressed("S",0) then
			my = my - 1
		end
		if IsKeyPressed("D",0) then
			mx = 1
		end
		if IsKeyPressed("A",0) then
			mx = mx - 1
		end
		if mx ~= 0 or my ~= 0 then
			local dist = math.sqrt(mx*mx+my*my)
			mx,my = mx/dist,my/dist
		end
		if IsKeyPressed("SPACE",0) then
			mz = 1
		end
		if IsKeyPressed("C",0) then
			mz = mz - 1
		end
		lx,ly = GetMouseInput()
		if IsKeyPressed("LSHIFT",0) and not VehicleIsValid(VehicleFromDriver(gPlayer)) then
			if IsKeyBeingPressed("LSHIFT",0) then
				gSpeedup = gSpeedup + 1
			end
			gSpeedupTimer = GetTimer()
		elseif IsKeyPressed("LCONTROL",0) then
			if gSettings.fine_rotation then
				lspeed = lspeed * FINE_ROTATION
			end
			mspeed = mspeed * 0.05
		end
		lspeed = -lspeed * gSettings.look_mouse
		if gFocus then
			gFocusDist = gFocusDist - GetMouseScroll() * GetFrameTime() * 0.2
			if gFocusDist < 1 then
				gFocusDist = 1
			elseif gFocusDist > 30 then
				gFocusDist = 30
			end
		end
	end
	if gSpeedup ~= 0 then
		if GetTimer() - gSpeedupTimer >= 200 then
			gSpeedup = 0
		elseif gAdmin then
			mspeed = mspeed * gSpeedups[math.min(gSpeedups.n,gSpeedup)]
		else
			mspeed = mspeed * gSpeedups[1]
		end
	end
	if dsl.radar and dsl.radar.IsActive() then
		lx,ly = 0,0
	end
	if gFocus or lx ~= 0 or ly ~= 0 then
		gRotation[1] = cp + ly * lspeed
		if gRotation[1] < -MAXIMUM_PITCH then
			gRotation[1] = -MAXIMUM_PITCH
		elseif gRotation[1] > MAXIMUM_PITCH then
			gRotation[1] = MAXIMUM_PITCH
		end
		gRotation[3] = F_Rot(ch + lx * lspeed)
		cp,cr,ch = unpack(gRotation)
		if gFocus then
			local fx,fy,fz = gFocus()
			gPosition[1] = fx - (math.cos(cp) * -math.sin(ch)) * gFocusDist
			gPosition[2] = fy - (math.cos(cp) * math.cos(ch)) * gFocusDist
			gPosition[3] = fz - math.sin(cp) * gFocusDist
		end
	end
	if not gFocus then
		if mx ~= 0 or my ~= 0 or mz ~= 0 then
			if gSettings.move_3d then
				gPosition[1] = cx + (mx * math.cos(ch) - my * math.cos(cp) * math.sin(ch)) * mspeed
				gPosition[2] = cy + (mx * math.sin(ch) + my * math.cos(cp) * math.cos(ch)) * mspeed
				gPosition[3] = cz + (my * math.sin(cp) + mz) * mspeed
			else
				gPosition[1] = cx + (mx * math.cos(ch) - my * math.sin(ch)) * mspeed
				gPosition[2] = cy + (mx * math.sin(ch) + my * math.cos(ch)) * mspeed
				gPosition[3] = cz + mz * mspeed
			end
		end
		if not gAdmin and not F_IsScripted() then
			local px,py,pz = PlayerGetPosXYZ()
			local cx,cy,cz = unpack(gPosition)
			local dx,dy,dz = cx-px,cy-py,cz-pz
			local dist = dx*dx+dy*dy+dz*dz
			if dist > MAXIMUM_DISTANCE*MAXIMUM_DISTANCE then
				dist = math.sqrt(dist)
				gPosition[1] = px + (dx / dist) * MAXIMUM_DISTANCE
				gPosition[2] = py + (dy / dist) * MAXIMUM_DISTANCE
				gPosition[3] = pz + (dz / dist) * MAXIMUM_DISTANCE
			end
		end
	elseif gSettings.move_3d then
		gFocusMove[1] = (mx * math.cos(ch) - my * math.cos(cp) * math.sin(ch)) * mspeed
		gFocusMove[2] = (mx * math.sin(ch) + my * math.cos(cp) * math.cos(ch)) * mspeed
		gFocusMove[3] = (my * math.sin(cp) + mz) * mspeed
	else
		gFocusMove[1] = (mx * math.cos(ch) - my * math.sin(ch)) * mspeed
		gFocusMove[2] = (mx * math.sin(ch) + my * math.cos(ch)) * mspeed
		gFocusMove[3] = mz * mspeed
	end
end

-- utility
function F_IsScripted()
	local s = next(gScripts)
	if s and (s ~= gScript or next(gScripts,s)) then
		return true
	end
	return false
end
function F_Toggle(s,on)
	if on then
		if not gScripts[s] then
			if not next(gScripts) and RunLocalEvent("freecam:Activate") then
				if dsl.first_person then
					dsl.first_person.Stop()
				end
				F_Setup()
				gThread = CreateThread("T_Freecam")
				gScripts[s] = true
			end
		end
	elseif gScripts[s] then
		gScripts[s] = nil
		if not next(gScripts) then
			TerminateThread(gThread)
			gThread = nil
			F_Cleanup()
		elseif gFocusScript == s then
			gFocus = false
		end
	end
end
function F_Stop()
	for s in pairs(gScripts) do
		F_Toggle(s,false)
	end
end
function F_Rot(r)
	while r > math.pi do
		r = r - math.pi * 2
	end
	while r <= -math.pi do
		r = r + math.pi * 2
	end
	return r
end

-- cleanup
function MissionCleanup()
	if next(gScripts) then
		gScripts = {[gScript] = true}
		F_Toggle(gScript,false)
	end
end

-- menu
function M_Freecam(parent,selected)
	local menu = parent:submenu(selected.name)
	while menu:active() do
		if menu:option("Toggle Freecam",F_GetFreecamStatus(),"Toggle the freecam.") then
			F_Toggle(gScript,not gScripts[gScript])
		end
		if next(gScripts) then
			if gAdmin and menu:option("Player Follow",gFollow and "[ON]" or "[OFF]","Keep the player slightly behind the camera.") then
				if gFollow then
					PedSetUsesCollisionScripted(gPlayer,false)
					PedSetEffectedByGravity(gPlayer,true)
				end
				gFollow = not gFollow
			elseif menu:option("Player Movement",gControl and "[OFF]" or "[ON]","Control the player instead of the camera.") then
				if gControl then
					PlayerSetControl(1)
				end
				gControl = not gControl
			elseif gAdmin and menu:option("Teleport Player",nil,"Teleport to the camera.") then
				local cx,cy,cz = unpack(gPosition)
				local cp,cr,ch = unpack(gRotation)
				local ox,oy,oz = RotateVector(0,3,0,cp,cr,ch,5)
				PedSetPosSimple(gPlayer,cx+ox,cy+oy,cz+oz-1)
				if gFollow then
					PedSetUsesCollisionScripted(gPlayer,false)
					PedSetEffectedByGravity(gPlayer,true)
					gFollow = false
				end
			end
		end
		if menu:option("Camera Movement",gSettings.move_3d and "[3D]" or "[2D]","Whether or not moving the camera forward / backwards affects height.") then
			gSettings.move_3d = not gSettings.move_3d
			SavePersistentDataTables()
		elseif menu:option("Fine Rotation",gSettings.fine_rotation and "[ON]" or "[OFF]","If the slow-down button should also adjust rotation speed.") then
			gSettings.fine_rotation = not gSettings.fine_rotation
			SavePersistentDataTables()
		elseif menu:option("Controller Sensitivity",string.format("[x%.1f]",gSettings.look_controller),"Look sensitivity when using a controller.") then
			F_AdjustSetting(menu,"look_controller","%.1f",0.5,10,0.5)
			SavePersistentDataTables()
		elseif menu:option("Mouse Sensitivity",string.format("[x%.3f]",gSettings.look_mouse),"Look sensitivity when using a mouse.") then
			F_AdjustSetting(menu,"look_mouse","%.3f",0.002,0.12,0.002)
			SavePersistentDataTables()
		end
		menu:draw()
		Wait(0)
	end
end
function F_GetFreecamStatus()
	if gScripts[gScript] then
		return "[ON]"
	elseif next(gScripts) then
		return "[LOCKED]"
	end
	return "[OFF]"
end
function F_AdjustSetting(menu,key,fmt,minimum,maximum,step)
	local backup = gSettings[key]
	local value = backup
	while menu:active() do
		menu:draw(string.format("> "..fmt.." <",value))
		Wait(0)
		if menu:left() then
			break
		elseif menu:right() then
			return
		elseif menu:up() then
			value = (math.floor(value / step) + 1) * step
			if value > maximum then
				value = maximum
			end
			gSettings[key] = value
		elseif menu:down() then
			value = (math.ceil(value / step) - 1) * step
			if value < minimum then
				value = minimum
			end
			gSettings[key] = value
		end
	end
	gSettings[key] = backup
end

-- events
RegisterNetworkEventHandler("freecam:SetAdmin",function()
	gAdmin = true
end)
RegisterLocalEventHandler("ScriptDestroyed",function(s)
	F_Toggle(s,false)
end)
RegisterLocalEventHandler("first_person:Activate",function()
	if next(gScripts) then
		return true
	end
end)
RegisterLocalEventHandler("f2menu:Open",function(f_add)
	f_add({
		name = "Freecam Options",
		description = "Toggle the freecam and adjust related settings.",
		thread = M_Freecam,
	})
end)

-- exports
function exports.IsActive()
	return next(gScripts) and true or false
end
function exports.Activate()
	return CallFunctionFromScript(gScript,F_Toggle,GetCurrentScript(),true)
end
function exports.Deactivate()
	return CallFunctionFromScript(gScript,F_Toggle,GetCurrentScript(),false)
end
function exports.Stop() -- forces deactivation for *ALL* scripts
	CallFunctionFromScript(gScript,F_Stop)
end
function exports.SetFocus(cb)
	if cb ~= nil and type(cb) ~= "function" then
		typerror(1,"function")
	end
	if next(gScripts) then
		if cb then
			gFocus = cb
			gFocusMove = {0,0,0}
			gFocusScript = GetCurrentScript()
		else
			gFocus = false
		end
	end
end
function exports.GetFocusMove()
	if next(gScripts) and gFocus then
		return unpack(gFocusMove)
	end
	return 0,0,0
end
function exports.GetPosition(ox,oy,oz)
	if next(gScripts) then
		local cx,cy,cz = unpack(gPosition)
		if ox ~= nil then
			local cp,cr,ch = unpack(gRotation)
			if type(ox) ~= "number" then
				typerror(1,"number")
			end
			if type(oy) ~= "number" then
				typerror(2,"number")
			end
			if type(oz) ~= "number" then
				typerror(3,"number")
			end
			ox,oy,oz = RotateVector(ox,oy,oz,cp,cr,ch,5)
			return cx+ox,cy+oy,cz+oz
		end
		return cx,cy,cz
	end
	return 0,0,0
end
function exports.GetRotation()
	if next(gScripts) then
		return unpack(gRotation)
	end
	return 0,0,0
end

-- command
SetCommand("freecam_fov",function(fov)
	fov = tonumber(fov)
	if fov > 0 and fov < 180 then
		gFOV = fov
	end
end,false,"Usage: freecam_fov <fov>\nSet the freecam's FOV.")

-- init
SendNetworkEvent("freecam:AskAdmin")
