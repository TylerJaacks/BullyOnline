LoadScript("vehicles.lua")

GET_IN_RANGE = 4 -- range you can start moving to a vehicle to get in
GET_IN_DETECT = 5 -- range to find vehicles you're trying to get in

GET_IN_ANGLE = math.rad(120)
GET_IN_BACK_ANGLE = math.rad(135)

PICKUP_ANGLE = math.rad(30) -- angle of vehicle pitch or roll to need to pickup motorcycles

HORN_DELAY = 2000
LOCK_DELAY = 500
ENGINE_DELAY = 1000
STARTUP_DELAY = 750 -- after turning engine back on
STATIC_SPEED = 0.5 -- speed a car goes static after engine off

LOCK_ANIM_SECS = 0.55
LOCK_ANIM_SIZE = 0.1
LOCK_ANIM_ALPHA = 200
LOCK_ANIM_SCALE = 0.4
LOCK_ANIM_FADE_IN = 0.25
LOCK_ANIM_SWITCH = 0.35
LOCK_ANIM_HOLD = 0.15
LOCK_ANIM_FADE_OUT = 0.25

gLockAnim = {} -- {vehicle, unlock, sound, bank}
gPlaySound = {} -- {vehicle, sound, bank}
gHornSounds = {} -- {[scar] = true}
gWantHorn = false

gCancelButton = false

gTrackEngine = -1
gTurnOnAsap = -1 -- gTurnOnTimer is also set when this isn't -1

gCanBrake = false -- while coasting after turning engine off

gRequesting = -1
gEnterVehicle = -1
gEnterSeat = 0
gWalkingVehicle = -1
gWalkingSeat = 0

-- events
RegisterNetworkEventHandler("vehicles:AllowVehicle",function(scar,seat)
	local vehicle = VehicleFromSyncVehicle(scar)
	if VehicleIsValid(vehicle) then
		gEnterVehicle = vehicle
		gEnterSeat = seat
	end
	gRequesting = -1
end)
RegisterNetworkEventHandler("vehicles:DenyVehicle",function(locked)
	if locked then
		gPlaySound = {-1,"SCDOOR_Open","SNDDoors.bnk"}
	end
	gRequesting = -1
end)
RegisterNetworkEventHandler("vehicles:LockVehicle",function(unlock)
	if unlock == nil then
		gPlaySound = {-1,"SprinklerSwitch","Sprinklr.bnk"} -- wrong key
	elseif unlock then
		--gLockAnim = {gRequesting,false,"LockerDoorOpen","LckPick.bnk"} -- unlocked
		gLockAnim = {gRequesting,false,"LckOpen","LckPick.bnk"} -- unlocked
	else
		gLockAnim = {gRequesting,true,"LockerDoorClose","LckPick.bnk"} -- locked
	end
	gRequesting = -1
end)
RegisterNetworkEventHandler("vehicles:LockSound",function(scar,unlock)
	local vehicle = VehicleFromSyncVehicle(scar)
	if VehicleIsValid(vehicle) then
		if unlock then
			gPlaySound = {vehicle,"LckOpen","LckPick.bnk"} -- unlocked
		else
			gPlaySound = {vehicle,"LockerDoorClose","LckPick.bnk"} -- locked
		end
	end
end)
RegisterNetworkEventHandler("vehicles:HornSound",function(scar)
	gHornSounds[scar] = true
end)
RegisterNetworkEventHandler("vehicles:EngineSound",function(scar,on)
	local vehicle = VehicleFromSyncVehicle(scar)
	if VehicleIsValid(vehicle) then
		if on then
			gPlaySound = {vehicle,"K1_EngStart","GoKart01.bnk"}
		else
			gPlaySound = {vehicle,"K1_EngStop","GoKart01.bnk"}
		end
	end
end)

-- engine
RegisterLocalEventHandler("VehicleStartEngine",function(vehicle)
	if vehicle == gTrackEngine then
		local ped = VehicleGetPassenger(vehicle,0)
		if PedIsValid(ped) and (ped ~= gPlayer or not IsButtonPressed(15,0)) then
			local scar = VehicleGetSyncVehicle(vehicle)
			if not scar or IsSyncEntityOwned(scar) then
				return false
			end
			gTurnOnTimer = GetTimer()
			gTurnOnAsap = vehicle
		end
	end
	return F_HasEngine(vehicle) -- if the vehicle doesn't "have" an engine we won't do anything
end)
RegisterLocalEventHandler("VehicleStopEngine",function(vehicle)
	if PedIsValid(VehicleGetPassenger(vehicle,0)) then
		return F_HasEngine(vehicle)
	end
	return false
end)

-- keys
RegisterLocalEventHandler("inventory:Use",function(slot,id)
	if gKeyItems[id] then
		if PedMePlaying(gPlayer,"DEFAULT_KEY",true) and PedGetWeapon(gPlayer) == -1 then
			dsl.inventory.Equip(slot)
		end
		return true
	end
end)

-- main
function main()
	local horn_disable
	local exit_button = false
	local horn_delay
	local lock_delay
	local engine_delay
	local start_up
	CreateThread("T_Keys")
	CreateThread("T_Lock")
	CreateThread("T_Engine")
	while true do
		local now = GetTimer()
		local current = VehicleFromDriver(gPlayer)
		if exit_button and not IsButtonPressed(9,0) and not IsButtonBeingReleased(9,0) then
			exit_button = false
		end
		if horn_delay and now - horn_delay >= HORN_DELAY then
			horn_delay = nil
		end
		if lock_delay and now - lock_delay >= LOCK_DELAY then
			lock_delay = nil
		end
		if engine_delay and now - engine_delay >= ENGINE_DELAY then
			engine_delay = nil
		end
		if starting_up and now - starting_up >= STARTUP_DELAY then
			if VehicleIsValid(current) and F_HasEngine(current) then
				VehicleEnableEngine(current,true)
			end
			starting_up = nil
		end
		if VehicleIsValid(current) and VehicleIsModel(current,276) and dsl.propcars and dsl.propcars.HasCustomHorn(current) then
			if not horn_disable then
				horn_disable = RegisterLocalEventHandler("ControllerUpdating",CB_DisableHorn)
			end
		elseif horn_disable then
			RemoveEventHandler(horn_disable)
			horn_disable = nil
			gWantHorn = false
		end
		if gEnterVehicle ~= -1 then
			if PedMePlaying(gPlayer,"DEFAULT_KEY",true) and VehicleIsValid(gEnterVehicle) and PedCanEnterVehicle(gPlayer,gEnterVehicle,gEnterSeat) and F_GetTargetVehicle(GET_IN_DETECT) == gEnterVehicle then
				F_EnterVehicle(gEnterVehicle,gEnterSeat)
				while PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES",true) and PedMePlaying(gPlayer,"GETINVEHICLE",true) do
					Wait(0)
				end
			end
			gEnterVehicle = -1
		elseif VehicleIsValid(current) then
			if IsButtonBeingPressed(9,0) then
				for seat = 0,3 do
					if VehicleGetPassenger(current,seat) == gPlayer then
						F_ExitVehicle(current,seat)
						break
					end
				end
				exit_button = true
			elseif VehicleGetPassenger(current,0) == gPlayer then
				if not horn_delay and (gWantHorn or IsButtonBeingPressed(8,0)) then
					local model = VehicleGetModelId(current)
					if model ~= 275 and model ~= 295 then
						local scar = VehicleGetSyncVehicle(current)
						if scar then
							SendNetworkEvent("vehicles:HonkVehicle",scar)
						end
						F_HonkVehicle(current)
						horn_delay = now
					elseif VehicleGetSiren(current) then
						VehicleEnableSiren(current,false)
						--VehicleSirenAllwaysOn(current,false)
					elseif not dsl.propcars or not dsl.propcars.PlayHorn(current) then
						VehicleEnableSiren(current,true)
						--VehicleSirenAllwaysOn(current,true)
					end
				elseif not lock_delay and not gLockAnim[1] and not (PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES",true) and PedMePlaying(gPlayer,"DISMOUNT",true)) and IsButtonBeingPressed(0,0) then
					local scar = VehicleGetSyncVehicle(current)
					if scar then
						SendNetworkEvent("vehicles:LockVehicle",scar)
						gRequesting = current
					end
					lock_delay = now
				elseif not engine_delay and not starting_up and IsButtonBeingPressed(15,0) and F_HasEngine(current) then
					local scar = VehicleGetSyncVehicle(current)
					if VehicleGetEngine(current) then
						if scar then
							SendNetworkEvent("vehicles:SwitchEngine",scar)
						end
						VehicleEnableEngine(current,false)
						F_PlaySound("K1_EngStop","GoKart01.bnk")
					else
						if scar then
							SendNetworkEvent("vehicles:SwitchEngine",scar,true)
						end
						F_PlaySound("K1_EngStart","GoKart01.bnk")
						starting_up = now
					end
					engine_delay = now
				end
			end
		elseif PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES",true) and (PedMePlaying(gPlayer,"VEHICLES_CARRIDE",true) or PedMePlaying(gPlayer,"VEHICLES_RIDE",true)) then
			PedSetActionNode(gPlayer,"/GLOBAL","")
		elseif PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES",true) and PedMePlaying(gPlayer,"GETINVEHICLE",true) then
			local vehicle = F_GetTargetVehicle(GET_IN_DETECT)
			if VehicleIsValid(vehicle) and F_IsLockable(vehicle) then
				local seat = PedMePlaying(gPlayer,"DRIVER",true) and 0 or 1
				PedSetActionNode(gPlayer,"/GLOBAL","")
				if VehicleIsBike(vehicle) then
					PlayerDetachFromVehicle()
				else
					PedWarpOutOfCar(gPlayer) -- important this is after setting /GLOBAL
				end
				if gRequesting == -1 then
					F_RequestVehicle(vehicle,seat)
				end
			end
		elseif gWalkingVehicle ~= -1 then
			if not VehicleIsValid(gWalkingVehicle) then
				gWalkingVehicle = -1
			elseif not (PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES",true) and PedMePlaying(gPlayer,"MOVETOVEHICLE",true)) then
				if PedMePlaying(gPlayer,"DEFAULT_KEY",true) and F_GetTargetVehicle(GET_IN_DETECT) == gWalkingVehicle and gRequesting == -1 then
					F_RequestVehicle(gWalkingVehicle,gWalkingSeat)
				end
				gWalkingVehicle = -1
			end
		elseif exit_button then
			if PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES",true) and PedMePlaying(gPlayer,"MOVETOVEHICLE",true) then
				PedSetActionNode(gPlayer,"/GLOBAL","")
			end
		elseif IsButtonBeingReleased(9,0) and not IsButtonPressed(10,0) and PedMePlaying(gPlayer,"DEFAULT_KEY",true) then
			local vehicle = F_GetTargetVehicle(GET_IN_RANGE)
			if VehicleIsValid(vehicle) then
				local seat = F_GetTargetSeat(vehicle)
				if not F_ShouldVehicleWarp(vehicle) then
					F_MoveToVehicle(vehicle,seat)
				elseif gRequesting == -1 then
					F_RequestVehicle(vehicle,seat)
				end
			end
		end
		Wait(0)
	end
end
function CB_DisableHorn(c)
	if c == 0 then
		gWantHorn = IsButtonPressed(8,0)
		SetButtonPressed(8,0,false)
	end
end
function T_Keys()
	while true do
		if dsl.inventory and gKeyItems[dsl.inventory.GetEquipped()] and (PedGetWeapon(gPlayer) ~= -1 or (not PedMePlaying(gPlayer,"DEFAULT_KEY",true) and not (PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES",true) and PedMePlaying(gPlayer,"MOVETOVEHICLE",true)))) then
			dsl.inventory.Unequip()
		end
		if gPlaySound[1] then
			if gPlaySound[1] == -1 then
				F_PlaySound(gPlaySound[2],gPlaySound[3])
			elseif VehicleIsValid(gPlaySound[1]) then
				local x,y,z = VehicleGetPosXYZ(gPlaySound[1])
				if dsl.sounds then
					dsl.sounds.Play3D(x,y,z,gPlaySound[2],gPlaySound[3])
				else
					SoundPlay3D(x,y,z,gPlaySound[2])
				end
			end
			gPlaySound = {}
		end
		for scar in pairs(gHornSounds) do
			local vehicle = VehicleFromSyncVehicle(scar)
			if VehicleIsValid(vehicle) then
				F_HonkVehicle(vehicle)
			end
			gHornSounds[scar] = nil
		end
		Wait(0)
	end
end

-- lock animation
function T_Lock()
	while true do
		if gLockAnim[1] then
			if VehicleIsValid(gLockAnim[1]) then
				F_Lock(unpack(gLockAnim))
			end
			gLockAnim = {}
		end
		Wait(0)
	end
end
function F_Lock(vehicle,lock,sound,bank)
	local image = CreateTexture("lock.png")
	local progress = GetFrameTime() / LOCK_ANIM_SECS
	local alpha,switch = 0,0
	if lock then
		switch = 1
	end
	while VehicleIsValid(vehicle) and progress < 1 do
		local sx,sy = 0.5,0.9
		if VehicleFromDriver(gPlayer) ~= vehicle then
			local px,py,pz = PedGetHeadPos(gPlayer)
			local vx,vy,vz = VehicleGetPosXYZ(vehicle)
			local dx,dy,dz = vx-px,vy-py,vz-pz
			sx,sy = GetScreenCoords(px+dx*0.5,py+dy*0.5,pz+dz*0.5)
		end
		if progress <= LOCK_ANIM_FADE_IN then
			alpha = progress / LOCK_ANIM_FADE_IN
		elseif progress <= LOCK_ANIM_FADE_IN + LOCK_ANIM_SWITCH then
			alpha = 1
			switch = (progress - LOCK_ANIM_FADE_IN) / LOCK_ANIM_SWITCH
			if lock then
				switch = 1 - switch
			end
			if sound then
				F_PlaySound(sound,bank)
				sound = nil
				bank = nil
			end
		elseif progress <= LOCK_ANIM_FADE_IN + LOCK_ANIM_SWITCH + LOCK_ANIM_HOLD then
			if lock then
				switch = 0
			else
				switch = 1
			end
		elseif progress <= LOCK_ANIM_FADE_IN + LOCK_ANIM_SWITCH + LOCK_ANIM_HOLD + LOCK_ANIM_FADE_OUT then
			alpha = 1 - (progress - (LOCK_ANIM_FADE_IN + LOCK_ANIM_SWITCH + LOCK_ANIM_HOLD)) / LOCK_ANIM_FADE_OUT
		end
		if sx then
			local ratio = GetTextureDisplayAspectRatio(image)
			local x = sx - (LOCK_ANIM_SIZE * 0.5) * ratio
			local y = sy - LOCK_ANIM_SIZE * 0.5
			local w = LOCK_ANIM_SIZE * ratio
			local h = LOCK_ANIM_SIZE
			if alpha ~= 1 then
				local scale = LOCK_ANIM_SCALE * (1 - alpha)
				x = x + (w * scale) * 0.5
				y = y + (h * scale) * 0.5
				w = w * (1 - scale)
				h = h * (1 - scale)
			end
			SetTextureBounds(image,0.5,0.5,1,1)
			DrawTexture(image,x+(w*switch)*1.3,y,w*(1-switch*2),h,255,255,255,alpha*LOCK_ANIM_ALPHA)
			SetTextureBounds(image,0,0,0.5,0.5)
			DrawTexture(image,x,y,w,h,255,255,255,alpha*LOCK_ANIM_ALPHA)
			SetTextureBounds(image,0,0.5,0.5,1)
			DrawTexture(image,x,y,w,h,255,255,255,alpha*math.max(0,1-switch)*LOCK_ANIM_ALPHA)
			SetTextureBounds(image,0.5,0,1,0.5)
			DrawTexture(image,x,y,w,h,255,255,255,alpha*math.min(1,switch)*LOCK_ANIM_ALPHA)
		end
		Wait(0)
		progress = progress + GetFrameTime() / LOCK_ANIM_SECS
	end
end

-- honk vehicle
function F_HonkVehicle(vehicle)
	if not dsl.propcars or not dsl.propcars.PlayHorn(vehicle) then
		VehicleUseHorn(vehicle)
	end
end

-- engine off
function T_Engine()
	local tracking,vx,vy,vz = -1
	local event
	while true do
		local vehicle = VehicleFromDriver(gPlayer)
		if VehicleIsValid(vehicle) and PedIsValid(VehicleGetPassenger(vehicle,0)) and not VehicleGetEngine(vehicle) and F_HasEngine(vehicle) then
			local nx,ny,nz = VehicleGetPosXYZ(vehicle)
			gCanBrake = false
			if tracking == vehicle then
				local status = VehicleGetStatus(vehicle)
				if status == 0 or status == 7 then
					local dx,dy,dz = nx-vx,ny-vy,nz-vz
					local speed = math.sqrt(dx*dx+dy*dy+dz*dz) / GetFrameTime()
					if speed <= STATIC_SPEED then
						VehicleSetStatus(vehicle,2)
					end
					dx,dy,dz = (TransposeMatrix(VehicleGetMatrix(vehicle))*vec3(dx,dy,dz)):unpack()
					gCanBrake = dy > 0
				end
			else
				tracking = vehicle
			end
			if VehicleGetStatus(vehicle) == 2 then
				if event then
					RemoveEventHandler(event)
					event = nil
				end
			elseif not event then
				event = RegisterLocalEventHandler("ControllerUpdating",CB_ControllerUpdating)
			end
			vx,vy,vz = nx,ny,nz
		elseif tracking ~= -1 then
			if event then
				RemoveEventHandler(event)
				event = nil
			end
			tracking = -1
		end
		if gTurnOnAsap ~= -1 then
			if vehicle == gTurnOnAsap and not VehicleGetEngine(vehicle) and GetTimer() - gTurnOnTimer < 2000 then
				local scar = VehicleGetSyncVehicle(vehicle)
				if not scar or IsSyncEntityOwned(scar) then
					if F_HasEngine(vehicle) then
						VehicleEnableEngine(vehicle,true)
					end
					gTurnOnTimer = nil
					gTurnOnAsap = -1
				end
			else
				gTurnOnTimer = nil
				gTurnOnAsap = -1
			end
		end
		F_TrackEngine(PedGetTargetVehicle(gPlayer))
		Wait(0)
	end
end
function F_HasEngine(vehicle)
	local model = VehicleGetModelId(vehicle)
	if VehicleIsBike(vehicle) and model ~= 275 and model ~= 276 then
		return false
	elseif dsl.propcars then
		local engine = dsl.propcars.HasEngine(vehicle)
		if engine ~= nil then
			return engine
		end
	end
	return true
end
function F_TrackEngine(vehicle)
	if VehicleIsValid(vehicle) and not PedIsValid(VehicleGetPassenger(vehicle,0)) then
		gTrackEngine = vehicle
	elseif gTrackEngine ~= -1 then
		gTrackEngine = -1
	end
end
function CB_ControllerUpdating(c)
	if c == 0 then
		if not gCanBrake then
			SetButtonPressed(6,0,false)
		end
		SetButtonPressed(7,0,false)
	end
end

-- target vehicle
function F_GetTargetVehicle(range)
	local h1 = PedGetHeading(gPlayer)
	local x1,y1,z1 = PlayerGetPosXYZ()
	local nearest,distance = -1,range*range
	for scar in AllSyncVehicles() do
		local veh = VehicleFromSyncVehicle(scar)
		if VehicleIsValid(veh) then
			local x2,y2,z2 = VehicleGetPosXYZ(veh)
			local dx,dy,dz = x2-x1,y2-y1,z2-z1
			local dist = dx*dx+dy*dy+dz*dz
			if dist < distance then
				local h2 = math.atan2(-dx,dy)
				local angle = F_Rotation(h2 - h1)
				if math.abs(angle) < GET_IN_ANGLE then
					nearest,distance = veh,dist
				end
			end
		end
	end
	return nearest
end
function F_GetTargetSeat(vehicle)
	local seats = F_GetMaxSeats(vehicle)
	local vp,vr,vh = VehicleGetRotation(vehicle)
	local vx,vy = VehicleGetPosXYZ(vehicle)
	local px,py = PlayerGetPosXYZ()
	local h = F_Rotation(math.atan2(vx-px,py-vy) - vh)
	if seats > 1 then
		if h < 0 then
			if PedIsValid(VehicleGetPassenger(vehicle,1)) and seats > 2 then
				return 2 -- target back right, because front right is taken
			elseif PedIsValid(VehicleGetPassenger(vehicle,2)) then
				return 1 -- target front right, because back right is taken
			elseif h <= -GET_IN_BACK_ANGLE and seats > 2 then
				return 2 -- target back right, because you're nearest
			end
			return 1 -- target front right, because no other
		elseif PedIsValid(VehicleGetPassenger(vehicle,0)) and seats > 3 then
			return 3 -- target back left, because front left is taken
		elseif PedIsValid(VehicleGetPassenger(vehicle,3)) then
			return 0 -- target front left, because back left is taken
		elseif h >= GET_IN_BACK_ANGLE and seats > 3 then
			return 3
		end
	end
	return 0
end

-- vehicle interactions
function F_MoveToVehicle(vehicle,seat)
	local node = F_GetMoveNode(vehicle)
	if node then
		PedEnterVehicle(gPlayer,vehicle)
		if seat == 0 or seat == 3 then
			PedSetActionNode(gPlayer,string.format(node,"MOVETOVEHICLELHS"),"")
		else
			PedSetActionNode(gPlayer,string.format(node,"MOVETOVEHICLERHS"),"")
		end
		if PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES",true) and PedMePlaying(gPlayer,"MOVETOVEHICLE",true) then
			gWalkingVehicle = vehicle
			gWalkingSeat = seat
		end
	end
end
function F_RequestVehicle(vehicle,seat)
	if F_IsLockable(vehicle) then
		local scar = VehicleGetSyncVehicle(vehicle)
		if scar and PedCanEnterVehicle(gPlayer,vehicle,seat) then
			local id,data,slot
			if dsl.inventory then
				id,data,slot = dsl.inventory.GetEquipped()
			end
			if gKeyItems[id] then
				SendNetworkEvent("vehicles:EnterVehicle",scar,seat,slot)
				dsl.inventory.Unequip()
			else
				SendNetworkEvent("vehicles:EnterVehicle",scar,seat)
			end
			gRequesting = vehicle
		end
	elseif PedCanEnterVehicle(gPlayer,vehicle,seat) then
		F_EnterVehicle(vehicle,seat)
	end
end
function F_EnterVehicle(vehicle,seat)
	if seat < 2 and not F_ShouldVehicleWarp(vehicle) then
		local node = F_GetEnterNode(vehicle)
		PedEnterVehicle(gPlayer,vehicle)
		if node then
			local vp,vr,vh = VehicleGetRotation(vehicle)
			PedFaceHeading(gPlayer,math.deg(vh),0)
			if seat == 0 then
				PedSetActionNode(gPlayer,string.format(node,"LEFTHANDSIDE"),"")
			else
				PedSetActionNode(gPlayer,string.format(node,"RIGHTHANDSIDE"),"")
			end
		end
	elseif VehicleIsBike(vehicle) then
		PedPutOnBike(gPlayer,vehicle)
	else
		F_TrackEngine(vehicle)
		PedWarpIntoCar(gPlayer,vehicle,seat)
	end
end
function F_ExitVehicle(vehicle,seat)
	if not F_ShouldVehicleWarp(vehicle) or F_IsMotorcycle(vehicle) then
		local scar = VehicleGetSyncVehicle(vehicle)
		local node = F_GetExitNode(vehicle)
		if scar then
			SendNetworkEvent("vehicles:ExitVehicle",scar)
		end
		if node then
			if seat == 2 then
				PlayerSetPosSimple((vec3(PlayerGetPosXYZ())+VehicleGetMatrix(vehicle)*vec3(0.5,0,0)):unpack())
			elseif seat == 3 then
				PlayerSetPosSimple((vec3(PlayerGetPosXYZ())+VehicleGetMatrix(vehicle)*vec3(-0.5,0,0)):unpack())
			end
			if seat == 0 or seat == 3 then
				PedSetActionNode(gPlayer,string.format(node,"DRIVER"),"")
			else
				PedSetActionNode(gPlayer,string.format(node,"PASSENGER"),"")
			end
		end
	elseif VehicleIsBike(vehicle) then
		PlayerDetachFromVehicle()
	else
		PedWarpOutOfCar(gPlayer)
	end
end

-- utility
function F_PlaySound(sound,bank)
	if dsl.sounds then
		dsl.sounds.Play(sound,bank)
	else
		SoundPlay2D(sound)
	end
end
function F_Rotation(angle)
	while angle > math.pi do
		angle = angle - math.pi * 2
	end
	while angle <= -math.pi do
		angle = angle + math.pi * 2
	end
	return angle
end
