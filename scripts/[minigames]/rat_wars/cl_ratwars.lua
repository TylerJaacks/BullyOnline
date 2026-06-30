LoadScript("crosshairs.lua")
LoadScript("weapons.lua")

-- settings (visual)
RAT_REAL_SCALE = 2.5
HIDE_HUD_COMPS = {0,4,11}
INFO_HUD_WIDTH = 0.35
DEATH_CAMERA_TIME = 0.35 -- seconds to see who killed you
PICKUP_DRAW_RANGE = 2
PICKUP_DRAW_ANGLE = math.rad(45)
PICKUP_DRAW_SCALE = 1
PICKUP_DRAW_KEY = true -- otherwise icon is drawn
HEALTH_WARNING = 0.25 -- health ratio to show red health
CROSSHAIR_SIZE = 128
MAX_EFFECTS = 10

-- settings (adrenaline)
ADRENALINE_FX_ALPHA = 0.7
ADRENALINE_FX_RATE = 1.2
ADRENALINE_FX_FADE = 0.3
ADRENALINE_FX_FOV = 0.1

-- settings (markers)
HIT_MARKER_SIZE = 0.05
HIT_MARKER_VARY = 0.2 -- kill marker scale random variation
HIT_MARKER_KILL = 1.5 -- kill marker scale increase when it's a kill
HIT_MARKER_RANGE = 80 -- distance where it is smallest
HIT_MARKER_SCALING = 0.45 -- how much distance should affect size [0, 1]
HIT_MARKER_ALPHA = 200
HIT_MARKER_HOLD_MS = 40
HIT_MARKER_FADE_MS = 60

-- settings (kills)
KILL_TRANSITION = 150
KILL_DURATION = 5000
KILL_HEIGHT = 0.024
KILL_STREAK_RES = 160
KILL_STREAK_SIZE = 0.2
KILL_STREAK_MAX = 30
KILL_FEED_TRANSITION = 200
KILL_FEED_DURATION = 5000

-- settings (gameplay)
RECOIL_SCOPE_AMOUNT = 0.8 -- 1 to disable scope recoil, 0 for full
RECOIL_JUMP_START = 0.4 -- 0.5 to skip all build up
FIRE_MODE_DELAY = 270 -- delay after switching fire modes
RESPAWN_DELAY = 3500
PICKUP_RANGE = 2
SOUND_RANGE = 12

-- settings (hitrats)
RAT_FAKE_SCALE = 0.02
HITRAT_ANGLE = math.rad(15) -- if within this angle *or* within distance, the fake rat can be used
HITRAT_DISTANCE = 5
KEEP_HITRATS = 8000 -- keep fake rats outside the angle and distance this long, allowing them to be re-used
MAX_HITRATS = 5

-- settings (miscellaneous)
SWITCH_INPUT_DELAY = 200 -- time to hold different input to switch
ICON_RES = 500 -- icons.png is expected to be divisible by this to index icons

-- settings (streaks)
GIANT_RAT_VISUAL = 5
GIANT_RAT_HITBOX = 0.24

-- textures
gBullet = CreateTexture("images/bullet.png")
gCircle = CopyTexture(CreateTexture("images/circle.png"),"D3DFMT_DXT5")
gIcons = CopyTexture(CreateTexture("images/icons.png"),"D3DFMT_DXT5")
gMarker = CopyTexture(CreateTexture("images/hitmarker.png"),"D3DFMT_DXT5")
gKillNumbers = CopyTexture(CreateTexture("images/kills.png"),"D3DFMT_DXT5")
gAdrenalineScreen = CopyTexture(CreateTexture("images/adrenaline.png"),"D3DFMT_DXT5")

-- duration
gStarted = GetSyncTimer() -- used alongside gDuration (set by launcher) to calculate match time
gWarning = 31000 -- next warning beep

-- phases
gIntroduction = true -- if the introduction sequence is active
gResults = false -- if the results screen is active

-- gameplay
gGunshots = {} -- {[sped] = {...}} for each sound that needs playing
gPlayers = {} -- {[sped] = fake_ped}, for each player ped currently playing
gFakes = {} -- {[fake_ped] = {...}} for all fake hitbox rats
gKilled = 0 -- 0 not dead, 1 apply death asap, 2 wait for alive
gScores = {} -- {{name, score, deaths, r, g, b}, ...}

-- controls
gLockAim = false
gLockSprint = false
gButtonsLast = {}
gButtonsNow = {}
gInputSwitch = -1 -- if not -1, the time another controller started movement input
gInputBackup = -1 -- if not -1, the player's original keyboard controller index

-- weapons
gEquipped = false -- also means there's a valid gCurrentWeapon table
gSwitching = false -- also means there's a valid gPreviousWeapon table
gEquip = 0 -- 0 when the gun is off-screen, 1 when fully raised / equipped
gAim = 0 -- 0 when fully hip fire, 1 when fully aimed

-- reloading
gReloading = false -- bring weapon down in order to reload
gReloadTimer = -1 -- time that a reload "started" (off screen)
gReloadMagazine = false -- intend to reload mag after setting timer

-- timing
gRecoilTimer = -1
gScopeTimer = -1
gSemiTimer = -1
gFireTimer = -1

-- pickups
gPickups = {}
gPickupAllow = {} -- [id] = true, for pickup removal
gPickupSounds = {}
gPickupBinding = 0 -- 0 = not set, 1 = controller, 2 = keyboard
gPickupSpawns = 0
gAdrenaline = false
gAdrenalineFOV = 0

-- hits
gVisualEffects = {n = 0}
gShootPosition = {0,0,0} -- updated when a gun is shot to calculate effect direction
gHitMarker = -1 -- if not -1, time a hit marker started being shown
gHitPosition = {0,0,0} -- where the hit marker is
gHitKilled = false -- if the hit was also a kill
gHitSound = false -- if it needs to make sound
gHitSize = 0 -- hit marker scale

-- kills
gKillStreak = 0 -- if non-zero, gKillStreakTimer is also set
gKillSound = false
gKillFeed = {}

-- streaks
gGiantRat = false
gGiantRats = {} -- [sped] = true

-- miscellaneous
gRatClass = ""
gWeaponUpdates = 0 -- update requests we're waiting for
gRequestSwitch = false -- waiting for server switch response
gSpeedMult = 1 -- for reloading, aiming, and equipping
gRecoilMult = 1 -- changed by powerups
gRecoilAim = false -- if the last recoil was aimed
gRecoilOffset = 0 -- how much the last recoil should offset
gRecoilAngle = 0 -- angle of the offset
gShocker = false
gPayment = 0

-- network events
RegisterNetworkEventHandler("rat_wars:SetClass",function(class)
	gRatClass = class
end)
RegisterNetworkEventHandler("rat_wars:SkipIntro",function()
	gIntroduction = false
end)
RegisterNetworkEventHandler("rat_wars:AddPlayer",function(sped)
	gPlayers[sped] = -1
end)
RegisterNetworkEventHandler("rat_wars:SpawnPickup",function(pickup,icon)
	local data = {picked = false,draw = false} -- .id can be set later
	if icon then
		data.icon = {F_GetIconUV(icon-1)}
		data.auto = false
	else
		data.auto = true
	end
	gPickups[pickup] = data
end)
RegisterNetworkEventHandler("rat_wars:RejectPickup",function(pickup)
	local data = gPickups[pickup]
	if data then
		data.picked = false
	end
end)
RegisterNetworkEventHandler("rat_wars:UpdateScores",function(scores)
	local sorted = {}
	if dsl.role_colors then
		for name,sc in pairs(scores) do
			table.insert(sorted,{name,sc[1],sc[2],dsl.role_colors.GetColorFromIndex(sc[3])})
		end
	else
		for name,sc in pairs(scores) do
			table.insert(sorted,{name,sc[1],sc[2],230,230,230})
		end
	end
	table.sort(sorted,function(a,b)
		if a[2] == b[2] then
			return string.lower(a[1]) < string.lower(b[1])
		end
		return a[2] > b[2]
	end)
	gScores = sorted
end)
RegisterNetworkEventHandler("rat_wars:DisplayResults",function(pay)
	gPayment = pay / 100
	gResults = true
end)
RegisterNetworkEventHandler("rat_wars:SetWeapon",function(id,state)
	F_EquipWeapon(id,state)
end)
RegisterNetworkEventHandler("rat_wars:UpdateWeapon",function(state)
	gWeaponUpdates = gWeaponUpdates - 1
	if gWeaponUpdates <= 0 then
		F_UpdateWeapon(state)
		gWeaponUpdates = 0
	end
end)
RegisterNetworkEventHandler("rat_wars:AllowSwitch",function()
	gRequestSwitch = false
end)
RegisterNetworkEventHandler("rat_wars:KilledBy",function(sped,name)
	gKilled = 1
	gKiller = {name,sped}
end)
RegisterNetworkEventHandler("rat_wars:KillStreak",function(streak)
	if streak <= KILL_STREAK_MAX then
		local i = streak - 1
		local w,h = GetTextureResolution(gKillNumbers)
		local columns = math.floor(w/KILL_STREAK_RES)
		local rows = math.floor(h/KILL_STREAK_RES)
		local x,y = math.mod(i,columns),math.floor(i/columns)
		SetTextureBounds(gKillNumbers,x/columns,y/rows,(x+1)/columns,(y+1)/rows)
		gKillStreakTimer = GetTimer()
		gKillStreak = streak
		gKillSound = true
	end
end)
RegisterNetworkEventHandler("rat_wars:KillFeed",function(killer,c1,icon,adrenaline,victim,c2)
	local v = {when = GetTimer(),killer = killer,rainbow = adrenaline,victim = victim}
	if dsl.role_colors then
		v.r1,v.g1,v.b1 = dsl.role_colors.GetColorFromIndex(c1)
		v.r2,v.g2,v.b2 = dsl.role_colors.GetColorFromIndex(c2)
	else
		v.r1,v.g1,v.b1 = 230,230,230
		v.r2,v.g2,v.b2 = 230,230,230
	end
	if icon > 0 then
		v.icon = {F_GetIconUV(icon-1)}
	end
	table.insert(gKillFeed,1,v)
end)
RegisterNetworkEventHandler("rat_wars:GiantRat",function(sped,active)
	if sped == GetSyncPlayerPed() then
		gGiantRat = active or false
	else
		gGiantRats[sped] = active
	end
end)
RegisterNetworkEventHandler("rat_wars:ShootProjectile",function(sped,id,px,py,pz,vx,vy,vz)
	local stats = gWeapons[id]
	local resound = stats.sound_distance
	local rx,ry,rz = PlayerGetPosXYZ()
	local dx,dy,dz = px-rx,py-ry,pz-rz
	if stats.flash_effects[1] then
		local ped = PedFromSyncPed(sped)
		if PedIsValid(ped) then
			local dist = math.sqrt(vx*vx+vy*vy+vz*vz)
			if dist > 0 then
				local px,py,pz = PedGetPosXYZ(ped)
				local fx,fy,fz = unpack(stats.flash_offset)
				local fp,fh = math.rad(stats.flash_pitch)+math.asin(vz/dist),math.rad(stats.flash_heading)+math.atan2(-vx,vy)
				fz = fz * RAT_REAL_SCALE
				for _,name in ipairs(stats.flash_effects) do
					local x = px + fx * math.cos(fh) - math.sin(fh) * (fy * math.cos(fp) + fz * math.sin(fp))
					local y = py + fx * math.sin(fh) + math.cos(fh) * (fy * math.cos(fp) + fz * math.sin(fp))
					local z = pz + fy * math.sin(fp) + fz * math.cos(fp)
					local fx = EffectCreate(name,x,y,z)
					EffectSetDirection(fx,-math.cos(fp)*math.sin(fh),math.cos(fp)*math.cos(fh),math.sin(fp))
				end
			end
		end
	end
	CreateProjectile(stats.projectile_id,px,py,pz,vx,vy,vz,0) -- remote projectiles are just visual
	if math.sqrt(dx*dx+dy*dy+dz*dz) * resound < SOUND_RANGE then
		gGunshots[sped] = {
			replay = stats.sound_duplicate,
			sounds = stats.sound_names,
			banks = stats.sound_banks,
			x = rx + dx * resound,
			y = ry + dy * resound,
			z = rz + dz * resound,
		}
	end
end)
RegisterNetworkEventHandler("rat_wars:HitMarker",function(sped,kill)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local x2,y2,z2 = F_GetRatPosition(ped)
		local sx,sy = GetScreenCoords(x2,y2,z2)
		if sx and dsl.first_person then
			local x1,y1,z1 = dsl.first_person.GetPosition()
			local dx,dy,dz = x2-x1,y2-y1,z2-z1
			local dist = math.sqrt(dx*dx+dy*dy+dz*dz)
			if dist < HIT_MARKER_RANGE then
				gHitSize = HIT_MARKER_SIZE * ((1 - HIT_MARKER_SCALING) + HIT_MARKER_SCALING * (1 - dist / HIT_MARKER_RANGE))
			else
				gHitSize = HIT_MARKER_SIZE * (1 - HIT_MARKER_SCALING)
			end
			if kill then
				gHitSize = gHitSize * HIT_MARKER_KILL
			end
			gHitSize = gHitSize * (1 + HIT_MARKER_VARY * (1 - 2 * math.random()))
			gHitMarker = GetTimer()
			gHitPosition = {sx,sy}
			gHitKilled = kill
			gHitSound = true
		end
	end
end)
RegisterNetworkEventHandler("rat_wars:SetAdrenaline",function(active)
	gAdrenaline = active or false
	F_UpdateStatMult()
end)
RegisterNetworkEventHandler("rat_wars:PickupSound",function(ptype,x1,y1,z1)
	local sound,bank = "Gift_Pickup","Hud.bnk"
	if ptype == "health" then
		sound,bank = "ArtSuccess","ArtClass.bnk"
	elseif ptype == "adrenaline" then
		sound,bank = "Activate","ArtClass.bnk"
	end
	if x1 then
		for _,v in ipairs(gPickupSounds) do
			local s,b,x2,y2,z2 = unpack(v)
			local dx,dy,dz = x2-x1,y2-y1,z2-z1
			if dx*dx+dy*dy+dz*dz < 1 then
				return -- don't add another sound here
			end
		end
		table.insert(gPickupSounds,{sound,bank,x1,y1,z1})
	else
		gPickupSounds[0] = {sound,bank} -- play own sound
	end
end)
RegisterNetworkEventHandler("rat_wars:ReloadSound",function(sped,mag)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local px,py,pz = F_GetRatPosition(ped)
		local rx,ry,rz = PlayerGetPosXYZ()
		local dx,dy,dz = px-rx,py-ry,pz-rz
		if dx*dx+dy*dy+dz*dz < SOUND_RANGE*SOUND_RANGE then
			local sound,bank = "GunPump","ShotGall.bnk"
			if mag then
				sound,bank = "SpudGun_Reload","Spudgun.bnk"
			end
			gGunshots[sped] = {
				replay = 1,
				sounds = {sound},
				banks = {bank},
				x = px,
				y = py,
				z = pz,
			}
		end
	end
end)
RegisterNetworkEventHandler("rat_wars:DrySound",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local px,py,pz = F_GetRatPosition(ped)
		local rx,ry,rz = PlayerGetPosXYZ()
		local dx,dy,dz = px-rx,py-ry,pz-rz
		if dx*dx+dy*dy+dz*dz < SOUND_RANGE*SOUND_RANGE then
			gGunshots[sped] = {
				replay = 1,
				sounds = {"SpudGunDryfire"},
				banks = {"Spudgun.bnk"},
				x = px,
				y = py,
				z = pz,
			}
		end
	end
end)

-- local events
RegisterLocalEventHandler("ControllerUpdating",function(c)
	if not IsPauseMenuActive() and not IsMapMenuActive() and c == 0 then
		local joystick = IsUsingJoystick(0)
		for b,v in pairs(gButtonsNow) do
			gButtonsLast[b] = v
		end
		if gIntroduction or gResults then
			ZeroController(0)
		end
		if not joystick then
			gButtonsNow[4] = IsKeyPressed("TAB",0) -- 4: SCORES
			gButtonsNow[6] = IsKeyPressed("R",0) -- 6: RELOAD
			gButtonsNow[7] = IsKeyPressed("LSHIFT",0) -- 7: SPRINT
			gButtonsNow[8] = IsKeyPressed("1",0) or IsKeyPressed("2",0) or IsKeyPressed("Q",0) -- 8: SWITCH WEAPON
			gButtonsNow[9] = IsKeyPressed("F",0) -- 9: PICKUP STUFF
			gButtonsNow[10] = IsMousePressed(1) -- 10: AIM WEAPON
			gButtonsNow[11] = false
			gButtonsNow[12] = IsMousePressed(0) -- 12: SHOOT WEAPON
			gButtonsNow[13] = false
			gButtonsNow[14] = false
			gButtonsNow[15] = IsKeyPressed("C",0) -- 15: FIRE MODE
		end
		for b = 4,15 do -- leave d-pad alone
			if b ~= 5 then -- leave pause button alone
				if joystick then
					gButtonsNow[b] = IsButtonPressed(b,0)
				end
				SetButtonPressed(b,0,false)
			end
		end
		if gButtonsNow[10] and not gButtonsLast[10] and (gLockAim or not gSettings.aiming) then
			gLockAim = not gLockAim
		end
		if joystick then
			if gButtonsNow[7] or gButtonsNow[10] then
				gLockSprint = false
			elseif gButtonsNow[14] and not gButtonsLast[14] then -- can tap L3 to sprint
				gLockSprint = not gLockSprint
			end
		elseif gLockSprint then
			gLockSprint = false
		end
		if (gLockSprint or gButtonsNow[7]) and not gReloading and gRecoilTimer == -1 and gAim == 0 then
			SetButtonPressed(7,0,true)
		end
	end
end)
RegisterLocalEventHandler("ControllersUpdated",function()
	if gIntroduction or gResults then
		ZeroController(0)
	end
	if gLockSprint and GetStickValue(16,0) == 0 and GetStickValue(17,0) == 0 then
		gLockSprint = false
	end
end)
RegisterLocalEventHandler("PedUpdateActionController",function(ped,index)
	if gFakes[ped] and index == 0 then
		PedSetThrottle(ped,0)
	end
end)
RegisterLocalEventHandler("PedUpdateMatrix",function(ped)
	if PedIsModel(ped,136) then
		local scale = 1
		local sped = PedGetSyncPed(ped)
		if gPlayers[sped] then
			if gGiantRats[sped] then
				scale = GIANT_RAT_VISUAL
			else
				scale = RAT_REAL_SCALE
			end
		elseif gFakes[ped] or ped == gPlayer then
			scale = RAT_FAKE_SCALE
			if next(gGiantRats) then
				for sped,fake in pairs(gPlayers) do
					if fake == ped then
						if gGiantRats[sped] then
							scale = GIANT_RAT_HITBOX
						end
						break
					end
				end
			end
		end
		PedSetMatrix(ped,PedGetMatrix(ped)*(IdentityMatrix(3)*scale))
	end
end)
RegisterLocalEventHandler("PedResetAlpha",function(ped)
	if gFakes[ped] then
		return true
	end
end)
RegisterLocalEventHandler("sync:DeleteEntity",function(ent)
	local pickup = gPickups[ent]
	if pickup then
		if pickup.id and not PickupIsPickedUp(pickup.id) then
			PickupDelete(pickup.id)
		end
		gPickups[ent] = nil
	end
end)
RegisterLocalEventHandler("sync:DeletePed",function(sped)
	local fake = gPlayers[sped]
	if fake then
		if fake ~= -1 then
			if PedIsValid(fake) then
				PedDelete(fake)
			end
			gFakes[fake] = nil
		end
		if gKiller and gKiller[2] == sped then
			gKiller[2] = nil
		end
		gPlayers[sped] = nil
	end
end)
RegisterLocalEventHandler("sync:SuppressPed",function(ped)
	return gFakes[ped]
end)
RegisterLocalEventHandler("first_person:Deactivate",function()
	return true
end)
RegisterLocalEventHandler("spawner:Respawning",function()
	dsl.spawner.SetSpawnDelay(RESPAWN_DELAY)
end)

-- setup / cleanup
function MissionSetup()
	if dsl.freecam and dsl.freecam.IsActive() then
		dsl.freecam.Stop()
	end
	if dsl.nametags then
		dsl.nametags.SetHidden(true)
	end
	if dsl.radar then
		dsl.radar.DisableRadar(true)
	end
	if dsl.chat then
		dsl.chat.Raise(true)
	end
end
function MissionCleanup()
	CameraReturnToPlayer()
	if dsl.first_person then
		dsl.first_person.Stop()
	end
	if dsl.nametags then
		dsl.nametags.SetHidden(false)
	end
	if dsl.radar then
		dsl.radar.DisableRadar(false)
	end
	if dsl.chat then
		dsl.chat.Raise(false)
	end
	if gInputBackup ~= -1 then
		SetKeyboardController(gInputBackup)
	end
	for _,c in ipairs(HIDE_HUD_COMPS) do
		ToggleHUDComponentVisibility(c,true)
	end
	PedSetInvulnerable(gPlayer,false)
	PlayerWeaponHudLock(false)
	UnpauseGameClock()
	for sped in pairs(gPlayers) do
		local ped = PedFromSyncPed(sped)
		if PedIsValid(ped) then
			PedSetUsesCollisionScripted(ped,false)
			PedSetEffectedByGravity(ped,true)
		end
	end
	for fake in pairs(gFakes) do
		if PedIsValid(fake) then
			PedDelete(fake)
		end
	end
	for _,pickup in pairs(gPickups) do
		if pickup.id and not PickupIsPickedUp(pickup.id) then
			PickupDelete(pickup.id)
		end
	end
	for _,fx in ipairs(gVisualEffects) do
		EffectKill(fx)
	end
end

-- main
function main()
	local results = false
	local introduction = -1
	if type(PiShock) == "function" then
		SetCommand("rat_wars_shock",CB_SetShocker,false,"Usage: rat_wars_shock\nTurns on player death shocks during this game of Rat Wars.")
	end
	F_UpdateCrosshairUV(gSettings.crosshair)
	while gIntroduction do
		local passed = (GetSyncTimer() - gStarted) + gLateJoin
		local stage = math.max(1,math.ceil(passed/5000))
		if stage == 0 then
			stage = 1
		end
		if passed >= 15000 then
			break
		elseif stage ~= introduction then
			local map = gMaps[gMap]
			if stage == 1 then
				CameraSetXYZ(unpack(map.cameras.time_15))
			elseif stage == 2 then
				CameraSetXYZ(unpack(map.cameras.time_10))
			elseif stage == 3 then
				CameraSetXYZ(unpack(map.cameras.time_5))
			end
			introduction = stage
		end
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(200,200,200,255)
		SetTextOutline(0,0,0,255)
		SetTextAlign("C","T")
		SetTextScale(1.7)
		SetTextPosition(0.5,0.2)
		DrawText("STARTING IN "..math.ceil((15000-passed)/1000))
		F_UpdateMiscellaneous()
		Wait(0)
	end
	while gRatClass == "" do
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(200,200,200,255)
		SetTextOutline(0,0,0,255)
		SetTextAlign("C","T")
		SetTextScale(1.7)
		SetTextPosition(0.5,0.2)
		DrawText("STARTING IN 0")
		F_UpdateMiscellaneous()
		Wait(0)
	end
	gIntroduction = false
	CreateAdvancedThread("PRE_FADE","T_DrawHud")
	CreateAdvancedThread("POST_WORLD","T_DrawGun")
	while true do
		if IsKeyBeingPressed("B") then
			gSettings.crosshair = gSettings.crosshair + 1
			if not CROSSHAIR_SIZES[gSettings.crosshair] then
				gSettings.crosshair = 0
			end
			F_UpdateCrosshairUV(gSettings.crosshair)
			SavePersistentDataTables()
		elseif IsKeyBeingPressed("N") then
			gSettings.crosshair_color = math.mod(gSettings.crosshair_color,table.getn(CROSSHAIR_COLORS)) + 1
			SavePersistentDataTables()
		end
		F_UpdateInputSwitcher()
		F_UpdateDeathTracker()
		if gResults then
			if not results then
				if dsl.first_person and dsl.first_person.IsActive() then
					dsl.first_person.Stop()
				end
				CameraSetXYZ(unpack(gMaps[gMap].cameras.results))
				results = true
			end
		elseif dsl.first_person then
			local active = dsl.first_person.IsActive()
			if active or not (dsl.freecam and dsl.freecam.IsActive()) then
				if not active then
					dsl.first_person.Start()
				end
				if gGiantRat then
					dsl.first_person.ScaleRatHeight(GIANT_RAT_VISUAL)
				else
					dsl.first_person.ScaleRatHeight(RAT_REAL_SCALE)
				end
				if gEquipped and not gSwitching and not gRequestSwitch and not PedIsDead(gPlayer) then
					F_UpdateCurrentWeapon() -- weapon actions (including firing)
				end
			end
		end
		if gEquipped or gSwitching then
			F_UpdateEquipped() -- amount the weapon is equipped and aimed
		end
		if dsl.first_person then
			F_UpdateCameraFOV()
		end
		F_UpdateStatMult()
		F_UpdateStageRestrictions()
		F_UpdateWeaponPickups()
		F_UpdateOtherRats()
		F_UpdateGunshotSounds()
		F_UpdateMiscellaneous()
		Wait(0)
	end
end
function CB_SetShocker()
	if gShocker then
		PrintOutput("Shock was already turned on.")
	else
		PrintOutput("Turned on rat shocking.")
	end
	gShocker = true
end
function F_UpdateInputSwitcher()
	if GetStickValue(16,1) ~= 0 or GetStickValue(17,1) ~= 0 then
		if gInputSwitch == -1 then
			gInputSwitch = GetTimer()
		elseif GetTimer() - gInputSwitch >= SWITCH_INPUT_DELAY then
			local index = GetKeyboardController()
			if gInputBackup == -1 then
				gInputBackup = index
			end
			if index == 0 then
				SetKeyboardController(1)
			elseif index == 1 then
				SetKeyboardController(0)
			end
			gInputSwitch = -1
		end
	elseif gInputSwitch ~= -1 then
		gInputSwitch = -1
	end
end
function F_UpdateDeathTracker()
	if gKilled > 0 then
		if gKilled < 2 then
			if gShocker then
				PiShock(15,100)
			end
			PlayerSetHealth(0)
			PedSetDead(gPlayer,true)
			PedSetActionNode(gPlayer,"/GLOBAL/AN_RAT/HITRAT/DEATH/DEAD","")
			gKilled = 2
		elseif not PedIsDead(gPlayer) then
			gKilled = 0
			gKiller = nil
		end
		if gKilled > 0 and gKiller[2] then
			local ped = PedFromSyncPed(gKiller[2])
			if PedIsValid(ped) then
				if PedIsDead(ped) then
					gKiller[2] = nil
				elseif dsl.first_person then
					local x,y,z = F_GetRatPosition(ped)
					dsl.first_person.Assist(x,y,z,GetFrameTime()/DEATH_CAMERA_TIME)
				end
			end
		end
	end
end
function F_UpdateCurrentWeapon()
	local stats = gCurrentWeapon.stats
	if gSettings.assist and (stats.assist_on_kb or IsUsingJoystick(0)) and F_IsAimPressed() and stats.assist_range > 0 then
		F_AssistCurrentWeapon(stats.assist_range,math.rad(stats.assist_angle),stats.assist_slow,stats.assist_fast)
	end
	if gAim >= 0.5 and stats.scope_size > 0 and stats.scope_stages > 1 then -- ZOOM
		local scroll = 0
		if not IsUsingJoystick(0) then
			scroll = GetMouseScroll()
		elseif gScopeTimer == -1 or GetTimer() - gScopeTimer >= 30 then
			if F_IsControlPressed(2) then
				gScopeTimer = GetTimer()
				scroll = 1
			elseif F_IsControlPressed(3) then
				gScopeTimer = GetTimer()
				scroll = -1
			end
		end
		if scroll > 0 then
			if gCurrentWeapon.scope < stats.scope_stages - 1 then
				gCurrentWeapon.scope = gCurrentWeapon.scope + 1
				SendNetworkEvent("rat_wars:SetScopeStage",gCurrentWeapon.id,gCurrentWeapon.scope)
				gWeaponUpdates = gWeaponUpdates + 1
				F_PlaySound("LckNumClick","LckPick.bnk")
			end
		elseif scroll < 0 and gCurrentWeapon.scope > 0 then
			gCurrentWeapon.scope = gCurrentWeapon.scope - 1
			SendNetworkEvent("rat_wars:SetScopeStage",gCurrentWeapon.id,gCurrentWeapon.scope)
			gWeaponUpdates = gWeaponUpdates + 1
			F_PlaySound("LckNumClick","LckPick.bnk")
		end
	end
	if gSemiTimer ~= -1 and GetTimer() - gSemiTimer >= FIRE_MODE_DELAY then
		gSemiTimer = -1
	end
	if F_IsControlBeingPressed(15) and stats.full_auto and gSemiTimer == -1 then
		if gCurrentWeapon.semi then
			SendNetworkEvent("rat_wars:SelectFireMode",gCurrentWeapon.id)
			gWeaponUpdates = gWeaponUpdates + 1
			gCurrentWeapon.semi = false
		else
			SendNetworkEvent("rat_wars:SelectFireMode",gCurrentWeapon.id,true)
			gWeaponUpdates = gWeaponUpdates + 1
			gCurrentWeapon.semi = true
		end
		gSemiTimer = GetTimer()
		SoundPlay2D("Click")
	elseif not gReloading and not gSwitching and gEquip == 1 and gSemiTimer == -1 then
		if ((not gCurrentWeapon.cocked and F_IsControlBeingPressed(12)) or (F_IsControlBeingPressed(6) and F_ShouldAllowReload(gCurrentWeapon))) and (gRecoilTimer == -1 or (GetTimer() - gRecoilTimer) / stats.recoil_time_ms >= 0.5) then
			gReloading = true -- queue a reload asap
			gReloadTimer = -1
		elseif gFireTimer == -1 or GetTimer() - gFireTimer >= stats.fire_delay then
			if F_IsControlBeingPressed(8) then
				SendNetworkEvent("rat_wars:SwitchWeapon",gCurrentWeapon.id)
				gRequestSwitch = true
				gReloading = false
			elseif gCurrentWeapon.cocked and F_IsTriggerPressed(gCurrentWeapon) then
				if gCurrentWeapon.chamber or (gCurrentWeapon.stats.open_bolt and gCurrentWeapon.ammo > 0) then
					gFireTimer = GetTimer()
					F_FireCurrentWeapon()
				else
					F_PlaySound("SpudGunDryfire","Spudgun.bnk")
					SendNetworkEvent("rat_wars:DecockWeapon",gCurrentWeapon.id)
					gWeaponUpdates = gWeaponUpdates + 1
					gCurrentWeapon.cocked = false
				end
			end
		end
	end
end
function F_UpdateCameraFOV()
	local weapon = F_GetWeapon()
	local adrenaline = 1
	if gAdrenaline then
		if gAdrenalineFOV ~= 1 then
			gAdrenalineFOV = gAdrenalineFOV + GetFrameTime() / ADRENALINE_FX_FADE
			if gAdrenalineFOV > 1 then
				gAdrenalineFOV = 1
			end
		end
		adrenaline = 1 + ADRENALINE_FX_FOV * gAdrenalineFOV
	elseif gAdrenalineFOV ~= 0 then
		gAdrenalineFOV = gAdrenalineFOV - GetFrameTime() / ADRENALINE_FX_FADE
		if gAdrenalineFOV < 0 then
			gAdrenalineFOV = 0
		end
		adrenaline = 1 + ADRENALINE_FX_FOV * gAdrenalineFOV
	end
	if weapon then
		local push = 0 -- recoil camera push amount
		local recoil = 1 -- recoil camera fov multiplier
		local stats = weapon.stats
		local rat = 1 -- fov from rat class
		if gRatClass == "FOCUSED" and gAim >= 0.5 then
			rat = 1 - ((gAim-0.5)*gEquip*2) * 0.1 -- FOCUSED: +10% aim down sight speed
		end
		if gRecoilTimer ~= -1 then
			local scale = (GetTimer() - gRecoilTimer) / stats.recoil_time_ms
			local scale_2 = (GetTimer() - gRecoilTimer) / stats.recoil_push_ms
			if scale < 1 and stats.recoil_fov ~= 1 then
				recoil = 1 + math.sin(scale*math.pi) * (stats.recoil_fov - 1) * gRecoilMult
			end
			if scale_2 < 1 and stats.recoil_push_amount > 0 then
				push = math.sin((RECOIL_JUMP_START+(1-RECOIL_JUMP_START)*scale)*math.pi) * stats.recoil_push_amount
			end
			if scale >= 1 and scale_2 >= 1 then
				gRecoilTimer = -1
			end
		end
		if gAim < 0.5 then
			push = push * stats.recoil_push_hip
		end
		if push > 0 then
			local mult = GetFrameTime() * gRecoilMult * push
			local angle = gRecoilAngle
			if angle > math.pi then -- angle is in the range [0, 360) so we just need to check once to get to (-180,180]
				angle = angle - math.pi * 2
			end
			angle = angle * stats.recoil_push_ratio + math.rad(stats.recoil_push_base)
			dsl.first_person.Push(math.cos(angle)*mult,math.sin(angle)*mult)
		end
		dsl.first_person.AdjustFOV((1-(1-stats.scope_fov)*gAim*gEquip)*recoil*adrenaline*rat)
	else
		dsl.first_person.AdjustFOV(1*adrenaline)
	end
end
function F_UpdateStatMult()
	gSpeedMult = 1
	gRecoilMult = 1
	if not gAdrenaline and gRatClass == "JUNKIE" then
		gSpeedMult = gSpeedMult * (1 / 0.85) -- JUNKIE: -15% weapon handling speed
	elseif gRatClass == "SPEEDY" then
		gSpeedMult = gSpeedMult * (1 / 1.25) -- SPEEDY: +25% weapon handling speed
	elseif gRatClass == "FAT" then
		gSpeedMult = gSpeedMult * (1 / 0.6) -- FAT: -40% weapon handling speed
	elseif gRatClass == "FOCUSED" then
		gSpeedMult = gSpeedMult * (1 / 0.9) -- FOCUSED: -10% weapon handling speed
	end
	if gAim >= 0.5 then
		if gEquipped then
			gRecoilMult = gRecoilMult * gCurrentWeapon.stats.recoil_ads
		end
		if not gAdrenaline and gRatClass == "JUNKIE" then
			gRecoilMult = gRecoilMult * 1.2 -- JUNKIE: +20% extra recoil
		elseif gRatClass == "FOCUSED" then
			gRecoilMult = gRecoilMult * 0.7 -- FOCUSED: +30% recoil control
		end
	end
	if gAdrenaline then
		gSpeedMult = gSpeedMult * (1 / 1.8)
		gRecoilMult = gRecoilMult * 0.55
	end
end
function F_UpdateStageRestrictions()
	local map = gMaps[gMap]
	if AreaGetVisible() == map.area then
		local x1,y1,z1 = unpack(map.center)
		local x2,y2,z2 = PlayerGetPosXYZ()
		local dx,dy,dz = x2-x1,y2-y1,z2-z1
		if dx*dx+dy*dy+dz*dz >= map.radius*map.radius then
			local hp = PlayerGetHealth() - GetFrameTime() * 50
			if hp <= 0 then
				PlayerSetHealth(0)
				PedSetDead(gPlayer,true)
				PedSetActionNode(gPlayer,"/GLOBAL/AN_RAT/HITRAT/DEATH/DEAD","")
			else
				PlayerSetHealth(hp)
			end
		end
		if gMap == "warehouse" then -- don't fall off ledges
			local x,y,z = PlayerGetPosXYZ()
			if z >= 6.7 and z < 7 then
				if x < -596.2 and y >= -145.9 and y < -141.9 then
					PlayerSetPosSimple(-596.2,y,z)
				elseif x < -596.1 and y >= -173.2 and y < -163.2 then
					PlayerSetPosSimple(-596.1,y,z)
				end
			end
		elseif gMap == "the_tenements" then
			local x,y,z = PlayerGetPosXYZ()
			if x < -549.61 and y >= -32.51 and y < -29.01 and z >= 35.73 and z < 36.74 then
				PlayerSetPosSimple(-549.61,y,z)
			end
		end
	elseif not PedIsDead(gPlayer) and not AreaIsLoading() then
		PlayerSetHealth(0)
		PedSetDead(gPlayer,true)
		PedSetActionNode(gPlayer,"/GLOBAL/AN_RAT/HITRAT/DEATH/DEAD","")
	end
end
function F_UpdateWeaponPickups()
	local x1,y1,z1 = PlayerGetPosXYZ()
	local nearest,distance = nil,PICKUP_DRAW_RANGE*PICKUP_DRAW_RANGE
	for pickup in AllPickups() do -- delete non rat wars pickups
		if not gPickupAllow[pickup] then
			RemovePickup(pickup)
		end
	end
	for ent,pickup in pairs(gPickups) do
		if IsSyncEntityActive(ent) then
			local x2,y2,z2 = GetSyncEntityPos(ent)
			if pickup.id and not (PickupIsPickedUp(pickup.id) or F_ShouldRespawnPickup(pickup,x2,y2,z2)) then
				local dx,dy,dz = x2-x1,y2-y1,z2-z1
				local dist = dx*dx+dy*dy+dz*dz
				if dist < distance then
					nearest,distance = ent,dist
				end
			elseif not pickup.picked then
				local x,y,z = GetSyncEntityPos(ent)
				local model = GetSyncEntityModel(ent)
				if model == 10152 then
					x = x + 0.3
				end
				pickup.id = PickupCreateXYZ(model,x,y,z,"PermanentMission")
				gPickupAllow[pickup.id] = true
				gPickupSpawns = gPickupSpawns + 1
				if gPickupSpawns >= 1000 then
					PrintWarning("Spawned 1000 pickups.")
					gPickupSpawns = 0
				end
			end
		elseif pickup.id then
			if not PickupIsPickedUp(pickup.id) then
				PickupDelete(pickup.id)
			end
			gPickupAllow[pickup.id] = nil
			pickup.id = nil
		end
		pickup.draw = false
	end
	if nearest and not PedIsDead(gPlayer) then
		if IsUsingJoystick(0) then
			if gPickupBinding ~= 1 then
				local t,v = GetInputHardware(9,0)
				if t == "button" then
					local name = F_GetButtonTexture(v)
					if name then
						local texture = GetHudTexture(name)
						if texture then
							gPickupBinding = 1
							gPickupTexture = texture
						end
					end
				end
			end
		elseif gPickupBinding ~= 2 then
			local texture = GetHudTexture("Button_F")
			if texture then
				gPickupBinding = 2
				gPickupTexture = texture
			end
		end
		if (gPickups[nearest].auto or F_IsControlBeingPressed(9)) and distance < PICKUP_RANGE*PICKUP_RANGE then
			local data = gPickups[nearest]
			if data.id then
				PickupDelete(data.id)
				data.id = nil
			end
			SendNetworkEvent("rat_wars:PickupStuff",nearest)
			data.picked = true
		else
			gPickups[nearest].draw = true
		end
	end
end
function F_UpdateOtherRats()
	local heading = 0
	if dsl.first_person then
		local dx,dy = dsl.first_person.GetDirection()
		heading = math.atan2(-dx,dy)
	end
	for sped,fake in pairs(gPlayers) do
		local ped = PedFromSyncPed(sped)
		if PedIsValid(ped) then
			if F_ShouldShowHitrat(ped,fake,heading) then
				if not PedIsValid(fake) then
					if fake ~= -1 then
						gFakes[fake] = nil
					end
					fake = F_GetOrCreateHitrat(sped,PedGetPosXYZ(ped))
				end
			elseif fake ~= -1 then
				if PedIsValid(fake) then
					PedDelete(fake)
				end
				gPlayers[sped] = -1
				gFakes[fake] = nil
				fake = -1
			end
			if PedIsValid(ped) then
				if PedIsValid(fake) then
					if PedIsHit(fake,2,100) then
						local damage = PedGetHitRecordDamage(fake)
						if damage > 0 then
							if not PedIsDead(ped) then
								local weapon = PedGetLastHitWeapon(fake)
								if weapon ~= -1 then
									SendNetworkEvent("rat_wars:HitPlayer",sped,damage,weapon)
								end
							end
							if PedGetHealth(ped) > damage then
								local x,y,z = F_GetRatPosition(ped)
								if gVisualEffects.n >= MAX_EFFECTS then
									EffectKill(table.remove(gVisualEffects,1))
								end
								F_SpawnShotEffect(x,y,z)
							end
							PedSetHitRecordDamage(fake,0)
						end
					end
					if PedIsDead(fake) then
						PedSetDead(fake,false)
					elseif PedIsPlaying(fake,"/GLOBAL/AN_RAT/HITRAT",true) then
						PedSetActionNode(fake,"/GLOBAL","") -- should keep from dying
					end
					PedSetAlpha(fake,0,true)
					PedOverrideStat(fake,0,-1)
					PedOverrideStat(fake,1,0)
					PedSetHealth(fake,PedGetHealth(ped))
					PedSetMaxHealth(fake,PedGetMaxHealth(ped))
					PedSetPosSimple(fake,PedGetPosXYZ(ped))
					PedFaceHeading(fake,math.deg(PedGetHeading(ped)),0)
					PedSetStationary(fake,true)
					PedMakeTargetable(fake,false)
					PedSetEffectedByGravity(fake,false)
					PedIgnoreAttackCone(fake,true)
					PedIgnoreAttacks(fake,true)
					PedIgnoreStimuli(fake,true)
					PedClearObjectives(fake)
				end
				PedSetUsesCollisionScripted(ped,true) -- can't shoot real ped, only fake one
				PedSetEffectedByGravity(ped,false)
			elseif fake ~= -1 then -- CAN HAPPEN IF PedCreateXYZ DELETED OUR REAL PED
				if PedIsValid(fake) then
					PedDelete(fake)
				end
				gPlayers[sped] = -1
				gFakes[fake] = nil
			end
		elseif fake ~= -1 then
			if PedIsValid(fake) then
				PedDelete(fake)
			end
			gPlayers[sped] = -1
			gFakes[fake] = nil
		end
	end
end
function F_UpdateGunshotSounds()
	-- delaying gunshots prevents loud sound bursts from lag
	for sped,data in pairs(gGunshots) do
		for i = data.replay,1,-1 do
			for index,sound in ipairs(data.sounds) do
				F_PlaySound(sound,data.banks[index],data.x,data.y,data.z)
			end
		end
		gGunshots[sped] = nil
	end
	if gPickupSounds[0] then
		local s,b = unpack(gPickupSounds[0])
		F_PlaySound(s,b)
		gPickupSounds[0] = nil
	end
	for i,v in ipairs(gPickupSounds) do
		F_PlaySound(unpack(v))
		gPickupSounds[i] = nil
	end
	if gHitSound then
		if gHitMarker ~= -1 then
			local sound = "GritKikHevA"
			for i = 1,2 do
				SoundPlay2D(sound)
			end
		end
		gHitSound = false
	end
	if gKillSound then
		if gKillStreak >= 5 then
			F_PlaySound("BellHit","HiStrkr.bnk")
			if gKillStreak == 10 then
				F_PlaySound("WinAlrm","BallToss.bnk")
				F_PlaySound("WinFirewroks","BallToss.bnk")
				F_PlaySound("WinSiren","BallToss.bnk")
			elseif gKillStreak == 30 then
				SoundPlay2D("Trophy")
			end
		end
		gKillSound = false
	end
end
function F_UpdateMiscellaneous()
	for _,c in ipairs(HIDE_HUD_COMPS) do
		ToggleHUDComponentVisibility(c,false)
	end
	if PedGetWeapon(gPlayer) ~= -1 then
		PedSetWeaponNow(gPlayer,-1)
	end
	PedSetInvulnerable(gPlayer,true)
	PlayerWeaponHudLock(true)
	PauseGameClock()
end

-- pickups
function F_ShouldRespawnPickup(pickup,x2,y2,z2)
	local x1,y1,z1 = PickupGetXYZ(pickup.id)
	local dx,dy,dz = x2-x1,y2-y1,z2-z1
	if dx*dx+dy*dy+dz*dz >= 16 then
		PickupDelete(pickup.id)
		gPickupAllow[pickup.id] = nil
		pickup.id = nil
		return true
	end
	return false
end

-- current weapon
function F_ShouldAllowReload(weapon)
	return not weapon.cocked or (not weapon.stats.open_bolt and not weapon.chamber) or weapon.ammo < weapon.stats.magazine_size
end
function F_ShouldForceReload(weapon)
	return not weapon.cocked or not weapon.chamber or (weapon.stats.open_bolt and weapon.ammo == 0)
end
function F_AssistCurrentWeapon(range,angle,slow,fast)
	local nearest,distance = nil,1
	local x1,y1,z1 = dsl.first_person.GetPosition()
	for sped in pairs(gPlayers) do
		local ped = PedFromSyncPed(sped)
		if PedIsValid(ped) and not PedIsDead(ped) then
			local x2,y2,z2 = F_GetRatPosition(ped)
			local dx,dy,dz = x2-x1,y2-y1,z2-z1
			local dist = math.sqrt(dx*dx+dy*dy+dz*dz)
			if dist < range then
				local cx,cy,cz = dsl.first_person.GetDirection()
				local dx,dy,dz = dx/dist-cx,dy/dist-cy,dz/dist-cz
				local ang = math.acos((2-(dx*dx+dy*dy+dz*dz))/2)
				if ang < angle then
					dist = (1 - (1 - dist / range) * (1 - ang / angle))
					if dist < distance then
						nearest,distance = {x2,y2,z2},dist
					end
				end
			end
		end
	end
	if nearest and gAim >= 0.5 then
		local x,y,z = unpack(nearest)
		if slow then
			slow = fast * (1 - distance) + slow * distance
			dsl.first_person.Assist(x,y,z,(GetFrameTime()/slow)*((gAim-0.5)*2))
		else
			dsl.first_person.Assist(x,y,z)
		end
	end
end
function F_FireCurrentWeapon()
	local stats = gCurrentWeapon.stats
	local power = stats.projectile_power
	local cx,cy,cz = dsl.first_person.GetPosition()
	local dx,dy,dz = dsl.first_person.GetDirection()
	local dist = stats.spawn_dist_base + stats.spawn_dist_pitch * math.max(0,math.sin(F_GetPitch(dx,dy,dz)))
	if gAim >= 0.5 then
		cx,cy,cz = cx+dx*dist,cy+dy*dist,cz+dz*dist+stats.shoot_aim_height
		if stats.shoot_aim_pitch ~= 0 then
			local h,p = math.atan2(-dx,dy),math.asin(dz)+math.rad(stats.shoot_aim_pitch)
			dx,dy,dz = -math.cos(p)*math.sin(h),math.cos(p)*math.cos(h),math.sin(p)
		end
	else
		cx,cy,cz = cx+dx*dist,cy+dy*dist,cz+dz*dist+stats.shoot_hip_height
		if stats.shoot_hip_offset ~= 0 then
			local h = math.atan2(-dx,dy)
			cx = cx + math.cos(h) * stats.shoot_hip_offset
			cy = cy + math.sin(h) * stats.shoot_hip_offset
		end
		if stats.shoot_hip_pitch ~= 0 or stats.shoot_hip_heading ~= 0 then
			local h,p = math.atan2(-dx,dy)+math.rad(stats.shoot_hip_heading),math.asin(dz)+math.rad(stats.shoot_hip_pitch)
			dx,dy,dz = -math.cos(p)*math.sin(h),math.cos(p)*math.cos(h),math.sin(p)
		end
	end
	SendNetworkEvent("rat_wars:ShootWeapon",gCurrentWeapon.id,cx,cy,cz,dx,dy,dz)
	gWeaponUpdates = gWeaponUpdates + 1
	dist = math.sqrt(dx*dx+dy*dy+dz*dz)
	if gRecoilTimer ~= -1 and stats.recoil_spread > 0 then
		local rotate = math.rad(stats.recoil_spread)
		local rx,ry = F_GetRecoilOffset(stats)
		local p,h = ry*rotate,-rx*rotate+math.atan2(-dx,dy)
		if dist > 0 then
			p = p + math.asin(dz/dist)
		end
		dx,dy,dz = -math.cos(p)*math.sin(h)*dist,math.cos(p)*math.cos(h)*dist,math.sin(p)*dist
		cx = cx + rx * GetDisplayAspectRatio()
		cz = cz + ry
	end
	cz = cz - (1 - (gEquip * ((math.abs(0.5 - gAim) * 2)))) * 0.5
	CreateProjectile(stats.projectile_id,cx,cy,cz,(dx/dist)*power,(dy/dist)*power,(dz/dist)*power,stats.projectile_damage)
	gShootPosition = {cx,cy,cz}
	for i = stats.sound_duplicate,1,-1 do
		for index,sound in ipairs(stats.sound_names) do
			F_PlaySound(sound,stats.sound_banks[index])
		end
	end
	if not DEBUG_NO_RECOIL and stats.recoil_time_ms > 0 then
		gRecoilTimer = GetTimer()
		gRecoilAim = gAim >= 0.5
		if DEBUG_UP_RECOIL then
			gRecoilOffset = stats.recoil_offset
			gRecoilAngle = 0
		else
			gRecoilOffset = math.random() * stats.recoil_offset
			gRecoilAngle = math.random() * math.pi * 2
		end
	end
	if stats.bolt_action then
		gCurrentWeapon.chamber = false
		gCurrentWeapon.cocked = false
	elseif gCurrentWeapon.ammo > 0 then
		gCurrentWeapon.ammo = gCurrentWeapon.ammo - 1
	else
		gCurrentWeapon.chamber = false
	end
end
function F_GetRecoilOffset(stats)
	local scale,rx,ry = F_GetRecoilScale(stats)
	return rx*(scale-1),ry*(scale-1)
end

-- hitbox rats
function F_ShouldShowHitrat(ped,fake,heading)
	local x1,y1 = PlayerGetPosXYZ()
	local x2,y2 = PedGetPosXYZ(ped)
	local dx,dy = x2-x1,y2-y1
	local h = math.atan2(-dx,dy) - heading
	while h > math.pi do
		h = h - math.pi * 2
	end
	while h <= -math.pi do
		h = h + math.pi * 2
	end
	if math.abs(h) >= HITRAT_ANGLE and dx*dx+dy*dy >= HITRAT_DISTANCE*HITRAT_DISTANCE then
		if KEEP_HITRATS > 0 then
			local data = gFakes[fake]
			if data and PedIsValid(fake) then
				if not data.delete then
					PedSetUsesCollisionScripted(fake,true) -- no collision with fake rat
					data.delete = GetTimer()
					return true
				end
				return GetTimer() - data.delete < KEEP_HITRATS -- keep for grace period
			end
			return false
		end
	elseif gFakes[fake] then
		local data = gFakes[fake]
		if data and data.delete then
			if PedIsValid(fake) then
				PedSetUsesCollisionScripted(fake,false)
			end
			data.delete = nil
		end
	end
	return true -- needed
end
function F_GetBetterHitrat(sx,sy,sz)
	local px,py,pz = PlayerGetPosXYZ()
	local dx,dy,dz = sx-px,sy-py,sz-pz
	local distance = dx*dx+dy*dy+dz*dz
	for sped,fake in pairs(gPlayers) do
		local ped = PedFromSyncPed(sped)
		if not PedIsValid(ped) then
			gPlayers[sped] = -1
			return fake -- real ped isn't valid, use this one
		elseif PedIsValid(fake) then
			local fx,fy,fz = PedGetPosXYZ(ped)
			dx,dy,dz = fx-px,fy-py,fz-pz
			if dx*dx+dy*dy+dz*dz > distance then
				gPlayers[sped] = -1
				return fake -- this fake ped is farther, so use it
			end
		end
	end
	return -1
end
function F_GetOrCreateHitrat(sped,x,y,z)
	local ped = -1
	for fake,data in pairs(gFakes) do
		if data.delete and PedIsValid(fake) then
			for sped,value in pairs(gPlayers) do
				if value == fake then
					gPlayers[sped] = -1 -- clear old reference
				end
			end
			PedSetUsesCollisionScripted(fake,false) -- allow collision again
			ped = fake -- re-use rat that was put up for deletion
			break
		end
	end
	if ped == -1 then
		local count = 0
		for fake in pairs(gFakes) do
			if PedIsValid(fake) then
				count = count + 1
			end
		end
		if count >= MAX_HITRATS then
			ped = F_GetBetterHitrat(x,y,z)
		else
			ped = PedCreateXYZ(136,x,y,z)
		end
	end
	if PedIsValid(ped) then
		gPlayers[sped] = ped
		gFakes[ped] = {}
		return ped
	end
	gPlayers[sped] = -1
	gFakes[ped] = nil
	return -1
end

-- effects
function F_SpawnShotEffect(x2,y2,z2)
	local fx = EffectCreate("TacksThrown",x2,y2,z2)
	if EffectIsRunning(fx) then
		local x1,y1,z1 = unpack(gShootPosition)
		local dx,dy,dz = x2-x1,y2-y1,z2-z1
		local dist = dx*dx+dy*dy+dz*dz
		if dist > 0 then
			local p = -math.asin(dz/math.sqrt(dist)) - math.rad(30)
			local h = math.atan2(-dx,dy) + math.pi
			EffectSetDirection(fx,-math.cos(p)*math.sin(h),math.cos(p)*math.cos(h),math.sin(p))
		end
		table.insert(gVisualEffects,fx)
	end
end

-- controls
function F_IsAimPressed()
	return gLockAim or F_IsControlPressed(10)
end
function F_IsTriggerPressed(weapon)
	if not weapon.semi and weapon.stats.full_auto then
		return F_IsControlPressed(12)
	end
	return F_IsControlBeingPressed(12)
end
function F_IsControlBeingPressed(button)
	return (gButtonsNow[button] and not gButtonsLast[button]) or IsButtonBeingPressed(button,0)
end
function F_IsControlPressed(button)
	return gButtonsNow[button] or IsButtonPressed(button,0)
end

-- equipped
function F_UpdateEquipped()
	local fp = false -- in first person?
	local stats = F_GetWeapon().stats
	if dsl.first_person and dsl.first_person.IsActive() then
		fp = true
	end
	if fp and not gReloading and not gSwitching and not PedIsDead(gPlayer) then
		if gEquip ~= 1 then
			gEquip = gEquip + GetFrameTime() * (1000 / (stats.equip_ms * gSpeedMult))
			if gEquip > 1 then
				gEquip = 1
			end
		end
		if gEquip == 1 then
			if (F_IsAimPressed() and stats.can_aim and gRecoilTimer == -1) or (gRecoilAim and gRecoilTimer ~= -1) then
				if gAim ~= 1 then
					gAim = gAim + GetFrameTime() * (1000 / (stats.aim_in_ms * gSpeedMult))
					if gAim > 1 then
						gAim = 1
					end
				end
			elseif gAim ~= 0 then
				gAim = gAim - GetFrameTime() * (1000 / (stats.aim_out_ms * gSpeedMult))
				if gAim < 0 then
					gAim = 0
				end
			end
		end
	elseif gEquip ~= 0 then
		if gSwitching then
			stats = gPreviousWeapon.stats
		end
		gEquip = gEquip - GetFrameTime() * (1000 / (stats.unequip_ms * gSpeedMult))
		if gEquip <= 0 then
			if gSwitching then
				gSwitching = false
				gPreviousWeapon = nil
			end
			gRecoilTimer = -1
			gScopeTimer = -1
			gSemiTimer = -1
			gFireTimer = -1
			gEquip = 0
			gAim = 0
			if fp and gEquipped and not gReloading and not PedIsDead(gPlayer) then
				stats = gCurrentWeapon.stats
				if stats.can_aim and F_IsAimPressed() and not PedIsDead(gPlayer) then
					gAim = 1 -- if holding aim on switch, just be aiming to begin with
				end
			end
		end
	end
	if gReloading then -- gReloading being true ensures we have a weapon and aren't switching (so stats is valid)
		if PedIsDead(gPlayer) then
			gReloading = false
		elseif gEquip == 0 then
			if gReloadTimer == -1 then
				gReloadTimer = GetTimer()
				if F_IsControlPressed(6) or stats.open_bolt or gCurrentWeapon.chamber or gCurrentWeapon.ammo == 0 then
					SendNetworkEvent("rat_wars:ReloadSound",true)
					F_PlaySound("SpudGun_Reload","Spudgun.bnk")
					gReloadMagazine = true
				else
					SendNetworkEvent("rat_wars:ReloadSound")
					F_PlaySound("GunPump","ShotGall.bnk")
					gReloadMagazine = false
				end
			elseif gReloadMagazine then
				if GetTimer() - gReloadTimer >= stats.reload_ms * gSpeedMult then
					local topoff = false
					if F_IsControlPressed(6) and stats.bolt_action and gCurrentWeapon.ammo > 0 then
						topoff = true
					end
					SendNetworkEvent("rat_wars:ReloadWeapon",gCurrentWeapon.id,true,topoff)
					gWeaponUpdates = gWeaponUpdates + 1
					gCurrentWeapon.ammo = stats.magazine_size
					if not stats.open_bolt and not gCurrentWeapon.chamber then -- also chamber a round
						if not topoff then
							gCurrentWeapon.ammo = gCurrentWeapon.ammo - 1 -- top off bolt actions
						end
						gCurrentWeapon.chamber = true
					end
					gCurrentWeapon.cocked = true
					gReloading = false
				end
			elseif GetTimer() - gReloadTimer >= stats.rechamber_ms then
				if not gCurrentWeapon.chamber then -- can't happen on open bolt because gReloadMagazine is true
					SendNetworkEvent("rat_wars:ReloadWeapon",gCurrentWeapon.id)
					gWeaponUpdates = gWeaponUpdates + 1
					gCurrentWeapon.ammo = gCurrentWeapon.ammo - 1
					gCurrentWeapon.chamber = true
					gCurrentWeapon.cocked = true
				end
				gReloading = false
			end
			if not gReloading then
				if stats.can_aim and F_IsAimPressed() then
					gAim = 1
				else
					gAim = 0
				end
			end
		elseif gReloadTimer ~= -1 then
			gReloadTimer = -1
		end
	end
end
function F_EquipWeapon(id,state)
	local stats = gWeapons[id]
	if gEquipped and gEquip ~= 0 then
		gSwitching = true
		gPreviousWeapon = gCurrentWeapon
	else
		gSwitching = false
		gPreviousWeapon = nil
	end
	if stats then
		gEquipped = true
		gCurrentWeapon = state -- .id, .stats, .ammo, .chamber, .cocked, .semi, .scope
		state.stats = stats
		state.id = id
	else
		gEquipped = false
		gCurrentWeapon = nil
	end
	gReloading = false -- cancel pending reload on new weapon
end
function F_UpdateWeapon(state)
	for k,v in pairs(state) do
		gCurrentWeapon[k] = v
	end
end
function F_GetWeapon()
	if gSwitching then
		return gPreviousWeapon
	elseif gEquipped then
		return gCurrentWeapon
	end
end

-- drawing (hud)
function T_DrawHud()
	local icon -- current icon index
	local killed -- when you were killed
	local adrenaline = 0
	local started -- when you started adrenaline
	local x1,y1,x2,y2 -- uv
	while IsPauseMenuActive() or IsMapMenuActive() do
		Wait(0)
	end
	while not gResults do
		local weapon = F_GetWeapon()
		local ms = gDuration - (GetSyncTimer() - gStarted)
		if gAdrenaline then
			if adrenaline ~= 1 then
				if adrenaline == 0 then
					started = GetTimer()
				end
				adrenaline = adrenaline + GetFrameTime() / ADRENALINE_FX_FADE
				if adrenaline > 1 then
					adrenaline = 1
				end
			end
			F_DrawAdrenaline(started,adrenaline)
		elseif adrenaline ~= 0 then
			adrenaline = adrenaline - GetFrameTime() / ADRENALINE_FX_FADE
			if adrenaline < 0 then
				adrenaline = 0
			end
		end
		if adrenaline > 0 then
			F_DrawAdrenaline(started,adrenaline)
		end
		if ms >= 0 and ms < 1 / 0 then
			F_DrawGameTimer(ms)
		end
		if weapon then
			local stats = weapon.stats
			if stats.icon_index > 0 then
				local mode = 1
				if weapon.stats.full_auto and not weapon.semi then
					mode = 4
				end
				if icon ~= stats.icon_index then
					x1,y1,x2,y2 = F_GetIconUV(stats.icon_index-1)
					icon = stats.icon_index
				end
				SetTextureBounds(gIcons,x1,y1,x2,y2)
				if weapon.chamber then
					F_DrawWeaponHud(gCircle,gIcons,stats.icon_scale,weapon.ammo+1,weapon.cocked,mode)
				elseif stats.open_bolt and weapon.ammo > 0 then
					F_DrawWeaponHud(gCircle,gIcons,stats.icon_scale,weapon.ammo,weapon.cocked,mode)
				else
					F_DrawWeaponHud(gCircle,gIcons,stats.icon_scale,weapon.ammo,false,mode)
				end
			elseif icon then
				icon = nil
			end
		end
		F_DrawHealthBar(gCircle,math.max(0,math.min(1,PedGetHealth(gPlayer)/PedGetMaxHealth(gPlayer))))
		if gKillFeed[1] then
			F_DrawKillFeed()
		end
		if gKillStreak > 0 then
			F_DrawPlayerKills()
		end
		if gKilled > 0 then
			if not killed then
				killed = GetTimer()
			end
			F_DrawKillerName(gKiller[1],math.min(1,(GetTimer()-killed)/(DEATH_CAMERA_TIME*1000)))
		elseif killed then
			killed = nil
		end
		if gSettings.crosshair > 0 and gEquip * gAim < 0.5 then
			local size = CROSSHAIR_SIZES[gSettings.crosshair]
			local ar = GetDisplayAspectRatio()
			local rgb = CROSSHAIR_COLORS[gSettings.crosshair_color]
			if rgb then
				local r,g,b = unpack(rgb)
				DrawTexture(gCrosshairs,0.5-(size*0.5)/ar,0.5-size*0.5,size/ar,size,r,g,b,255*(1-(gEquip*gAim)*2))
			end
		end
		if gHitMarker ~= -1 then
			local alpha = HIT_MARKER_ALPHA
			local passed = GetTimer() - gHitMarker
			if passed >= HIT_MARKER_HOLD_MS then
				local fade = (passed - HIT_MARKER_HOLD_MS) / HIT_MARKER_FADE_MS
				if fade >= 1 then
					gHitMarker = -1
					alpha = 0
				else
					alpha = alpha * (1 - fade)
				end
			end
			if gHitSize > 0 and alpha > 0 then
				local ar = GetDisplayAspectRatio()
				local x,y = unpack(gHitPosition)
				local w = gHitSize / ar
				local h = gHitSize
				x = x - (gHitSize * 0.5) / ar
				y = y - gHitSize * 0.5
				if gHitKilled then
					DrawTexture(gMarker,x,y,w,h,255,20,20,alpha)
				else
					DrawTexture(gMarker,x,y,w,h,255,230,230,alpha)
				end
			end
		end
		if F_IsControlPressed(4) then
			F_DrawPlayerScores(gScores)
		end
		repeat
			Wait(0)
		until not IsPauseMenuActive() and not IsMapMenuActive()
	end
	return T_DrawResults()
end
function F_DrawAdrenaline(started,visibility)
	local ms = (GetTimer() - started) * ADRENALINE_FX_RATE
	local hue = math.mod((ms/1000)*360,360)
	local huebg = math.mod((ms/1350)*360,360)
	local size = 1.2 + 0.1 * math.sin(math.mod(ms/2000,1)*math.pi*0.5)
	local alpha = (0.8 + 0.2 * math.sin(math.mod(ms/1500,1)*math.pi*0.5)) * visibility * ADRENALINE_FX_ALPHA
	DrawRectangle(0.5-size*0.5,0.5-size*0.5,size,size,F_HSVA(huebg,1,1,math.min(1,alpha*0.04)))
	DrawTexture(gAdrenalineScreen,0.5-size*0.5,0.5-size*0.5,size,size,F_HSVA(hue,1,1,math.min(1,alpha)))
end
function F_DrawGameTimer(ms)
	SetTextFont("Georgia")
	SetTextBold()
	SetTextColor(200,200,200,255)
	SetTextOutline(0,0,0,255)
	SetTextAlign("C","T")
	SetTextScale(1.5)
	SetTextPosition(0.5,0.01)
	if ms < gWarning then
		SoundPlay2D("Time")
		if gWarning > 11000 then
			gWarning = 11000
		elseif gWarning <= 1000 then
			gWarning = -1 / 0
		else
			gWarning = gWarning - 1000
		end
	end
	if ms < 31000 then
		SetTextColor(230,80,80,255)
	end
	if ms >= 60000 then
		DrawText("%d:%.2d",math.floor((ms/1000)/60),math.mod(math.floor(ms/1000),60))
	elseif ms >= 10000 then
		DrawText(math.mod(math.floor(ms/1000),60))
	else
		DrawText("%.1f",ms/1000)
	end
end
function F_DrawWeaponHud(circle,icon,scale,ammo,ready,mode)
	local ar = GetDisplayAspectRatio()
	local curve = 0.005
	local width = INFO_HUD_WIDTH
	local height = width / (4 / 3)
	local pad_x = 0.015
	local pad_y = 0.07
	local pad_2 = 0.004
	local pad_3 = 0.006
	local pad_4 = 0.002 -- for ammo
	local ratio = 4/3
	local x,y,w,h = 1-(width+pad_x-pad_2-pad_3-((width-width/ratio)*0.5))/ar,1-(height+pad_y-pad_2-pad_3),(width/ratio-((pad_2+pad_3)*2))/ar,height-(pad_2+pad_3)*2
	DrawRectangle(1-(width+pad_x-pad_2)/ar,1-(height+pad_y-pad_2),(width-((pad_2)*2))/ar,height-(pad_2)*2,55,50,45,120) -- draw transparent background first
	F_DrawRounded_2(circle,curve,1-(width+pad_x)/ar,1-(height+pad_y),width/ar,height,120,120,120,255)
	F_DrawRounded_2(circle,curve,1-(width+pad_x-pad_2)/ar,1-(height+pad_y-pad_2),(width-(pad_2*2))/ar,height-pad_2*2,0,0,0,255)
	if scale ~= 1 then
		scale = (scale - 1) * h
		DrawTexture(icon,x-(scale*0.5)/ar,y-scale*0.5,w+scale/ar,h+scale,255,255,255,255)
	else
		DrawTexture(icon,x,y,w,h,255,255,255,255)
	end
	SetTextFont("Georgia")
	SetTextBold()
	if ready then
		SetTextColor(230,230,230,255)
	else
		SetTextColor(230,50,50,255)
	end
	SetTextOutline()
	SetTextAlign("L","B")
	SetTextHeight(height*0.12)
	SetTextPosition(1-(width+pad_x-pad_2-pad_3-pad_4)/ar,1-(pad_y+pad_2+pad_3+pad_4))
	DrawText(ammo)
	if mode > 0 then
		local size = 0.004
		local tar = GetTextureAspectRatio(gBullet) / ar
		for i = mode-1,0,-1 do
			DrawTexture(gBullet,1-((pad_x+pad_2+pad_3+pad_4)/ar+size*tar),1-(pad_y+pad_2+pad_3+pad_4+size*(1+i*1.15)),size*tar,size,255,255,255,255)
		end
	end
end
function F_DrawHealthBar(circle,ratio)
	local ar = GetDisplayAspectRatio()
	local curve = 0.005
	local width = INFO_HUD_WIDTH
	local height = 0.055
	local pad_1 = 0.015
	local pad_2 = 0.004
	local pad_3 = 0.006
	local greener = 0.7 + 0.3 * ((ratio - HEALTH_WARNING) / (1 - HEALTH_WARNING))
	local washout = 0.7 + 0.3 * (1 - (ratio - HEALTH_WARNING) / (1 - HEALTH_WARNING))
	local r,g,b = 80*washout,255*greener,80*washout
	if ratio < HEALTH_WARNING then
		local brighter = 0.7 + 0.3 * (1 - ratio / HEALTH_WARNING)
		local washout = 0.7 + 0.3 * (ratio / HEALTH_WARNING)
		r,g,b = 255*brighter,80*washout,80*washout
	end
	F_DrawRounded(circle,curve,1-(width+pad_1)/ar,1-(height+pad_1),width/ar,height,120,120,120,255)
	F_DrawRounded(circle,curve,1-(width+pad_1-pad_2)/ar,1-(height+pad_1-pad_2),(width-(pad_2*2))/ar,height-pad_2*2,0,0,0,255)
	DrawRectangle(1-(width+pad_1-pad_2-pad_3)/ar,1-(height+pad_1-pad_2-pad_3),(width-((pad_2+pad_3)*2))/ar,height-(pad_2+pad_3)*2,55,50,45,255)
	DrawRectangle(1-(width+pad_1-pad_2-pad_3)/ar,1-(height+pad_1-pad_2-pad_3),((width-((pad_2+pad_3)*2))/ar)*ratio,height-(pad_2+pad_3)*2,r,g,b,255)
end
function F_DrawKillFeed()
	local slide = 0
	local size = 0.02 -- of gun icon
	local extra = 0.02 -- extra icon size
	local space = 0.017
	local shadow = 0.001
	local ar = GetDisplayAspectRatio()
	local timer = GetTimer()
	local i,v = 1,gKillFeed[1]
	while v do
		local ms = timer - v.when
		if ms < KILL_FEED_DURATION then
			local alpha = 255
			local x,y = 0.2/ar,0.55-((size+extra*0.5)*1.02)*slide
			if ms < KILL_FEED_TRANSITION then
				alpha = 255 * math.sin((ms/KILL_FEED_TRANSITION)*math.pi*0.5)
			elseif ms >= KILL_FEED_DURATION - KILL_FEED_TRANSITION then
				alpha = 255 * math.sin(((KILL_FEED_DURATION-ms)/KILL_FEED_TRANSITION)*math.pi*0.5)
			end
			SetTextFont("Arial")
			SetTextBlack()
			SetTextColor(v.r1,v.g1,v.b1,alpha)
			SetTextShadow()
			SetTextAlign("R","C")
			SetTextPosition(x-space/ar,y+size*0.5)
			SetTextHeight(size)
			DrawText(v.killer)
			if v.icon then
				local ix,iy,iw,ih = x-(extra*0.5)/ar,y-extra*0.5,(size+extra)/ar,size+extra
				SetTextureBounds(gIcons,unpack(v.icon))
				SetTextureColorBlending(2)
				DrawTexture(gIcons,ix+shadow/ar,iy+shadow,iw,ih,0,0,0,100*(alpha/255))
				if v.rainbow then
					local hue = (ms / 700) * 360
					DrawTexture(gIcons,ix,iy,iw,ih,F_HSVA(math.mod(hue,360),0.7,1,alpha/255))
				else
					DrawTexture(gIcons,ix,iy,iw,ih,255,80,80,alpha)
				end
				SetTextureColorBlending(0)
			else
				DrawRectangle(x,y,size/ar,size,255,0,255,alpha)
			end
			SetTextFont("Arial")
			SetTextBlack()
			SetTextColor(v.r2,v.g2,v.b2,alpha)
			SetTextShadow()
			SetTextAlign("L","C")
			SetTextPosition(x+(size+space)/ar,y+size*0.5)
			SetTextHeight(size)
			w,h = DrawText(v.victim)
			slide = slide + math.sin(math.min(1,(timer-v.when)/KILL_FEED_TRANSITION)*math.pi*0.5)
			i = i + 1
		else
			table.remove(gKillFeed,i)
		end
		v = gKillFeed[i]
	end
end
function F_DrawPlayerKills()
	local ms = GetTimer() - gKillStreakTimer
	if ms < KILL_DURATION then
		local shadow = 0.005
		local ar = GetDisplayAspectRatio()
		local x,y,w,h = (0.2-KILL_STREAK_SIZE*0.5)/ar,0.57,KILL_STREAK_SIZE/ar,KILL_STREAK_SIZE
		local gb = 255 * (1 - math.min(1,(gKillStreak-1)/10) * 0.8)
		local alpha = 1
		if ms < KILL_TRANSITION then
			alpha = math.sin((ms/KILL_TRANSITION)*math.pi*0.5)
		elseif ms >= KILL_DURATION - KILL_TRANSITION then
			alpha = math.sin(((KILL_DURATION-ms)/KILL_TRANSITION)*math.pi*0.5)
		end
		DrawTexture(gKillNumbers,x-shadow/ar,y+shadow,w,h,0,0,0,100*alpha)
		DrawTexture(gKillNumbers,x,y,w,h,255,gb,gb,255*alpha)
	else
		gKillStreak = 0
	end
end
function F_DrawKillerName(name,alpha)
	SetTextFont("Arial")
	SetTextBlack()
	SetTextColor(230,230,230,alpha*255)
	SetTextOutline()
	SetTextAlign("C","B")
	SetTextPosition(0.5,0.8)
	SetTextScale(0.9+0.2*alpha)
	DrawText("KILLED BY "..name)
end
function F_DrawPlayerScores(scores)
	local count = table.getn(scores)
	local ar = GetDisplayAspectRatio()
	local size = 0.03
	local margin = 0.01
	local padding = 0.02
	local width = 0.7 / ar
	local height = (size + margin) * count + padding * 2
	local offset = 0.12
	DrawRectangle(0.5-(width*0.5)/ar,offset,width/ar,height,0,0,0,200)
	for i,v in ipairs(scores) do
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(230,230,230,255)
		SetTextAlign("R","T")
		SetTextHeight(size)
		SetTextPosition(0.5+(width*0.5-padding)/ar,offset+padding+(size+margin)*(i-1))
		local w = DrawText("["..v[2].."]")
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(v[4],v[5],v[6],255)
		SetTextAlign("L","T")
		SetTextHeight(size)
		SetTextClipping((width-padding*2)/ar-w)
		SetTextPosition(0.5-(width*0.5-padding)/ar,offset+padding+(size+margin)*(i-1))
		DrawText(v[1])
	end
end
function T_DrawResults()
	local text = CopyTexture(CreateTexture("images/results.png"),"D3DFMT_DXT5")
	local winners = {}
	local colors = {{255,200,50},{200,200,230},{230,120,80},{180,180,180}}
	local sizes = {0.05,0.0425,0.035,0.03}
	local padding = 0.01
	local place,score = 0,-1
	for i,v in ipairs(gScores) do
		if v[2] ~= score then
			place,score = i,v[2]
		end
		winners[i] = {place,v[1],v[2],v[3]}
	end
	if winners[17] then
		for i,v in ipairs(sizes) do
			sizes[i] = v * 0.7
		end
	end
	winners[33] = nil
	while true do
		local ar = GetDisplayAspectRatio()
		local tar = GetTextureAspectRatio(text) / ar
		local size = 0.1
		local width = size * tar
		local y = 0.2
		if winners[17] then
			y = 0.1
		end
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
			DrawText(v[3].." / "..v[4])
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
			if winners[17] then
				y = y + size + 0.003
			else
				y = y + size + 0.005
			end
		end
		Wait(0)
	end
end

-- drawing (weapon)
function T_DrawGun()
	local screen,scope,tw,th
	local gun,png,sgun,spng -- primary and secondary but secondary is actually just the last image cached
	while not gResults do
		local weapon = F_GetWeapon()
		if weapon then
			local decock
			local stats = weapon.stats
			if stats.texture_decock then
				decock = not weapon.cocked
			end
			if stats.scope_size > 0 then
				local nw,nh = GetDisplayResolution()
				local ar = nw / nh
				if tw ~= nw or th ~= nh then
					screen = nil
					screen = CreateRenderTarget(nw,nh)
					scope = nil
					scope = CreateRenderTarget(nw,nh)
					tw,th = nw,nh
				end
			elseif screen then
				screen = nil
				scope = nil
				tw = nil
			end
			if png ~= stats.texture_name then
				local lgun,lpng = gun,png
				png = stats.texture_name
				if png == spng then -- swap primary and secondary
					gun = sgun
					sgun,spng = lgun,lpng
				elseif png ~= "none" then -- move primary to secondary and load new primary
					sgun,spng = lgun,lpng
					gun = CopyTexture(CreateTexture("images/weapons/"..png),"D3DFMT_DXT5")
				else -- move primary to secondary and clear primary
					sgun,spng = lgun,lpng
					gun = nil
				end
			end
			if gEquip > 0 then
				local raise = (gAim-0.5)*2*gEquip
				local scale,rx,ry = F_GetRecoilScale(stats)
				if gAim >= 0.5 then
					if stats.scope_size > 0 then
						local zoom = stats.scope_minimum
						if stats.scope_stages > 1 then
							zoom = zoom + (stats.scope_maximum - stats.scope_minimum) * (F_GetWeapon().scope / (stats.scope_stages - 1))
						end
						F_DrawZoom(screen,scope,gCircle,stats.scope_size,1/zoom,stats.aim_size,raise,scale,rx,ry)
					end
					if gun then
						F_DrawGun(gun,decock,true,stats.aim_size,stats.aim_offset,raise,scale,rx,ry)
					end
					if stats.dot_size > 0 then
						local r,g,b = unpack(stats.dot_color)
						F_DrawDot(r,g,b,stats.dot_size,stats.aim_size,raise,scale,rx,ry)
					end
				elseif gun then
					F_DrawGun(gun,decock,false,stats.hip_size,stats.hip_offset,(1-(gAim*2))*gEquip,scale,rx,ry)
				end
			end
			if dsl.first_person and PICKUP_DRAW_RANGE > 0 then
				F_DrawPickups()
			end
		elseif screen then
			screen = nil
			scope = nil
			tw = nil
		end
		Wait(0)
	end
end
function F_GetRecoilScale(stats)
	local scale = 1
	local rx,ry = 0,0 -- recoil offset
	if gRecoilTimer ~= -1 and stats.recoil_scale ~= 1 then
		local recoil = (GetTimer() - gRecoilTimer) / stats.recoil_time_ms
		if recoil < 1 then
			scale = 1 + math.sin(recoil*math.pi) * (stats.recoil_scale - 1) * gRecoilMult
			if gRecoilOffset > 0 then
				rx,ry = -math.sin(gRecoilAngle)*gRecoilOffset,math.cos(gRecoilAngle)*gRecoilOffset
				if gun then
					rx = rx * stats.recoil_ratio * (1 / GetDisplayAspectRatio())
				end
				if stats.recoil_upwards then
					ry = math.abs(ry)
				end
			end
		end
	end
	return scale,rx,ry
end
function F_ScaleRectangle(x,y,width,height,sx,sy,scale)
	return x-sx*(width*(scale-1)),y-sy*(height*(scale-1)),width*scale,height*scale
end
function F_DrawZoom(screen,scope,circle,size,ratio,height,raise,scale,rx,ry)
	local ar = GetDisplayAspectRatio()
	local x,y,w,h = 0.5-(size*0.5)/ar,(1+(height-0.5))-(raise*height+size*0.5),size/ar,size
	if scale ~= 1 then
		x,y,w,h = F_ScaleRectangle(x,y,w,h,0.5,0.5,scale)
	end
	DrawBackBufferOntoTarget(screen)
	ratio = ratio * size * (1 - (1 - scale) * RECOIL_SCOPE_AMOUNT)
	ClearTarget(scope)
	rx,ry = rx*(scale-1),ry*(1-scale)
	SetTextureBounds(circle,0,0,1,1)
	DrawTextureOntoTarget(scope,circle,0.5-(ratio*0.5)/ar+rx,0.5-ratio*0.5+ry,ratio/ar,ratio,255,255,255,255,0)
	DrawTextureOntoTarget(scope,screen,0,0,1,1,255,255,255,255,2)
	SetTextureBounds(scope,0.5-(ratio*0.5)/ar+rx,0.5-ratio*0.5+ry,0.5+(ratio*0.5)/ar+rx,0.5+ratio*0.5+ry)
	DrawTexture(scope,x+rx,y+ry,w,h,255,255,255,255)
end
function F_DrawGun(gun,decock,ads,height,offset,raise,scale,rx,ry)
	local ar = GetDisplayAspectRatio()
	local tw,th = GetTextureResolution(gun)
	local width = height * (((tw * 0.5) / (decock ~= nil and th * 0.5 or th)) / ar)
	local x,y,w,h = 0.5-width*0.5+offset/ar,1-height*raise,width,height
	if scale ~= 1 then
		x,y,w,h = F_ScaleRectangle(x,y,w,h,0.5-((offset/ar)+rx)/width,((height-0.5)+ry)/height,scale)
	end
	if decock ~= nil then
		local y = 0
		if decock then
			y = 0.5
		end
		if ads then
			SetTextureBounds(gun,0,y,0.5,y+0.5)
		else
			SetTextureBounds(gun,0.5,y,1,y+0.5)
		end
	elseif ads then
		SetTextureBounds(gun,0,0,0.5,1)
	else
		SetTextureBounds(gun,0.5,0,1,1)
	end
	if DEBUG_TRANSPARENT_WEAPON then
		DrawTexture(gun,x,y,w,h,255,255,255,150)
	else
		DrawTexture(gun,x,y,w,h,255,255,255,255)
	end
end
function F_DrawDot(r,g,b,size,height,raise,scale,rx,ry)
	local ar = GetDisplayAspectRatio()
	local x,y,w,h = 0.5-(size*0.5)/GetDisplayAspectRatio(),(1+(height-0.5))-(raise*height+size*0.5),size/GetDisplayAspectRatio(),size
	if scale ~= 1 then
		x,y,w,h = F_ScaleRectangle(x,y,w,h,0.5,0.5,scale)
	end
	DrawRectangle(x+rx*(scale-1),y-ry*(scale-1),w,h,r,g,b,255)
end
function F_DrawPickups()
	local x1,y1,z1 = PlayerGetPosXYZ()
	for ent,pickup in pairs(gPickups) do
		if pickup.draw and IsSyncEntityActive(ent) then
			local x2,y2,z2 = GetSyncEntityPos(ent)
			local dx,dy,dz = x2-x1,y2-y1,z2-z1
			if dx*dx+dy*dy+dz*dz < PICKUP_DRAW_RANGE*PICKUP_DRAW_RANGE then
				local dist = math.sqrt(dx*dx+dy*dy+dz*dz)
				local cx,cy,cz = dsl.first_person.GetDirection()
				local dx,dy,dz = dx/dist-cx,dy/dist-cy,dz/dist-cz
				local angle = math.acos((2-(dx*dx+dy*dy+dz*dz))/2)
				if angle < PICKUP_DRAW_ANGLE then
					local sx,sy = GetScreenCoords(x2,y2,z2)
					if sx then
						local ar = GetDisplayAspectRatio()
						local size = 0.035 * (0.2 + 1.3 * (1 - dist / PICKUP_DRAW_RANGE)) * PICKUP_DRAW_SCALE
						local alpha = (1 - (dist - PICKUP_RANGE) / PICKUP_DRAW_RANGE) * (1 - angle / PICKUP_DRAW_ANGLE)
						if alpha > 1 then
							alpha = 1
						end
						if PICKUP_DRAW_KEY then
							if gPickupBinding ~= 0 then
								DrawTexture(gPickupTexture,sx-(size*0.5)/ar,sy-size*0.5,size/ar,size,255,255,255,255*alpha)
							end
						elseif pickup.icon then
							SetTextureBounds(gIcons,unpack(pickup.icon))
							DrawTexture(gIcons,sx-(size*0.5)/ar,sy-size*0.5,size/ar,size,255,255,255,255*alpha)
						end
					end
				end
			end
		end
	end
end

-- utility
function F_GetPitch(x,y,z)
	local d = math.sqrt(x*x+y*y+z*z)
	if d > 0 then
		return math.asin(z/d)
	end
	return 0
end
function F_PlaySound(sound,bank,x,y,z)
	if dsl.sounds and bank ~= "Hud.bnk" then
		if x then
			dsl.sounds.Play3D(x,y,z,sound,bank)
		else
			dsl.sounds.Play(sound,bank)
		end
	elseif x then
		SoundPlay3D(x,y,z,sound,bank)
	else
		SoundPlay2D(sound,bank)
	end
end
function F_GetRatPosition(ped)
	local x,y,z = PedGetPosXYZ(ped)
	return x,y,z+0.09*RAT_REAL_SCALE
end
function F_GetIconUV(index)
	local w,h = GetTextureResolution(gIcons)
	local columns = math.floor(w/ICON_RES)
	local rows = math.floor(h/ICON_RES)
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
function F_GetButtonTexture(name)
	return ({
		[0] = "arrow_up",
		[1] = "arrow_down",
		[2] = "arrow_left",
		[3] = "arrow_right",
		[4] = "Button_start",
		[5] = "Button_select",
		[6] = "Analog_L3",
		[7] = "Analog_R3",
		[8] = "Button_L1",
		[9] = "Button_R1",
		[10] = "Button_L2",
		[11] = "Button_R2",
		[12] = "HUD_buttonCross",
		[13] = "HUD_buttonCircle",
		[14] = "HUD_ButtonSquare",
		[15] = "HUD_ButtonTriangle",
	})[name]
end
function F_DrawRounded(circle,size,x,y,w,h,r,g,b,a)
	local ar = GetDisplayAspectRatio()
	DrawRectangle(x+size/ar,y,w-(size*2)/ar,size,r,g,b,a) -- top (cut corners)
	DrawRectangle(x,y+size,w,h-size*2,r,g,b,a) -- center (full width)
	DrawRectangle(x+size/ar,y+h-size,w-(size*2)/ar,size,r,g,b,a) -- bottom (cut corners)
	SetTextureBounds(circle,0,0,0.5,0.5)
	DrawTexture(circle,x,y,size/ar,size,r,g,b,a) -- top left
	SetTextureBounds(circle,0.5,0,1,0.5)
	DrawTexture(circle,x+w-size/ar,y,size/ar,size,r,g,b,a) -- top right
	SetTextureBounds(circle,0,0.5,0.5,1)
	DrawTexture(circle,x,y+h-size,size/ar,size,r,g,b,a) -- bottom left
	SetTextureBounds(circle,0.5,0.5,1,1)
	DrawTexture(circle,x+w-size/ar,y+h-size,size/ar,size,r,g,b,a) -- bottom right
end
function F_DrawRounded_2(circle,size,x,y,w,h,r,g,b,a)
	local ar = GetDisplayAspectRatio()
	DrawRectangle(x+size/ar,y,w-(size*2)/ar,size,r,g,b,a) -- top (cut corners)
	DrawRectangle(x+size/ar,y+h-size,w-(size*2)/ar,size,r,g,b,a) -- bottom (cut corners)
	DrawRectangle(x,y+size,size/ar,h-size*2,r,g,b,a) -- left
	DrawRectangle(x+w-size/ar,y+size,size/ar,h-size*2,r,g,b,a) -- right
	SetTextureBounds(circle,0,0,0.5,0.5)
	DrawTexture(circle,x,y,size/ar,size,r,g,b,a) -- top left
	SetTextureBounds(circle,0.5,0,1,0.5)
	DrawTexture(circle,x+w-size/ar,y,size/ar,size,r,g,b,a) -- top right
	SetTextureBounds(circle,0,0.5,0.5,1)
	DrawTexture(circle,x,y+h-size,size/ar,size,r,g,b,a) -- bottom left
	SetTextureBounds(circle,0.5,0.5,1,1)
	DrawTexture(circle,x+w-size/ar,y+h-size,size/ar,size,r,g,b,a) -- bottom right
end
function F_HSVA(h,s,v,a)
	local c = v * s
	local m = v - c
	local x = c * (1 - math.abs(math.mod(h/60,2)-1))
	if h < 60 then
		h,s,v = c,x,0
	elseif h < 120 then
		h,s,v = x,c,0
	elseif h < 180 then
		h,s,v = 0,c,x
	elseif h < 240 then
		h,s,v = 0,x,c
	elseif h < 300 then
		h,s,v = x,0,c
	else
		h,s,v = c,0,x
	end
	return math.floor((h+m)*255),math.floor((s+m)*255),math.floor((v+m)*255),math.floor(a*255)
end
