-- HOW TO TWEAK DYNAMIC FOV: Turn on SPEED_FOV_DEBUG, then adjust the values in SPEED_FOV_WALKING and SPEED_FOV_DRIVING.

LoadScript("offsets.lua")

SPEED_FOV_DEBUG = false
SPEED_FOV_WALKING = {
	fov = 4, -- max fov increase
	minimum = 4, -- speed to start effect
	maximum = 7, -- speed needed for max effect
	raise_rate = 2, -- fov added per second
	lower_rate = 12 -- fov subtracted per second
}
SPEED_FOV_DRIVING = {
	fov = 3,
	minimum = 12,
	maximum = 21,
	raise_rate = 4,
	lower_rate = 12
}

MAX_SPRINT_ANGLE = math.rad(50)
MINIMUM_PITCH = math.rad(-75)
MAXIMUM_PITCH = math.rad(70)
MAXIMUM_VEH_H = math.rad(150)

SPEED_COUNT = 20
SPEED_SNAP = 10

gRatHeight = 0.07

gScaleFOV = 1
gSmoothFOV = 0
gSpeed = {n = 0}

gPreviewOffset = {}
gCanOffset = false

gForceStart = false

gFirstPerson = {}
gWalking = false
gDriving = -1

gCamera = {}

-- exports (aim assist)
function exports.Assist(tx,ty,tz,advance)
	if type(tx) ~= "number" then
		typerror(1,"number")
	elseif type(ty) ~= "number" then
		typerror(2,"number")
	elseif type(tz) ~= "number" then
		typerror(3,"number")
	elseif type(advance) ~= "number" and advance ~= nil then
		typerror(4,"number")
	elseif gFirstPerson[1] then
		local cx,cy,cz = exports.GetPosition()
		local dx,dy,dz = tx-cx,ty-cy,tz-cz
		local dist = math.sqrt(dx*dx+dy*dy+dz*dz)
		if gWalking then
			local p2,h2 = 0,math.atan2(-dx,dy)
			if dist > 0 then
				p2 = math.asin(dz/dist)
			end
			if advance and advance < 1 then
				local p1,h1 = unpack(gFirstPerson)
				p2 = p2 - p1
				while p2 > math.pi do
					p2 = p2 - math.pi * 2
				end
				while p2 <= -math.pi do
					p2 = p2 + math.pi * 2
				end
				if p2 < MINIMUM_PITCH then
					p2 = MINIMUM_PITCH
				elseif p2 > MAXIMUM_PITCH then
					p2 = MAXIMUM_PITCH
				end
				h2 = h2 - h1
				while h2 > math.pi do
					h2 = h2 - math.pi * 2
				end
				while h2 <= -math.pi do
					h2 = h2 + math.pi * 2
				end
				p2 = p1 + p2 * advance
				h2 = h1 + h2 * advance
			end
			gFirstPerson = {p2,h2}
			F_WalkingCamera(p2,h2)
		end
	end
end

-- exports (miscellaneous)
function exports.Push(pp,ph)
	if type(pp) ~= "number" then
		typerror(1,"number")
	elseif type(ph) ~= "number" then
		typerror(2,"number")
	elseif gFirstPerson[1] then
		local cp,ch = unpack(gFirstPerson)
		cp = cp + math.rad(pp)
		while cp > math.pi do
			cp = cp - math.pi * 2
		end
		while cp <= -math.pi do
			cp = cp + math.pi * 2
		end
		if cp < MINIMUM_PITCH then
			cp = MINIMUM_PITCH
		elseif cp > MAXIMUM_PITCH then
			cp = MAXIMUM_PITCH
		end
		ch = ch + math.rad(ph)
		while ch > math.pi do
			ch = ch - math.pi * 2
		end
		while ch <= -math.pi do
			ch = ch + math.pi * 2
		end
		gFirstPerson = {cp,ch}
		if gWalking then
			F_WalkingCamera(cp,ch)
		else
			if ch < -MAXIMUM_VEH_H then
				ch = -MAXIMUM_VEH_H
			elseif ch > MAXIMUM_VEH_H then
				ch = MAXIMUM_VEH_H
			end
			F_VehicleCamera(cp,ch)
		end
	end
end
function exports.AdjustFOV(scale)
	if type(scale) ~= "number" then
		typerror(1,"number")
	end
	gScaleFOV = scale
end
function exports.ScaleRatHeight(scale)
	gRatHeight = 0.07 * scale
end

-- exports (core)
function exports.GetPosition()
	if gForceStart or gFirstPerson[1] then
		local lp,lh = 0,0
		if not gForceStart then
			lp,lh = unpack(gFirstPerson)
		end
		if gDriving ~= -1 then
			local car = VehicleFromDriver(gPlayer)
			if VehicleIsValid(car) then
				return (vec3(VehicleGetPosXYZ(car)) + VehicleGetMatrix(car) * F_GetOffset(car,F_GetSeat(car))):unpack()
			end
		end
		return (vec3(F_GetHeadPos()) + Rz(lh) * vec3(0.01,-0.12,0.13)):unpack()
	end
	return 0,0,0
end
function exports.GetDirection()
	if gForceStart or gFirstPerson[1] then
		local lp,lh = 0,0
		if not gForceStart then
			lp,lh = unpack(gFirstPerson)
		end
		if gDriving ~= -1 then
			local car = VehicleFromDriver(gPlayer)
			if VehicleIsValid(car) then
				return (VehicleGetMatrix(car) * F_GetRotation(car,F_GetSeat(car)) * Rz(lh+math.pi) * Rx(-(lp-math.pi*0.5)) * vec3(0,0,1)):unpack()
			end
		end
		return (Rz(lh+math.pi) * Rx(-(lp-math.pi*0.5)) * vec3(0,0,1)):unpack()
	end
	return 0,1,0
end
function exports.GetTarget()
	local cx,cy,cz = exports.GetPosition()
	local dx,dy,dz = exports.GetDirection()
	return cx+dx,cy+dy,cz+dz
end
function exports.IsActive()
	return gForceStart or gFirstPerson[1]
end
function exports.Start()
	if not gFirstPerson[1] then
		gForceStart = true
	end
end
function exports.Stop()
	F_Reset()
end

-- user preferences
function F_LoadSettings()
	local data = GetPersistentDataTable("Xx_Yubari_xX").first_person or {}
	gControllerMult = tonumber(data.controller) or 2.5
	gMouseMult = tonumber(data.mouse) or 0.03
	gDynamic = tonumber(data.dynamic) or 1
	gFOV = tonumber(data.fov) or 90
end

-- main controller
function main()
	F_LoadSettings()
	while true do
		local vehicle = VehicleFromDriver(gPlayer)
		if not gFirstPerson[1] then
			if gForceStart or (IsButtonBeingPressed(2,0) and RunLocalEvent("first_person:Activate")) then
				-- attempt to activate first person
				if VehicleIsValid(vehicle) and CameraGetActive() == 1 then
					gDriving = vehicle
				elseif PedMePlaying(gPlayer,"DEFAULT_KEY",true) and (gForceStart or CameraGetActive() == 13) and not F_CancelWalking() then
					gWalking = true
				end
				if gWalking or gDriving ~= -1 then
					CameraSetActive(4)
					if CameraGetActive() == 4 then
						if gDriving ~= -1 then
							if dsl.fakecars and F_ShouldUseFakeCar(VehicleGetModelId(gDriving)) then
								dsl.fakecars.Register(gDriving)
							end
							gFirstPerson = {0,0} -- start driving camera at 0 since it's relative
						else
							local p,r,h = CameraGetRotation()
							gFirstPerson = {-(p-math.pi*0.5),h+math.pi} -- start walking camera using camera rotation
						end
						F_UpdateNearClip()
						gRatHeight = 0.07
						gScaleFOV = 1
						gSmoothFOV = gFOV
						gSpeed = {n = 0}
					else
						gWalking = false -- nevermind, failed to activate
						gDriving = -1
					end
				end
				gForceStart = false
			end
		elseif (IsButtonBeingPressed(3,0) and RunLocalEvent("first_person:Deactivate")) or CameraGetActive() ~= 4 then
			-- de-activate first person
			F_Reset()
		end
		if gFirstPerson[1] then
			-- invisible during first person
			PedSetAlpha(gPlayer,0,true)
			PedSetEntityFlag(gPlayer,11,false)
			if gWalking then
				-- update first person walking
				if F_AllowWalking() and not F_CancelWalking() then
					F_LookAround(gFirstPerson,nil)
					F_WalkingCamera(unpack(gFirstPerson))
				elseif VehicleIsValid(vehicle) and CameraGetActive() == 4 then -- from walking -> driving
					if PedMePlaying(gPlayer,"NC_LOCO",true) then
						PedSetActionNode(gPlayer,"/GLOBAL","")
					end
					gWalking = false
					if dsl.fakecars and F_ShouldUseFakeCar(VehicleGetModelId(vehicle)) then
						dsl.fakecars.Register(vehicle)
					end
					gFirstPerson = {F_TransitionDriving(vehicle,gFirstPerson[1],gFirstPerson[2])}
					gDriving = vehicle
				else
					F_Reset()
				end
			elseif gDriving ~= -1 then
				-- update first person driving
				if gDriving == vehicle and not (PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES",true) and PedMePlaying(gPlayer,"DISMOUNT",true)) then
					F_LookAround(gFirstPerson,vehicle)
					F_VehicleCamera(vehicle,unpack(gFirstPerson))
				elseif VehicleIsValid(vehicle) and CameraGetActive() == 4 and not F_CancelWalking() then -- from driving -> walking
					if dsl.fakecars then
						dsl.fakecars.Unregister(gDriving)
					end
					gDriving = -1
					gFirstPerson = {F_TransitionWalking(vehicle,gFirstPerson[1],gFirstPerson[2])}
					gWalking = true
				else
					F_Reset()
				end
			end
		end
		if SPEED_FOV_DEBUG then
			local speed = 0
			for _,v in ipairs(gSpeed) do
				speed = speed + v
			end
			if gSpeed.n > 0 then
				speed = speed / gSpeed.n
			end
			SetTextFont("Cascadia Code")
			SetTextBold()
			SetTextColor(0,0,0,255)
			SetTextOutline(0,255,0,255)
			SetTextAlign("C","T")
			SetTextPosition(0.5,0.1)
			DrawText("FOV: %.1f\nSpeed: %.2f",CameraGetFOV(),speed)
		end
		Wait(0)
	end
end
function MissionCleanup(s)
	if gPreviewOffset[1] then
		PlayerSetControl(1)
	end
	F_Reset()
end

-- reset stuff
function F_Reset()
	if gFirstPerson[1] then
		if gWalking then
			if PedMePlaying(gPlayer,"NC_LOCO",true) then
				PedSetActionNode(gPlayer,"/GLOBAL","")
			end
			gWalking = false
		elseif gDriving ~= -1 then
			if dsl.fakecars then
				dsl.fakecars.Unregister(gDriving)
			end
			gDriving = -1
		end
		CameraReset()
		CameraDefaultFOV()
		CameraAllowChange(true)
		CameraReturnToPlayer()
		PedSetAlpha(gPlayer,255,false)
		PedSetEntityFlag(gPlayer,11,true)
		gCamera = {}
	end
	gFirstPerson = {}
end

-- transition math
function F_TransitionDriving(vehicle,cp,ch)
	local vp,vr,vh = VehicleGetRotation(vehicle)
	cp,ch = cp-vp,ch-vh
	if cp < MINIMUM_PITCH then
		cp = MINIMUM_PITCH
	elseif cp > MAXIMUM_PITCH then
		cp = MAXIMUM_PITCH
	end
	while ch > math.pi do
		ch = ch - math.pi * 2
	end
	while ch <= -math.pi do
		ch = ch + math.pi * 2
	end
	if ch < -MAXIMUM_VEH_H then
		ch = -MAXIMUM_VEH_H
	elseif ch > MAXIMUM_VEH_H then
		ch = MAXIMUM_VEH_H
	end
	return cp,ch
end
function F_TransitionWalking(vehicle,cp,ch)
	local vp,vr,vh = VehicleGetRotation(vehicle)
	cp,ch = vp+cp,vh+ch
	if cp < MINIMUM_PITCH then
		cp = MINIMUM_PITCH
	elseif cp > MAXIMUM_PITCH then
		cp = MAXIMUM_PITCH
	end
	while ch > math.pi do
		ch = ch - math.pi * 2
	end
	while ch <= -math.pi do
		ch = ch + math.pi * 2
	end
	return cp,ch
end

-- look rotations
function F_LookAround(fp,vehicle)
	local x,y = 0,0
	local frame = GetFrameTime() * (math.pi * 0.5)
	if IsUsingJoystick(0) then
		x = GetStickValue(18,0) * gControllerMult * frame
		y = GetStickValue(19,0) * gControllerMult * frame
	elseif not dsl.radar or dsl.radar.ShouldAllowMouse() then
		x,y = GetMouseInput()
		x = -x * gMouseMult * frame
		y = -y * gMouseMult * frame
	end
	if x ~= 0 then
		fp[2] = fp[2] + x
		if not vehicle then
			while fp[2] > math.pi do
				fp[2] = fp[2] - math.pi * 2
			end
			while fp[2] <= -math.pi do
				fp[2] = fp[2] + math.pi * 2
			end
		elseif fp[2] < -MAXIMUM_VEH_H then
			fp[2] = -MAXIMUM_VEH_H
		elseif fp[2] > MAXIMUM_VEH_H then
			fp[2] = MAXIMUM_VEH_H
		end
	end
	if y ~= 0 then
		fp[1] = fp[1] + y
		if fp[1] < MINIMUM_PITCH then
			fp[1] = MINIMUM_PITCH
		elseif fp[1] > MAXIMUM_PITCH then
			fp[1] = MAXIMUM_PITCH
		end
	end
end

-- walking camera
function F_WalkingCamera(lp,lh)
	local cm = Rz(lh+math.pi) * Rx(-(lp-math.pi*0.5))
	local cx,cy,cz = (vec3(F_GetHeadPos()) + Rz(lh) * vec3(0.01,-0.12,0.13)):unpack()
	local dx,dy,dz = (cm * vec3(0,0,1)):unpack()
	CameraSetXYZ(cx,cy,cz,cx+dx,cy+dy,cz+dz)
	CameraSetNearPlane(0)
	CameraAllowChange(false)
	F_UpdateFOV(cx,cy,cz)
	gCamera = {cx,cy,cz,cm}
	if (PedMePlaying(gPlayer,"DEFAULT_KEY",true) or PedMePlaying(gPlayer,"NC_LOCO",true)) and not (PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES",true) and PedMePlaying(gPlayer,"MOVETOVEHICLE",true)) then
		local sh = F_GetSprint() -- sprint heading, if pushing a direction within a certain angle
		if PedIsModel(gPlayer,136) then
			lh = lh + math.atan2(GetStickValue(16,0),GetStickValue(17,0))
		elseif IsButtonBeingPressed(9,0) then
			PedSetActionNode(gPlayer,"/GLOBAL/WPROPS","")
		elseif IsButtonBeingPressed(8,0) then
			PedSetActionNode(gPlayer,"/GLOBAL/PLAYER/JUMPACTIONS","")
		elseif sh and IsButtonPressed(7,0) and not IsButtonPressed(10,0) then
			if PedMePlaying(gPlayer,"NC_LOCO",true) then
				PedSetActionNode(gPlayer,"/GLOBAL","")
			end
			lh = lh + sh
		elseif not PedMePlaying(gPlayer,"NC_LOCO",true) then
			PedSetActionNode(gPlayer,"/GLOBAL/PLAYER/DEFAULT_KEY/LOCOMOTION/GLOBALLOCO/LOCOMOTION/LOCOMOTIONEXECUTES/NONCOMBATSTRAFE/NC_LOCO","")
		end
		PedFaceHeading(gPlayer,math.deg(lh),0)
	end
end
function F_GetHeadPos()
	if PedIsModel(gPlayer,136) then
		local x,y,z = PlayerGetPosXYZ()
		return x,y,z+gRatHeight
	end
	return PedGetHeadPos(gPlayer)
end
function F_AllowWalking()
	return PedIsModel(gPlayer,136) or PedMePlaying(gPlayer,"DEFAULT_KEY",true) or PedMePlaying(gPlayer,"NC_LOCO",true) or PedIsPlaying(gPlayer,"/GLOBAL/PLAYER/JUMPACTIONS",true) or PedIsPlaying(gPlayer,"/GLOBAL/WPROPS/WALLCLIMB",true) or (PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES",true) and (PedMePlaying(gPlayer,"MOVETOVEHICLE") or PedMePlaying(gPlayer,"GETINVEHICLE") or PedMePlaying(gPlayer,"DISMOUNT",true)))
end
function F_CancelWalking()
	if IsButtonBeingPressed(6,0) or (IsButtonPressed(10,0) and IsButtonBeingPressed(9,0)) or PedGetFlag(gPlayer,2) or PedGetWeapon(gPlayer) ~= -1 then
		return true
	elseif IsButtonBeingPressed(11,0) or IsButtonBeingPressed(13,0) then
		return RunLocalEvent("first_person:WeaponSwitch")
	end
	return false
end
function F_GetSprint()
	local h = math.atan2(GetStickValue(16,0),GetStickValue(17,0))
	if math.abs(h) <= MAX_SPRINT_ANGLE then
		return h
	end
end

-- vehicle camera
function F_VehicleCamera(car,lp,lh)
	local seat = F_GetSeat(car)
	local car_pos = vec3(VehicleGetPosXYZ(car))
	local car_rot = VehicleGetMatrix(car)
	local cm = car_rot * F_GetRotation(car,seat) * Rz(lh+math.pi) * Rx(-(lp-math.pi*0.5))
	local cx,cy,cz = (car_pos + car_rot * F_GetOffset(car,seat)):unpack()
	local dx,dy,dz = (cm * vec3(0,0,1)):unpack()
	CameraSetXYZ(cx,cy,cz,cx+dx,cy+dy,cz+dz)
	CameraSetNearPlane(0)
	CameraAllowChange(false)
	F_UpdateFOV(cx,cy,cz)
	gCamera = {cx,cy,cz,cm}
	if dsl.fakecars then
		dsl.fakecars.Update(car)
	end
end

-- dynamic fov
function F_UpdateFOV(cx,cy,cz)
	if gDynamic > 0 then
		local frame = GetFrameTime()
		if gSpeed.x and frame > 0 then
			local target = gFOV
			local dx,dy,dz = cx-gSpeed.x,cy-gSpeed.y,cz-gSpeed.z
			local distance = math.sqrt(dx*dx+dy*dy+dz*dz)
			local speed = distance / frame
			local x = SPEED_FOV_DRIVING
			if gWalking then
				x = SPEED_FOV_WALKING
			elseif VehicleIsValid(gDriving) then
				local scar = VehicleGetSyncVehicle(gDriving)
				if scar and not IsSyncEntityOwned(scar) then
					speed = 0
				end
			end
			if distance < SPEED_SNAP then
				if gSpeed.n >= SPEED_COUNT then
					table.remove(gSpeed,1)
				end
				table.insert(gSpeed,speed)
			elseif gSpeed.n > 0 then
				gSmoothFOV = target
				gSpeed = {n = 0}
			end
			speed = 0
			for _,v in ipairs(gSpeed) do
				speed = speed + v
			end
			speed = speed / gSpeed.n
			if speed > x.minimum then
				target = target + x.fov * math.min(1, (speed - x.minimum) / (x.maximum - x.minimum)) * gDynamic
			end
			if gSmoothFOV < target then
				gSmoothFOV = gSmoothFOV + x.raise_rate * frame
				if gSmoothFOV > target then
					gSmoothFOV = target
				end
			elseif gSmoothFOV > target then
				gSmoothFOV = gSmoothFOV - x.lower_rate * frame
				if gSmoothFOV < target then
					gSmoothFOV = target
				end
			end
		end
		gSpeed.x,gSpeed.y,gSpeed.z = cx,cy,cz
	end
	return CameraSetFOV(gSmoothFOV*gScaleFOV)
end

-- fake cars
function F_ShouldUseFakeCar(model)
	return model == 275 or model == 276 or model >= 284
end

-- near clip
RegisterLocalEventHandler("TimecycleSwitcher:Apply",function()
	if gFirstPerson[1] then
		F_UpdateNearClip()
	end
end)
function F_UpdateNearClip()
	local mult = (2500 / 400) * 1.5
	for h = 0,23 do
		for s = 0,3 do
			for w = 0,5 do
				local tc = GetTimecycle(h,s,w)
				tc.nearfarratio = math.min(math.floor(tc.farclip*mult),65534)
			end
		end
	end
	for a = 0,23 do
		for i = 0,2 do
			local tc = GetExtraTimecycle(a,i)
			tc.nearfarratio = math.min(math.floor(tc.farclip*mult),65534)
		end
	end
end

-- disable buttons
RegisterLocalEventHandler("ControllerUpdating",function(c)
	if gWalking and c == 0 then
		SetButtonPressed(15,0,false)
	end
end)

-- override camera
RegisterLocalEventHandler("CameraUpdated",function()
	if gCamera[1] then
		local x,y,z,m = unpack(gCamera)
		CameraSetPosition(x,y,z)
		CameraSetMatrix(m)
	end
end)

-- offset stuff
RegisterNetworkEventHandler("first_person:AllowOffset",function()
	gCanOffset = true
end)
RegisterNetworkEventHandler("first_person:UpdateOffsets",function(offsets,rotations)
	F_ConvertOffsets(offsets)
	gOffsets = offsets
	gRotations = rotations
end)
function F_ConvertOffsets(offsets)
	for _,seats in pairs(offsets) do
		for i = 0,3 do
			seats[i] = vec3(unpack(seats[i])) -- convert tables to vectors
		end
	end
end
function F_GetOffset(vehicle,seat)
	if gPreviewOffset[1] then
		return vec3(unpack(gPreviewOffset))
	elseif dsl.propcars then
		local offsets = gOffsets[dsl.propcars.GetName(vehicle)]
		if offsets then
			return offsets[seat]
		end
	end
	return (gOffsets[VehicleGetModelId(vehicle)] or gOffsets[0])[seat]
end
function F_GetRotation(vehicle,seat)
	if dsl.propcars then
		local rotations = gRotations[dsl.propcars.GetName(vehicle)]
		if rotations then
			return RotationMatrix(unpack(rotations[seat]))
		end
	end
	return RotationMatrix(unpack((gRotations[VehicleGetModelId(vehicle)] or gRotations[0])[seat]))
end
function F_GetSeat(vehicle)
	for seat = 0,2 do
		if VehicleGetPassenger(vehicle,seat) == gPlayer then
			return seat
		end
	end
	return 3
end

-- f2menu stuff
RegisterLocalEventHandler("f2menu:Open",function(f_add)
	f_add({
		name = "First Person Options",
		description = "Configure the first person camera, which can be turned on by double tapping the zoom-in button.",
		thread = M_FirstPerson,
	})
	if gCanOffset then
		f_add({
			name = "First Person Offsets",
			description = "(admin only)\nAdjust first person camera offsets for vehicles.",
			thread = M_OffsetMenu,
		})
	end
end)
RegisterLocalEventHandler("f2menu:Close",function()
	if gPreviewOffset[1] then
		PlayerSetControl(1)
		gPreviewOffset = {}
	end
end)
function M_FirstPerson(parent,selected)
	local menu = parent:submenu(selected.name)
	while menu:active() do
		if menu:option("Base FOV","["..gFOV.."]","The base value for the field-of-view.") then
			O_SetGlobal(menu,"fov","gFOV","%.0f",85,120,1)
		elseif menu:option("Dynamic FOV",({[0]="[OFF]","[NORMAL]","[STRONG]"})[gDynamic],"If FOV should adjust with speed.") then
			gDynamic = math.mod(gDynamic+1,3)
			if gDynamic == 0 then
				gSmoothFOV = gFOV
				gSpeed = {n = 0}
			end
			F_SaveGlobal(getfenv(1),"dynamic","gDynamic")
		elseif menu:option("Controller Sensitivity",string.format("[x%.1f]",gControllerMult),"Sensitivity multiplier for looking around with a controller.") then
			O_SetGlobal(menu,"controller","gControllerMult","%.1f",0.5,10,0.5)
		elseif menu:option("Mouse Sensitivity",string.format("[x%.3f]",gMouseMult),"Sensitivity multiplier for looking around with the mouse.") then
			O_SetGlobal(menu,"mouse","gMouseMult","%.3f",0.002,0.12,0.002)
		elseif menu:option("Restore Defaults",nil,"Restore default settings.") then
			GetPersistentDataTable("Xx_Yubari_xX").first_person = nil
			SavePersistentDataTables()
			F_LoadSettings()
			if gDynamic == 0 then
				gSmoothFOV = gFOV
				gSpeed = {n = 0}
			end
		end
		menu:draw()
		Wait(0)
	end
end
function F_SaveGlobal(env,save,key)
	local persist = GetPersistentDataTable("Xx_Yubari_xX") -- .first_person = {...}
	local data = persist.first_person
	if data then
		data[save] = env[key]
	else
		persist.first_person = {[save] = env[key]}
	end
	SavePersistentDataTables()
end
function O_SetGlobal(menu,save,key,fmt,minimum,maximum,step)
	local env = getfenv(2)
	local value = env[key]
	while menu:active() do
		menu:draw(string.format("> "..fmt.." <",env[key]))
		Wait(0)
		if menu:left() then
			break
		elseif menu:right() then
			F_SaveGlobal(env,save,key)
			return
		elseif menu:up() then
			env[key] = (math.floor(env[key] / step) + 1) * step
			if env[key] > maximum then
				env[key] = maximum
			end
			if key == "gFOV" then
				gSmoothFOV = gFOV
				gSpeed = {n = 0}
			end
		elseif menu:down() then
			env[key] = (math.ceil(env[key] / step) - 1) * step
			if env[key] < minimum then
				env[key] = minimum
			end
			if key == "gFOV" then
				gSmoothFOV = gFOV
				gSpeed = {n = 0}
			end
		end
	end
	env[key] = value
end
function M_OffsetMenu(parent)
	local menu = parent:submenu("First Person Offsets","Any car with a note starting with \"done\" is shown as [DONE]. Others still need configured.")
	local keys = {}
	local names = {
		"bmxrace","retro","crapbmx","bikecop","Scooter","bike","custombike","banbike","mtnbike","oladbike","racer","aquabike",
		"Mower","Arc_3","taxicab","Arc_2","Dozer","GoCart","Limo","Dlvtruck","Foreign","cargreen","70wagon","policecar","domestic","Truck","Arc_1"
	}
	for m = 272,298 do
		table.insert(keys,{"["..m.."] "..names[m-271],m})
	end
	if dsl.propcars then
		for _,name in ipairs(dsl.propcars.GetNames()) do
			table.insert(keys,{name,name})
		end
	end
	while menu:active() do
		local vehicle = VehicleFromDriver(gPlayer)
		if VehicleIsValid(vehicle) and menu:option("< current vehicle >") then
			local key
			if dsl.propcars then
				key = dsl.propcars.GetName(vehicle)
			end
			M_AdjustOffsets(menu,key or VehicleGetModelId(vehicle))
		end
		for _,v in ipairs(keys) do
			local offsets = gOffsets[v[2]]
			if offsets and offsets.note then
				if not v[3] then
					if string.find(offsets.note,"^done") then
						v[3] = "[DONE]"
					else
						v[3] = "[NOTE]"
					end
				end
			elseif v[3] then
				v[3] = nil
			end
		end
		for _,v in ipairs(keys) do
			if menu:option(v[1],v[3]) then
				M_AdjustOffsets(menu,v[2])
			end
		end
		menu:draw()
		Wait(0)
	end
end
function M_AdjustOffsets(parent,key)
	local seats = {[0] = "FL","FR","BR","BL"}
	local menu = parent:submenu("Adjust Offsets")
	local description = "."..key
	local note
	if type(key) == "number" then
		description = "["..key.."]"
	elseif string.find(key,"[^%w_]") or string.find(key,"^%d") then
		description = "[\""..key.."\"]"
	end
	if gOffsets[key] then
		note = gOffsets[key].note
	end
	description = "gOffsets"..description
	if note then
		menu:help(description.."\n"..note)
	else
		menu:help(description)
	end
	while menu:active() do
		for i = 0,3 do
			if menu:option("Adjust Seat ["..i.." ("..seats[i]..")]") then
				M_AdjustSeat(menu,key,i)
			end
		end
		if menu:option("Mirror L2R") then
			while menu:active() do
				menu:draw("[SURE?]")
				Wait(0)
				if menu:right() then
					SendNetworkEvent("first_person:MirrorOffsets",key,seat)
					break
				elseif menu:left() then
					break
				end
			end
		elseif menu:option("Set Note") then
			note = O_NoteOffset(menu,key,note)
			if note then
				menu:help(description.."\n"..note)
			end
		end
		menu:draw()
		Wait(0)
	end
end
function M_AdjustSeat(parent,key,seat)
	local menu = parent:submenu("Adjust Seat ["..seat.."]")
	local rotation = {0,0,0,0}
	if gRotations[key] then
		rotation = gRotations[key][seat]
	end
	while menu:active() do
		if menu:option("Adjust Offset") then
			O_AdjustOffset(menu,key,seat)
		elseif menu:option("Adjust Pitch",string.format("[%.1f]",math.deg(rotation[1]))) then
			O_AdjustRotation(menu,key,seat,rotation,1)
		elseif menu:option("Adjust Roll",string.format("[%.1f]",math.deg(rotation[2]))) then
			O_AdjustRotation(menu,key,seat,rotation,2)
		elseif menu:option("Adjust Yaw",string.format("[%.1f]",math.deg(rotation[3]))) then
			O_AdjustRotation(menu,key,seat,rotation,3)
		elseif menu:option("Rotation Order",({[0]="ZYX","YZX","ZXY","XZY","YXZ","XYZ"})[rotation[4]]) then
			rotation[4] = math.mod(rotation[4]+1,6)
			SendNetworkEvent("first_person:AdjustRotation",key,seat,unpack(rotation))
		elseif menu:option("Default Rotation") then
			SendNetworkEvent("first_person:AdjustRotation",key,seat,0,0,0,2)
			rotation = {0,0,0,2}
		end
		menu:draw()
		Wait(0)
	end
end
function O_NoteOffset(menu,key,note)
	local typing = StartTyping(note)
	if not typing then
		return note
	end
	while menu:active() do
		local text = GetTypingString(typing,true)
		SetTextFont("Arial")
		SetTextBlack()
		SetTextColor(230,230,230,255)
		SetTextShadow()
		SetTextAlign("C","C")
		SetTextPosition(0.5,0.2)
		SetTextWrapping(0.5/GetDisplayAspectRatio())
		DrawText(text)
		menu:draw("[TYPING]")
		Wait(0)
		if not IsTypingActive(typing) then
			if not WasTypingAborted(typing) then
				note = GetTypingString(typing)
				if note == "" then
					SendNetworkEvent("first_person:NoteOffset",key)
				else
					SendNetworkEvent("first_person:NoteOffset",key,note)
				end
			end
			break
		end
	end
	if IsTypingActive(typing) then
		StopTyping(typing)
	end
	return note
end
function O_AdjustOffset(menu,key,seat)
	if gOffsets[key] then
		gPreviewOffset = {(gOffsets[key][seat]):unpack()}
	else
		gPreviewOffset = {0,0,0}
	end
	while menu:active() and gPreviewOffset[1] do
		SetTextFont("Arial")
		SetTextBlack()
		SetTextColor(240,240,128,255)
		SetTextShadow()
		SetTextAlign("C","C")
		SetTextPosition(0.5,0.2)
		DrawText("{%.3f, %.3f, %.3f}",unpack(gPreviewOffset))
		SetTextFont("Arial")
		SetTextBlack()
		SetTextColor(230,230,230,255)
		SetTextShadow()
		SetTextAlign("C","C")
		SetTextPosition(0.5,0.9)
		DrawText("[Z] Zero Offset | [W/A/S/D] Move XY | [T/G] Move Z\n[SHIFT] Move Faster | [CTRL] Move Slower\n[LEFT] Cancel | [RIGHT] Confirm")
		menu:draw("[ACTIVE]")
		PlayerSetControl(0)
		Wait(0)
		if menu:right() then
			if gPreviewOffset[1] then
				SendNetworkEvent("first_person:AdjustOffset",key,seat,unpack(gPreviewOffset))
			end
			break
		elseif menu:left() then
			break
		elseif gPreviewOffset[1] then
			F_AdjustOffset(gPreviewOffset)
		end
	end
	if gPreviewOffset[1] then
		PlayerSetControl(1)
		gPreviewOffset = {}
	end
end
function F_AdjustOffset(off)
	local speed = GetFrameTime() * 0.1
	if IsKeyBeingPressed("Z") then
		off[1],off[2],off[3] = 0,0,0
	end
	if IsKeyPressed("LSHIFT") then
		speed = speed * 4
	end
	if IsKeyPressed("LCONTROL") then
		speed = speed * 0.2
	end
	if IsKeyPressed("W") then
		off[2] = off[2] + speed
	end
	if IsKeyPressed("A") then
		off[1] = off[1] - speed
	end
	if IsKeyPressed("S") then
		off[2] = off[2] - speed
	end
	if IsKeyPressed("D") then
		off[1] = off[1] + speed
	end
	if IsKeyPressed("T") then
		off[3] = off[3] + speed
	end
	if IsKeyPressed("G") then
		off[3] = off[3] - speed
	end
end
function O_AdjustRotation(menu,key,seat,rotation,index)
	local typing = StartTyping()
	if not typing then
		return
	end
	while menu:active() do
		if not IsTypingActive(typing) then
			if not WasTypingAborted(typing) then
				local value = tonumber(GetTypingString(typing))
				if value and value > -360 and value < 360 then
					rotation[index] = math.rad(value)
					SendNetworkEvent("first_person:AdjustRotation",key,seat,unpack(rotation))
				end
			end
			break
		end
		menu:draw(GetTypingString(typing,true))
		Wait(0)
	end
end

-- convert offsets
F_ConvertOffsets(gOffsets)

-- request permissions
SendNetworkEvent("first_person:RequestOffset")

-- run main as PRE_GAME (before most other scripts)
CreateAdvancedThread("PRE_GAME",main)
main = nil
