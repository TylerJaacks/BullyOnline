require("utility/texture")

local CHECKPOINT_RANGE = 5
local RESPAWN_TIME_MS = 3000
local DISQUALIFY_TIME_MS = 10000
local MINIMUM_LOADING_MS = 1000
local START_TEXT_MS = 2000
local LAP_TEXT_MS = 2000

local gPeds = {}
local gStarted = GetSyncTimer()
local gDriving = false
local gLoading = false -- waiting for server initialization
local gTransition = false -- waiting for area transition
local gActive = true -- race is on-going (a racer hasn't finished)
local gSpectate = false
local gStage = "intro" -- can also be "gameplay" or "results"
local gRawResults = {}
local gSortedResults = {}
local gWantRespawn = false
local gLastCheckpoint
local gCheckpoints = {} -- will get filled after intro
local gEffects = {}
local gBlip = -1
local gLap = 1
local gText -- printed text (see F_SetText)
local gPayment = 0

local gVoted = false
local gVoteNow = false
local gVoteBefore = false
local gVoteRatio = 0
local gVoteTexture

local gCollision = true

-- cleanup
RegisterLocalEventHandler("sync:DeletePed",function(sped)
	gPeds[sped] = nil
end)

-- controls
RegisterLocalEventHandler("ControllerUpdating",function(c)
	if c == 0 then
		if gTransition or gStage == "intro" then
			if gStage == "intro" then
				gVoteBefore = gVoteNow
				if IsUsingJoystick(0) then
					gVoteNow = IsButtonPressed(9,0)
				else
					gVoteNow = IsKeyPressed("F",0)
				end
			end
			ZeroController(0)
		elseif gStage == "results" then
			SetButtonPressed(4,0,false)
		end
		gWantRespawn = IsButtonPressed(9,0)
		if gSpectate then
			SetButtonPressed(6,0,false)
			SetButtonPressed(9,0,false)
			SetButtonPressed(12,0,false)
		elseif gDriving then
			SetButtonPressed(9,0,false)
		else
			SetButtonPressed(6,0,false)
			SetButtonPressed(12,0,false)
		end
		SetButtonPressed(11,0,false)
		SetButtonPressed(13,0,false)
	end
end)
RegisterLocalEventHandler("ControllersUpdated",function()
	if gTransition or gStage == "intro" then
		ZeroController(0)
	end
end)

-- network
RegisterNetworkEventHandler("races:AddRacers",function(racers)
	for _,racer in ipairs(racers) do
		gPeds[racer] = -1
	end
end)
RegisterNetworkEventHandler("races:SetResult",function(id,name,result)
	if name then
		if result then
			result = math.max(0,result-(MINIMUM_LOADING_MS+15000))
		end
		gRawResults[id] = {name,result} -- result can be nil if DNF
	else
		gRawResults[id] = nil
	end
	gSortedResults = {}
	for _,v in pairs(gRawResults) do
		table.insert(gSortedResults,v)
	end
	table.sort(gSortedResults,function(a,b)
		if a[2] == b[2] then
			return string.lower(a[1]) < string.lower(b[1])
		elseif a[2] and b[2] then
			return a[2] < b[2]
		end
		return a[2]
	end)
end)
RegisterNetworkEventHandler("races:UnfadeScreen",function()
	gLoading = false
end)
RegisterNetworkEventHandler("races:FinishRace",function(pay)
	gPayment = pay / 100
	gActive = false
end)
RegisterNetworkEventHandler("races:UpdateCollision",function(ratio,collision)
	gVoteRatio = ratio
	gCollision = collision
end)

-- skateboard
RegisterLocalEventHandler("weapon_items:AdjustAmmo",function(weapon)
	return weapon == 437
end)
RegisterLocalEventHandler("weapon_items:ResetWeapon",function()
	return PedGetWeapon(gPlayer) == 437
end)

-- cleanup
function MissionCleanup()
	if dsl.radar then
		dsl.radar.DisableRadar(false)
	end
	for _,ped in pairs(gPeds) do
		if PedIsValid(ped) then
			PedSetUsesCollisionScripted(ped,false)
			PedSetEffectedByGravity(ped,true)
			BlipRemoveFromChar(ped)
		end
	end
	for _,fx in ipairs(gEffects) do
		EffectKill(fx)
	end
	if gBlip ~= -1 then
		BlipRemove(gBlip)
	end
	if gTransition then
		AreaDisableCameraControlForTransition(false)
		CameraFade(0,1)
	end
	SoundStopInteractiveStream()
	CameraSetWidescreen(false)
	UnpauseGameClock()
end
function MissionSetup()
	if dsl.freecam and dsl.freecam.IsActive() then
		dsl.freecam.Stop()
	end
	if dsl.radar and dsl.radar.IsActive() then
		dsl.radar.Close()
	end
end
function main()
	local respawning
	local disqualify
	local disqualified = false
	local waitforspawn
	F_Transition()
	CreateThread("T_Music")
	PauseGameClock()
	if gRace.weapon and gRace.weapon ~= -1 then
		PedSetWeaponNow(gPlayer,gRace.weapon,1,false)
	else
		PedSetWeaponNow(gPlayer,-1)
	end
	PlayerSetHealth(PedGetMaxHealth(gPlayer))
	PedSetEffectedByGravity(gPlayer,true)
	F_SetEngine(true)
	F_Introduction()
	F_InitLastCheckpoint()
	F_RefillCheckpoints()
	F_SpawnCheckpoint()
	gStage = "gameplay"
	F_SetText("GO!",START_TEXT_MS)
	while gActive do
		-- TextPrintString(PedGetHealth(gPlayer).." / "..PedGetMaxHealth(gPlayer),0,1)
		gDriving = VehicleIsValid(VehicleFromDriver(gPlayer))
		if not gSpectate and gRace.parkour_height and AreaGetVisible() == 0 then
			local x,y,z = PlayerGetPosXYZ()
			if z < gRace.parkour_height then
				local hp = PlayerGetHealth() - GetFrameTime() * 30
				if hp <= 0 then
					if PedMePlaying(gPlayer,"DEFAULT_KEY",true) then
						PedSetActionNode(gPlayer,"/GLOBAL/HITTREE/STANDING/POSTHIT/STANDING/DEAD/COLLAPSE/COLLAPSE_B","")
					end
					PlayerSetHealth(0)
				else
					PlayerSetHealth(hp)
				end
			end
		end
		if gRace.force_ladders and PedIsPlaying(gPlayer,"/GLOBAL/WPROPS/PROPINTERACT/PROPINTERACTLOCO/LOCODIRECTWITHDEEQUIP",true) then
			PedSetActionNode(gPlayer,"/GLOBAL/WPROPS/PROPINTERACT/PROPINTERACTLOCO/BASE/PROPINTERACTLOCODIRECT/INTERACT","")
		end
		if gSpectate then
			F_UpdateSpectating()
		elseif F_UpdateCheckpoint() then
			SendNetworkEvent("races:FinishRace")
			F_StartSpectating()
			gSpectate = true
		elseif gDriving and gLastCheckpoint and gWantRespawn then
			if not respawning then
				respawning = GetTimer()
			elseif GetTimer() - respawning >= RESPAWN_TIME_MS then
				F_RespawnVehicle(unpack(gLastCheckpoint))
				respawning = nil
			end
		elseif respawning then
			respawning = nil
		end
		if waitforspawn and (gDriving or GetTimer() - waitforspawn >= 5000) then
			waitforspawn = nil
		end
		if not disqualified and not waitforspawn and not gSpectate and not gDriving and (gRace.vehicle and gRace.vehicle ~= -1) then
			if not disqualify then
				disqualify = GetTimer()
			elseif GetTimer() - disqualify >= DISQUALIFY_TIME_MS then
				if gRace.can_disqualify then
					SendNetworkEvent("races:FinishRace",true)
					F_SetText("DISQUALIFIED!",3000)
					disqualified = true
				else
					local lx,ly,lz = unpack(gLastCheckpoint)
					local nx,ny,nz = unpack(gCheckpoints[1])
					waitforspawn = GetTimer()
					SendNetworkEvent("races:AttemptRespawn",lx,ly,lz,math.deg(math.atan2(lx-nx,ny-ly)))
				end
				disqualify = nil
			end
		elseif disqualify then
			disqualify = nil
		end
		if disqualify then
			F_DrawText("Get back in your vehicle! ("..math.ceil((DISQUALIFY_TIME_MS - (GetTimer() - disqualify)) / 1000)..")")
			gText = nil
		elseif gText then
			if F_Time() - gText[2] < gText[3] then
				F_DrawText(gText[1])
			else
				gText = nil
			end
		end
		if PedMePlaying(gPlayer,"DEFAULT_KEY",true) or PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES/SKATEBOARD/LOCOMOTION/RIDE",true) then
			if not gRace.weapon or gSpectate then
				if PedGetWeapon(gPlayer) ~= -1 then
					PedSetWeapon(gPlayer,-1)
				end
			elseif PedGetWeapon(gPlayer) ~= gRace.weapon then
				if gRace.weapon ~= -1 then
					PedSetWeapon(gPlayer,gRace.weapon,1,false)
				else
					PedSetWeapon(gPlayer,-1)
				end
			end
		end
		if respawning then
			F_DrawRespawning((GetTimer() - respawning) / RESPAWN_TIME_MS)
		end
		F_DrawInformation()
		F_UpdateRacers()
		F_UpdateBounds()
		Wait(0)
	end
	if dsl.radar then
		dsl.radar.DisableRadar(true)
	end
	gStage = "results"
	gDriving = false
	return T_DrawResults()
end

-- introduction
function F_Transition()
	local started
	while AreaIsLoading() do
		Wait(0)
	end
	CameraFade(650,0)
	Wait(650)
	while AreaIsLoading() do
		Wait(0)
	end
	started = GetTimer()
	PlayerSetPosXYZArea(gSpawn[1],gSpawn[2],gSpawn[3],gRace.area)
	SendNetworkEvent("races:FadedScreen")
	gTransition = true
	gLoading = true
	while gLoading or AreaIsLoading() or IsStreamingBusy() or GetTimer() - started < MINIMUM_LOADING_MS do
		AreaDisableCameraControlForTransition(true)
		Wait(0)
	end
	gTransition = false
	AreaDisableCameraControlForTransition(false)
	PedFaceHeading(gPlayer,gSpawn[4],0)
	CameraFade(650,1)
end
function F_Introduction()
	if IsUsingJoystick(0) then
		gVoteTexture = GetInputTexture(9,0)
	else
		gVoteTexture = GetHudTexture("Button_F")
	end
	CameraSetWidescreen(true)
	CameraSetXYZ(unpack(gRace.cameras.time_15))
	while F_Time() < MINIMUM_LOADING_MS + 5000 do
		F_DrawIntro(true)
		F_UpdateVote()
		Wait(0)
	end
	CameraSetXYZ(unpack(gRace.cameras.time_10))
	while F_Time() < MINIMUM_LOADING_MS + 10000 do
		F_DrawIntro(true)
		F_UpdateVote()
		Wait(0)
	end
	CameraSetWidescreen(false)
	CameraReturnToPlayer()
	while F_Time() < MINIMUM_LOADING_MS + 12000 do
		F_DrawIntro(true)
		F_UpdateVote()
		Wait(0)
	end
	for i = 1,3 do
		F_PlaySound("CountBeep","BikeBeep.bnk")
		while F_Time() < MINIMUM_LOADING_MS + 12000 + 1000 * i do
			F_DrawIntro(false)
			Wait(0)
		end
	end
	F_PlaySound("GoBeep","BikeBeep.bnk")
	gVoteTexture = nil
end
function F_SetText(text,ms)
	gText = {text,F_Time(),ms}
end
function F_UpdateVote()
	if not gVoted and not gVoteBefore and gVoteNow then
		SendNetworkEvent("races:VoteCollision")
		gVoted = true
	end
end
function F_DrawIntro(vote)
	SetTextFont("Georgia")
	SetTextBold()
	SetTextColor(200,200,200,255)
	SetTextOutline(0,0,0,255)
	SetTextAlign("C","T")
	SetTextScale(1.7)
	SetTextPosition(0.5,0.2)
	DrawText("STARTING IN "..math.ceil(((MINIMUM_LOADING_MS+15000)-F_Time())/1000))
	if vote and gVoteTexture then
		local x,y,w,h = 0.5,0.8
		local size = 0.03
		local tar = GetTextureDisplayAspectRatio(gVoteTexture)
		local padding = 0.015 / GetDisplayAspectRatio()
		SetTextFont("Georgia")
		SetTextBold()
		if gCollision then
			SetTextColor(200,200,200,255)
		else
			SetTextColor(50,210,50,255)
		end
		SetTextOutline(0,0,0,255)
		SetTextAlign("C","B")
		SetTextHeight(size)
		SetTextPosition(x,y)
		w,h = DrawText("Vote to Disable Collision ["..math.floor(gVoteRatio*100).."%]")
		if not gVoted then
			DrawTexture(gVoteTexture,x-(w*0.5+size*tar+padding),y-size,size*tar,size,255,255,255,255)
		end
	end
end
function F_DrawText(text)
	SetTextFont("Georgia")
	SetTextBold()
	SetTextColor(200,200,200,255)
	SetTextOutline(0,0,0,255)
	SetTextAlign("C","T")
	SetTextScale(1.7)
	SetTextPosition(0.5,0.2)
	DrawText(text)
end

-- gameplay
function F_SetEngine(on)
	local vehicle = VehicleFromDriver(gPlayer)
	if VehicleIsValid(vehicle) then
		VehicleEnableEngine(vehicle,on)
	end
end
function F_InitLastCheckpoint()
	local vehicle = VehicleFromDriver(gPlayer)
	if VehicleIsValid(vehicle) then
		gLastCheckpoint = {VehicleGetPosXYZ(vehicle)}
	end
end
function F_RefillCheckpoints()
	if gRace.shuffle then
		local shuffle = {}
		local count = table.getn(gRace.checkpoints) - 1
		for i = 1,count do
			shuffle[i] = gRace.checkpoints[i]
		end
		count = math.min(count,gRace.shuffle)
		while count > 0 do
			table.insert(gCheckpoints,table.remove(shuffle,math.random(count)))
			count = count - 1
		end
		table.insert(gCheckpoints,gRace.checkpoints[table.getn(gRace.checkpoints)])
	else
		for _,point in ipairs(gRace.checkpoints) do
			table.insert(gCheckpoints,point)
		end
	end
end
function F_UpdateCheckpoint()
	local checkpoint = gCheckpoints[1]
	local x1,y1,z1 = PlayerGetPosXYZ()
	local x2,y2,z2 = unpack(checkpoint)
	local dx,dy,dz = x2-x1,y2-y1,z2-z1
	if not gWantRespawn and dx*dx+dy*dy+dz*dz < CHECKPOINT_RANGE*CHECKPOINT_RANGE and (VehicleIsValid(VehicleFromDriver(gPlayer)) or (not gRace.vehicle or gRace.vehicle == -1)) then
		local vehicle = VehicleFromDriver(gPlayer)
		for i,fx in ipairs(gEffects) do
			gEffects[i] = nil
			EffectKill(fx)
		end
		if gBlip ~= -1 then
			BlipRemove(gBlip)
		end
		if not checkpoint.sound then
			SoundPlay2D("Generic_Pickup")
		elseif dsl.sounds and checkpoint.bank and string.lower(checkpoint.bank) ~= "hud.bnk" then
			dsl.sounds.Play(checkpoint.sound,checkpoint.bank)
		else
			SoundPlay2D(checkpoint.sound)
		end
		SendNetworkEvent("races:HitCheckpoint",x2,y2,z2)
		table.remove(gCheckpoints,1)
		if not gCheckpoints[1] then
			if gLap >= gRace.laps then
				return true
			end
			F_RefillCheckpoints()
			gLap = gLap + 1
			if gRace.laps ~= gLap then
				local x = ({"2nd","3rd","4th","5th"})[gLap-1]
				if x then
					F_SetText(x.." LAP!",LAP_TEXT_MS)
				else
					F_SetText("LAP "..gLap,LAP_TEXT_MS)
				end
			else
				F_SetText("FINAL LAP!",LAP_TEXT_MS)
			end
		end
		if VehicleIsValid(vehicle) then
			x1,y1,z1 = VehicleGetPosXYZ(vehicle)
		end
		if gRace.exact_respawns then
			gLastCheckpoint = {x2,y2,z2}
		else
			gLastCheckpoint = {x1,y1,z1}
		end
		F_SpawnCheckpoint()
	end
	if gEffects[1] then
		F_UpdateWaypoint(gEffects[1])
	end
	return false
end
function F_SpawnCheckpoint()
	local x,y,z = unpack(gCheckpoints[1])
	if not gCheckpoints[2] and gLap == gRace.laps then
		gEffects[1] = EffectCreate("RaceWaypointFinal",x,y,z)
		gEffects[2] = EffectCreate("RaceBeamFinal",x,y,z)
	else
		gEffects[1] = EffectCreate("RaceWaypoint",x,y,z)
		gEffects[2] = EffectCreate("RaceBeam",x,y,z)
	end
	gBlip = BlipAddXYZ(x,y,z,0,1)
end
function F_UpdateWaypoint(fx)
	local x,y,z = unpack(gCheckpoints[1])
	if gCheckpoints[2] then
		F_RotateWaypoint(fx,x,y,z,unpack(gCheckpoints[2]))
	elseif gLap ~= gRace.laps then
		F_RotateWaypoint(fx,x,y,z,unpack(gRace.checkpoints[2]))
	else
		F_RotateWaypoint(fx,x,y,z,PlayerGetPosXYZ())
	end
end
function F_RotateWaypoint(fx,x1,y1,z1,x2,y2,z2)
	local h = math.atan2(x1-x2,y2-y1)
	EffectSetPosition(fx,x1,y1,z1+0.05)
	EffectSetDirection(fx,-math.sin(h),math.cos(h),0.01)
	EffectSetSphereDirection(fx,math.pi*0.5,0,0)
end
function F_RespawnVehicle(lx,ly,lz)
	local vehicle = VehicleFromDriver(gPlayer)
	if VehicleIsValid(vehicle) then
		local nx,ny,nz = unpack(gCheckpoints[1])
		VehicleSetPosXYZ(vehicle,lx,ly,lz)
		VehicleFaceHeading(vehicle,math.deg(math.atan2(lx-nx,ny-ly)))
		CameraMgrUpdate()
		CameraReturnToPlayer()
	end
end
function F_DrawRespawning(progress)
	local width = 0.5 / GetDisplayAspectRatio()
	local height = 0.03
	DrawRectangle(0.5-width*0.5+width*progress,0.95-height*0.5,width*(1-progress),height,0,0,0,150)
	DrawRectangle(0.5-width*0.5,0.95-height*0.5,width*progress,height,255,30,60,150)
end
function F_DrawInformation()
	local secs = math.floor(math.max(0,F_Time()-(MINIMUM_LOADING_MS+15000))/1000)
	SetTextFont("Georgia")
	SetTextBold()
	SetTextColor(200,200,200,255)
	SetTextShadow()
	SetTextAlign("C","T")
	SetTextScale(1.2)
	SetTextPosition(0.5,0.02)
	if gSpectate then
		DrawText("Time: %.2d:%.2d | Waiting for others to finish...",math.floor(secs/60),math.mod(secs,60))
	elseif gRace.laps == 1 then
		DrawText("Time: %.2d:%.2d",math.floor(secs/60),math.mod(secs,60))
	else
		DrawText("Time: %.2d:%.2d | Lap: %d / %d",math.floor(secs/60),math.mod(secs,60),gLap,gRace.laps)
	end
end
function F_UpdateRacers()
	for sped,blipped in pairs(gPeds) do
		local ped = PedFromSyncPed(sped)
		if PedIsValid(ped) and not PedIsDead(ped) and ped ~= gPlayer then
			if ped ~= blipped then
				AddBlipForChar(ped,0,1,1)
				gPeds[sped] = ped
			end
		elseif blipped ~= -1 then
			gPeds[sped] = -1
		end
	end
	if not gCollision then
		for sped in pairs(gPeds) do
			local ped = PedFromSyncPed(sped)
			if PedIsValid(ped) and not IsSyncEntityOwned(sped) then
				local collision = gStage ~= "gameplay"
				local vehicle = VehicleFromDriver(ped)
				if VehicleIsValid(vehicle) then
					local scar = VehicleGetSyncVehicle(vehicle)
					if scar and not IsSyncEntityOwned(scar) then
						VehicleSetEntityFlag(vehicle,1,collision) -- TODO: try flag 0
					end
				end
				PedSetUsesCollisionScripted(ped,not collision)
				PedSetEffectedByGravity(ped,collision)
			end
		end
	end
end
function F_UpdateBounds()
	local x,y,z
	local vehicle = VehicleFromDriver(gPlayer)
	if VehicleIsValid(vehicle) then
		x,y,z = VehicleGetPosXYZ(vehicle)
	else
		x,y,z = PlayerGetPosXYZ()
	end
	if x < -781 then
		if VehicleIsValid(vehicle) then
			local m = VehicleGetMatrix(vehicle)
			VehicleSetPosSimple(vehicle,-781,y,z)
			VehicleSetMatrix(vehicle,m)
		else
			PlayerSetPosSimple(-781,y,z)
		end
	end
end

-- spectator
function F_StartSpectating()
	local x,y,z,d = unpack(gRace.spectator_spawn)
	local h = math.random() * math.pi * 2
	while AreaIsLoading() do
		Wait(0)
	end
	CameraFade(650,0)
	Wait(650)
	while AreaIsLoading() do
		Wait(0)
	end
	F_WarpOut()
	SendNetworkEvent("races:ExitVehicle")
	PlayerSetPosXYZArea(x-math.sin(h)*d,y+math.cos(h)*d,z,gRace.area)
	gTransition = true
	while AreaIsLoading() or IsStreamingBusy() do
		AreaDisableCameraControlForTransition(true)
		Wait(0)
	end
	gTransition = false
	AreaDisableCameraControlForTransition(false)
	CameraFade(650,1)
end
function F_UpdateSpectating()
	local update,px,py,pz = false,PlayerGetPosXYZ()
	local x1,y1,x2,y2 = unpack(gRace.spectator_bounds)
	if px < x1 then
		update,px,py,pz = true,x1,py,pz
	elseif px > x2 then
		update,px,py,pz = true,x2,py,pz
	end
	if py < y1 then
		update,px,py,pz = true,px,y1,pz
	elseif py > y2 then
		update,px,py,pz = true,px,y2,pz
	end
	if update then
		if AreaGetVisible() == gRace.area then
			PlayerSetPosSimple(px,py,pz)
		elseif not AreaIsLoading() then
			PlayerSetPosXYZArea(px,py,pz,gRace.area)
		end
	end
end
function F_WarpOut()
	local vehicle = VehicleFromDriver(gPlayer)
	if VehicleIsValid(vehicle) then
		if VehicleIsBike(vehicle) then
			PlayerDetachFromVehicle()
		else
			PedWarpOutOfCar(gPlayer)
		end
	end
end

-- results
function T_DrawResults()
	local text = CopyTexture(CreateTexture("results.png"),"D3DFMT_DXT5")
	local winners = {}
	local colors = {{255,200,50},{200,200,230},{230,120,80},{180,180,180}}
	local sizes = {0.05,0.0425,0.035,0.03}
	local padding = 0.01
	local place,score = 0,-1
	for i,v in ipairs(gSortedResults) do
		if v[2] ~= score then
			place,score = i,v[2]
		end
		winners[i] = {place,v[1],F_FormatResult(v[2])}
	end
	while true do
		local ar = GetDisplayAspectRatio()
		local tar = GetTextureAspectRatio(text) / ar
		local size = 0.1
		local width = size * tar
		local y = 0.2
		DrawTexture(text,0.5-(size*0.5)*tar,y-size*0.5,size*tar,size,255,200,50,255)
		y = y + size * 0.5 + 0.02
		for i,v in ipairs(winners) do
			local r,g,b = unpack(colors[v[1]] or colors[4])
			size = sizes[v[1]] or sizes[4]
			DrawRectangle(0.5-width*0.5,y,width,size,0,0,0,100)
			SetTextFont("Georgia")
			SetTextBold()
			SetTextColor(r,g,b,255)
			SetTextAlign("L","C")
			SetTextHeight(size-padding)
			SetTextPosition(0.5-width*0.5+(padding*0.5)/ar,y+size*0.5)
			SetTextClipping((width-padding/ar)*0.7)
			if v[1] <= 3 then
				DrawText(v[1]..") "..v[2])
			else
				DrawText(v[2])
			end
			SetTextFont("Georgia")
			SetTextBold()
			SetTextColor(230,230,230,255)
			SetTextAlign("R","C")
			SetTextHeight((size-padding)*0.9)
			SetTextPosition(0.5+width*0.5-(padding*0.5)/ar,y+size*0.5)
			SetTextClipping((width-padding/ar)*0.3)
			DrawText(v[3])
			if v[2] == GetPlayerName() then
				SetTextFont("Georgia")
				SetTextBold()
				if gPayment > 0 then
					SetTextColor(12,224,12,255)
				else
					SetTextColor(100,224,100,255)
				end
				SetTextAlign("L","C")
				SetTextHeight((size-padding)*0.9)
				SetTextPosition(0.5+width*0.5+(padding*0.5)/ar,y+size*0.5)
				SetTextClipping((width-padding/ar)*0.3)
				SetTextOutline()
				DrawText("+$%.2f",gPayment)
			end
			y = y + size + 0.005
		end
		Wait(0)
	end
end
function F_FormatResult(ms)
	if ms then
		local secs = math.floor(ms/1000)
		return string.format("%d:%.2d.%.3d",math.floor(secs/60),math.mod(secs,60),math.mod(ms,1000))
	end
	return "D.N.F."
end

-- music thread
function T_Music()
	local started,playing
	while true do
		if gStage ~= playing or (gRace.music_replay > 0 and GetTimer() - started >= math.floor(gRace.music_replay * 1000)) then
			SoundPlayInteractiveStreamLocked(gRace.music[gStage]..".rsm",0.5,250,250)
			started = GetTimer()
			playing = gStage
		end
		Wait(0)
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
function F_Time()
	return GetSyncTimer() - gStarted
end
