LoadScript("weapons.lua")
LoadScript("pickups.lua")
LoadScript("blips.lua")
LoadScript("maps.lua")

PAYOUT_MINIMUM_COUNT = 2 -- must be at least this many players
PAYOUT_REWARD_RATIO = 0.55 -- how much of the scoreboard gets paid (always at least 1st place though)
PAYOUT_MAX_CENTS = 2000
PAYOUT_COUNT_MAXIMUM = 12 -- how many players to get the full payment
PAYOUT_COUNT_FACTOR = 0.75 -- how much of the price gets reduced by having under maximum players
PAYOUT_PLACE_FACTOR = 0.72 -- how much of the price gets reduced by player placement
PAYOUT_BONUS_MULT = 0.12 -- maximum random bonus multiplier
PAYOUT_KILL_COUNT_1 = 30 -- if score >= this
PAYOUT_KILL_BONUS_1 = 1.15 -- multiply pay
PAYOUT_KILL_COUNT_2 = 50 -- if score >= this
PAYOUT_KILL_BONUS_2 = 1.35 -- multiply pay

TEST_MODE = false -- don't re-position on start unless needed, allow solo ready
TEST_PAYMENT = false
INFINITE_TIMER = false
START_ASAP = false -- immediately put everyone into rat wars
ADD_BOTS = 0

INVULNERABLE_TIMER = 1000 -- time any player is invulnerable after spawning
BOT_RESPAWN_TIMER = 2000

PICKUP_LOOT = 3 -- maximum pickups for player loot
PICKUP_STAGE = 9 -- maximum pickups for the map
PICKUP_TIMER = 8000
PICKUP_RANGE = 5 -- should be bigger than client value to account for latency

MAX_HEALTH = 100
SPAWN_SHIELD_RADIUS = 17
ADRENALINE_TIME = 30000
ADRENALINE_KILL = 0

SHOW_STREAK_COUNT = 5 -- how big of a streak to start showing it
GIANT_RAT_STREAK = 10 -- how big of a streak to become the giant rat

READY_MINIMUM_PLAYERS = 2
READY_COUNTDOWN_MS = 30000
READY_LOAD_TIME_MS = 1000

PLAY_RANGE = 10 -- for joining from the blip (just to make sure the player isn't a grossly different spot)
MATCH_TIME = 600000 + 15000 -- match time plus intro time
RESULTS_TIME = 15000

-- global stats
gStats = LoadTable("stats.bin")

-- also see F_StartGame for a list of other globals that are active while in a game.
-- also see F_JoinLobby for lobby specific
gReady = {} -- players that initialized their script (false for normal, true for admin).
gLobby = {} -- players in the lobby. anyone in gPlayers is also in gLobby.
gPlayers = {} -- in a current game. game is inactive if table is empty.

gRespawning = {} -- [ped] = timer
gBots = {} -- [ped] = {...}
gPickups = {}

gReadyCountdown = -1 -- if not -1, gReadyStarted and gReadyThread will be set
gPeakPlayers = 0

gPayoutMultiplier = 1

-- cleanup events
RegisterLocalEventHandler("sync:DeleteEntity",function(ent)
	gPickups[ent] = nil
end)
RegisterLocalEventHandler("sync:DeletePed",function(ped)
	gRespawning[ped] = nil
	gBots[ped] = nil
end)
RegisterLocalEventHandler("PlayerDropped",function(player)
	gReady[player] = nil
	if gLobby[player] then
		F_LeaveLobby(player,false)
	end
	if gPlayers[player] then
		F_LeaveGame(player)
	end
end)
RegisterLocalEventHandler("ScriptShutdown",function(s)
	if next(gPlayers) and s == GetCurrentScript() then
		F_SaveStats()
	end
end)
RegisterLocalEventHandler("ServerShutdown",function()
	if next(gPlayers) then
		F_SaveStats()
	end
end)

-- disable model switch
RegisterLocalEventHandler("models:SwitchModel",function(player)
	if gPlayers[player] then
		--SetSyncEntityModel(GetSyncPlayerPed(player),136)
		return true
	end
end)

-- spawner events
RegisterLocalEventHandler("spawner:Respawning",function(player,f_set)
	if gPlayers[player] then
		f_set(F_GetSpawn())
	end
end)
RegisterLocalEventHandler("spawner:Respawned",function(player)
	if gPlayers[player] then
		F_SpawnPlayer(player,GetSyncPlayerPed(player))
	end
end)

-- disable psync
RegisterLocalEventHandler("psync:SyncProjectile",function(player)
	-- rat projectiles aren't owned by the player but just to be extra safe...
	return gPlayers[player]
end)

-- network events (lobby)
RegisterNetworkEventHandler("rat_wars:InitScript",function(player)
	if gReady[player] == nil then
		gReady[player] = DoesPlayerHaveRole(player,"admin")
		if gReady[player] then
			SendNetworkEvent(player,"rat_wars:SetAdmin")
		end
		if START_ASAP and F_JoinActivity(player) then
			F_JoinLobby(player)
			if next(gPlayers) then
				F_JoinLate(player)
			else
				F_StartGame(player)
			end
			SendNetworkEvent(player,"rat_wars:SkipIntro")
		else
			F_UpdatePlayerCount(player)
		end
	end
end)
RegisterNetworkEventHandler("rat_wars:StartGame",function(player,blip)
	if not gLobby[player] and gReady[player] ~= nil then
		blip = gBlips[blip]
		if (gReady[player] or (blip and F_IsNear(GetSyncPlayerPed(player),unpack(blip)))) and F_JoinActivity(player) then
			F_JoinLobby(player,blip)
			if next(gPlayers) then
				F_JoinLate(player) -- game active, join it
				SendNetworkEvent(player,"rat_wars:FinishLoading",gMap.area)
			else
				SendNetworkEvent(player,"rat_wars:SetLobby",gLobby[player].class)
				F_UpdateLobbyPlayers(player)
				F_UpdateLobbyReady(player)
				F_UpdateLobbyMaps(player)
				SendNetworkEvent(player,"rat_wars:FinishLoading")
			end
		else
			SendNetworkEvent(player,"rat_wars:FinishLoading") -- no arg means exit loading screen asap
		end
	end
end)
RegisterNetworkEventHandler("rat_wars:ReadyUp",function(player,ready)
	local data = gLobby[player]
	if data and not next(gPlayers) and data.ready ~= (ready ~= nil) then
		for other in pairs(gLobby) do
			if ready then
				SendNetworkEvent(other,"rat_wars:PlayerReady",GetPlayerId(player),true)
			else
				SendNetworkEvent(other,"rat_wars:PlayerReady",GetPlayerId(player))
			end
		end
		data.ready = (ready ~= nil)
		F_UpdateLobbyReady()
	end
end)
RegisterNetworkEventHandler("rat_wars:ChangeClass",function(player,class)
	if gLobby[player] and not next(gPlayers) then
		for _,v in ipairs({"RAT","JUNKIE","SPEEDY","FAT","FOCUSED","BLOODTHIRSTY"}) do
			if v == class then
				F_SetRatClass(player,class)
				return
			end
		end
	end
end)
RegisterNetworkEventHandler("rat_wars:VoteMap",function(player,index)
	if gLobby[player] and not next(gPlayers) then
		local map = gVoteMaps[index]
		if map and not map.voters[player] then
			for _,v in ipairs(gVoteMaps) do
				if v.voters[player] then
					v.voters[player] = nil
					v.votes = v.votes - 1
				end
			end
			map.voters[player] = true
			map.votes = map.votes + 1
			F_UpdateLobbyMaps()
		end
	end
end)
RegisterNetworkEventHandler("rat_wars:LeaveLobby",function(player)
	if gLobby[player] and not next(gPlayers) then
		F_LeaveLobby(player,true)
		SendNetworkEvent(player,"rat_wars:SetLobby")
	end
end)

-- network events (gameplay)
RegisterNetworkEventHandler("rat_wars:PickupStuff",function(player,pickup)
	local data = gPickups[pickup]
	if data and gPlayers[player] then
		local ped = GetSyncPlayerPed(player)
		local x1,y1,z1 = GetSyncEntityPos(pickup)
		local x2,y2,z2 = GetSyncEntityPos(ped)
		local dx,dy,dz = x2-x1,y2-y1,z2-z1
		if not PedIsDead(ped) and dx*dx+dy*dy+dz*dz < PICKUP_RANGE*PICKUP_RANGE then
			local ptype = data.powerup
			if not ptype then
				data.pickup = nil
				data.dropped = nil
				F_SetPlayerWeapon(player,false,data.id,data)
			elseif ptype == "health" then
				PedSetHealth(ped,math.min(PedGetMaxHealth(ped),PedGetHealth(ped)+MAX_HEALTH))
			elseif ptype == "adrenaline" then
				local data = gPlayers[player]
				local ms = ADRENALINE_TIME
				if data.class == "JUNKIE" then
					ms = ms * 3 -- JUNKIE: 3x adrenaline time
				end
				if data.adrenaline then
					data.adrenaline_duration = data.adrenaline_duration + ms
				else
					data.adrenaline = GetAccurateTimer()
					data.adrenaline_duration = ms
				end
				SendNetworkEvent(player,"rat_wars:SetAdrenaline",true)
			end
			SendNetworkEvent(player,"rat_wars:PickupSound",ptype)
			for peer in pairs(gPlayers) do
				if peer ~= player then
					SendNetworkEvent(peer,"rat_wars:PickupSound",ptype,x1,y1,z1)
				end
			end
			DeleteSyncEntity(pickup)
			gPickups[pickup] = nil
		else
			SendNetworkEvent(player,"rat_wars:RejectPickup",pickup)
		end
	end
end)
RegisterNetworkEventHandler("rat_wars:SwitchWeapon",function(player,id)
	local data = gPlayers[player]
	if data then
		if (data.primary and data.primary.id) == id then
			local switch = data.secondary
			if switch then
				local state = {}
				for k,v in pairs(switch) do
					state[k] = v
				end
				state.id = nil
				state.stats = nil
				SendNetworkEvent(player,"rat_wars:SetWeapon",switch.id,state)
				data.secondary = data.primary
				data.primary = switch
			end
		end
		SendNetworkEvent(player,"rat_wars:AllowSwitch")
	end
end)
RegisterNetworkEventHandler("rat_wars:ReloadWeapon",function(player,id,mag,top)
	local data = gPlayers[player]
	if data and data.primary and data.primary.id == id then
		local weapon = data.primary
		if mag then
			weapon.ammo = weapon.stats.magazine_size -- reload magazine
			if not weapon.chamber and not weapon.stats.open_bolt then
				if not top or not weapon.stats.bolt_action or weapon.ammo == 0 then
					weapon.ammo = weapon.ammo - 1
				end
				weapon.chamber = true
			end
			weapon.cocked = true
		elseif not weapon.chamber and not weapon.stats.open_bolt then
			weapon.ammo = weapon.ammo - 1 -- just re-chamber closed bolt
			weapon.chamber = true
			weapon.cocked = true
		end
		F_UpdatePlayerWeapon(player)
	end
end)
RegisterNetworkEventHandler("rat_wars:ReloadSound",function(player,mag)
	if gPlayers[player] then
		local ped = GetSyncPlayerPed(player)
		for peer in pairs(gPlayers) do
			if peer ~= player then
				if mag then
					SendNetworkEvent(peer,"rat_wars:ReloadSound",ped,true)
				else
					SendNetworkEvent(peer,"rat_wars:ReloadSound",ped)
				end
			end
		end
	end
end)
RegisterNetworkEventHandler("rat_wars:DecockWeapon",function(player,id)
	local data = gPlayers[player]
	if data and data.primary and data.primary.id == id then
		local ped = GetSyncPlayerPed(player)
		for peer in pairs(gPlayers) do
			if peer ~= player then
				SendNetworkEvent(peer,"rat_wars:DrySound",ped)
			end
		end
		data.primary.cocked = false
		F_UpdatePlayerWeapon(player)
	end
end)
RegisterNetworkEventHandler("rat_wars:SelectFireMode",function(player,id,semi)
	local data = gPlayers[player]
	if data and data.primary and data.primary.id == id then
		data.primary.semi = semi ~= nil
		F_UpdatePlayerWeapon(player)
	end
end)
RegisterNetworkEventHandler("rat_wars:SetScopeStage",function(player,id,stage)
	local data = gPlayers[player]
	if data and data.primary and data.primary.id == id then
		if type(stage) == "number" and stage >= 0 and stage < data.primary.stats.scope_stages then
			data.primary.scope = stage
		end
		F_UpdatePlayerWeapon(player)
	end
end)
RegisterNetworkEventHandler("rat_wars:ShootWeapon",function(player,id,px,py,pz,dx,dy,dz)
	local data = gPlayers[player]
	if data and data.primary and data.primary.id == id and F_CheckNumbers(px,py,pz,dx,dy,dz) then
		local weapon = data.primary
		if weapon.cocked and (weapon.chamber or (weapon.stats.open_bolt and weapon.ammo > 0)) then
			local ped = GetSyncPlayerPed(player)
			local power = weapon.stats.projectile_power
			local dist = math.sqrt(dx*dx+dy*dy+dz*dz)
			dx,dy,dz = (dx/dist)*power,(dy/dist)*power,(dz/dist)*power
			for peer in pairs(gPlayers) do
				if peer ~= player then
					SendNetworkEvent(peer,"rat_wars:ShootProjectile",ped,id,px,py,pz,dx,dy,dz)
				end
			end
			if weapon.stats.bolt_action then
				weapon.chamber = false
				weapon.cocked = false
			elseif weapon.ammo > 0 then
				weapon.ammo = weapon.ammo - 1
			else
				weapon.chamber = false
			end
			F_UpdatePlayerWeapon(player)
			F_LogShotStat(id)
		end
	end
end)
RegisterNetworkEventHandler("rat_wars:HitPlayer",function(player,victim,damage,weapon)
	local data = gPlayers[player]
	if data and IsSyncPedValid(victim) and (gBots[victim] or gPlayers[GetSyncPlayerFromPed(victim)]) and not gRespawning[victim] and not gGameOver then
		local id,stats
		if data.primary then -- was it primary?
			stats = data.primary.stats
			if stats.projectile_id == weapon and stats.projectile_damage == damage then
				id = data.primary.id
			else
				stats = nil
			end
		end
		if not stats and data.secondary then -- was it secondary?
			stats = data.secondary.stats
			if stats.projectile_id == weapon and stats.projectile_damage == damage then
				id = data.secondary.id
			else
				stats = nil
			end
		end
		if not stats then -- could it have been anything?
			for i,v in pairs(gWeapons) do
				if v.projectile_id == weapon and v.projectile_damage == damage then
					id,stats = i,v
					break
				end
			end
		end
		if stats then
			local hp = PedGetHealth(victim) - damage
			if hp > 0 then
				SendNetworkEvent(player,"rat_wars:HitMarker",victim)
				PedSetHealth(victim,hp)
			elseif not PedIsDead(victim) then
				local adrenaline = data.adrenaline ~= nil
				local ped = GetSyncPlayerPed(player)
				local vp = GetSyncPlayerFromPed(victim)
				local vname = vp and GetPlayerName(vp)
				local name = GetPlayerName(player)
				local c1,c2 = 0,0
				if dsl.role_colors then
					c1 = dsl.role_colors.GetColorIndex(player)
					if vp then
						c2 = dsl.role_colors.GetColorIndex(vp)
					end
				end
				data.score = data.score + 1
				data.streak = data.streak + 1
				if vp then
					F_KillPlayer(vp,true)
					SendNetworkEvent(vp,"rat_wars:KilledBy",ped,name)
				end
				if not PedIsDead(ped) and data.streak == GIANT_RAT_STREAK then
					PedSetHealth(ped,PedGetMaxHealth(ped))
				end
				for player in pairs(gPlayers) do
					if data.streak == GIANT_RAT_STREAK then
						SendNetworkEvent(player,"rat_wars:GiantRat",ped,true)
					end
					if vp then
						SendNetworkEvent(player,"rat_wars:KillFeed",name,c1,stats.icon_index,adrenaline,vname,c2)
					else
						SendNetworkEvent(player,"rat_wars:KillFeed",name,c1,stats.icon_index,adrenaline,"Rat",0)
					end
				end
				if data.streak >= SHOW_STREAK_COUNT then
					SendNetworkEvent(player,"rat_wars:KillStreak",data.streak)
				end
				F_UpdatePlayerScores()
				if adrenaline then
					data.adrenaline_duration = data.adrenaline_duration + ADRENALINE_KILL
				end
				gRespawning[victim] = GetAccurateTimer()
				SendNetworkEvent(player,"rat_wars:HitMarker",victim,true)
				if not PedIsDead(ped) and data.class == "BLOODTHIRSTY" then
					PedSetHealth(ped,math.min(PedGetMaxHealth(ped),PedGetHealth(ped)+15))
				end
				PedSetDead(victim,true)
				PedSetHealth(victim,0)
				data = gLobby[player]
				if data.account then
					data.account.kills = data.account.kills + 1
					data.save = true
				end
				F_LogKillStat(id)
			end
		end
	end
end)

-- network events (admin)
RegisterNetworkEventHandler("rat_wars:WarpBlip",function(player)
	if gReady[player] and not gPlayers[player] then
		local blip = gBlips[math.random(table.getn(gBlips))]
		SetSyncEntityPos(GetSyncPlayerPed(player),blip[1],blip[2],blip[3])
	end
end)
RegisterNetworkEventHandler("rat_wars:RequestStats",function(player)
	if gReady[player] then
		SendNetworkEvent(player,"rat_wars:PrintStats",gStats)
	end
end)
RegisterNetworkEventHandler("rat_wars:FinishGame",function(player)
	if gReady[player] and next(gPlayers) then
		TerminateThread(gThread)
		F_Cleanup()
	end
end)
RegisterNetworkEventHandler("rat_wars:SetWeapon",function(player,id)
	if gReady[player] and gPlayers[player] then
		if gWeapons[id] then
			F_SetPlayerWeapon(player,false,id)
		else
			F_SetPlayerWeapon(player,false,nil)
		end
	end
end)

-- rat class
function F_SetRatClass(player,class)
	local pd = gPlayers[player]
	local ld = gLobby[player]
	SendNetworkEvent(player,"rat_wars:SetClass",class)
	if pd then
		F_UpdateRatClass(player)
		pd.class = class
	end
	if ld.account then
		ld.account.class = class
		ld.save = true
	end
	ld.class = class
end
function F_UpdateRatClass(player)
	if gPlayers[player] then
		local ped = GetSyncPlayerPed(player)
		local class = gPlayers[player].class
		local maxhp = PedGetMaxHealth(ped)
		local ratio = PedGetHealth(ped) / maxhp
		if class == "SPEEDY" then
			maxhp = maxhp - 20 -- SPEEDY: -20 hp
		elseif class == "FAT" then
			maxhp = maxhp + 25 -- FAT: +25 hp
		elseif class == "BLOODTHIRSTY" then
			maxhp = maxhp - 10 -- BLOODTHIRSTY: -10 hp
		end
		PedSetMaxHealth(ped,maxhp)
		PedSetHealth(ped,math.floor(maxhp*ratio))
	end
end

-- network utility
function F_IsNear(ped,x1,y1,z1,a1)
	if GetSyncEntityArea(ped) == a1 then
		local x2,y2,z2 = GetSyncEntityPos(ped)
		local dx,dy,dz = x2-x1,y2-y1,z2-z1
		return dx*dx+dy*dy+dz*dz < PLAY_RANGE*PLAY_RANGE
	end
	return false
end
function F_CheckNumbers(...)
	for _,x in ipairs(arg) do
		if type(x) ~= "number" or not (x >= -1 / 0 and x <= 1 / 0) then
			return false
		end
	end
	return true
end

-- fun stats
function F_SaveStats()
	local status,message = pcall(SaveTable,"stats.bin",gStats)
	if not status then
		PrintWarning("failed to save stats.bin ("..message..")")
	end
end
function F_LogShotStat(id)
	local w = gStats[id]
	if w then
		w.shots = w.shots + 1
	else
		gStats[id] = {shots = 1,kills = 0}
	end
end
function F_LogKillStat(id)
	local w = gStats[id]
	if w then
		w.kills = w.kills + 1
	else
		gStats[id] = {shots = 0,kills = 1}
	end
end

-- lobby controller
function F_JoinLobby(player,blip)
	local ped = GetSyncPlayerPed(player)
	local account = GetPlayerAccountTable(player,"rat_wars")
	local class = "RAT"
	if account then
		if type(account.class) == "string" then
			class = account.class
		end
		account.kills = tonumber(account.kills) or 0
	end
	if not next(gLobby) then
		gDimension = CreateSyncDimension("rat_wars")
		SetSyncActiveDimension(gDimension)
		F_SetupVoteMaps()
	end
	SetSyncEntityDimension(ped,gDimension)
	gLobby[player] = {
		ready = false, -- if the player is ready to play
		account = account,
		class = class,
		save = false, -- set if anything in account changed and should be saved eventually
		blip = blip,
		model = GetSyncEntityModel(ped),
		maxhp = PedGetMaxHealth(ped),
		hp = PedGetHealth(ped)
	}
	F_UpdatePlayerCount()
end
function F_LeaveLobby(player,playing)
	local data = gLobby[player]
	if data then
		if playing then
			local ped = GetSyncPlayerPed(player)
			local b = data.blip
			if b then
				local x = b.x[1] + ((b.x[2] - b.x[1]) * math.random())
				local y = b.y[1] + ((b.y[2] - b.y[1]) * math.random())
				local h = math.pi * 2 * math.random()
				SetSyncEntityPos(ped,x,y,b.z,h)
			end
			SetSyncEntityDimension(ped,GetSyncMainDimension())
			if dsl.models then
				dsl.models.RestoreModel(player)
			else
				SetSyncEntityModel(ped,data.model)
			end
			PedSetMaxHealth(ped,data.maxhp)
			PedSetHealth(ped,data.hp)
		end
		for _,v in ipairs(gVoteMaps) do
			if v.voters[player] then
				v.voters[player] = nil
				v.votes = v.votes - 1
			end
		end
		gLobby[player] = nil
		for other in pairs(gLobby) do
			SendNetworkEvent(other,"rat_wars:PlayerList",GetPlayerId(player))
		end
		F_UpdatePlayerCount()
		F_UpdateLobbyReady()
		F_UpdateLobbyMaps()
		if not next(gLobby) then
			if gReadyCountdown ~= -1 then
				TerminateThread(gReadyThread)
				gReadyCountdown = -1
				gReadyStarted = nil
				gReadyThread = nil
			end
			DeleteSyncDimension(gDimension)
			gDimension = nil
			gVoteMaps = nil
		end
		F_LeaveActivity(player)
	end
end
function F_SetupVoteMaps()
	local maps = {}
	for name in pairs(gMaps) do
		table.insert(maps,name)
	end
	gVoteMaps = {}
	for i = 1,2 do
		gVoteMaps[i] = {
			name = table.remove(maps,math.random(table.getn(maps))),
			voters = {},
			votes = 0,
		}
	end
end
function F_UpdateLobbyPlayers(player)
	-- only call for a specific player after they just joined and the game isn't active
	-- only call for all players after a game ended and players just started their lobby scripts
	if player then
		local data = gLobby[player]
		local index,kills = 0,0
		if dsl.role_colors then
			index = dsl.role_colors.GetColorIndex(player)
		end
		if data.account then
			kills = data.account.kills
		end
		for other,data in pairs(gLobby) do
			if other ~= player then
				local kills = 0
				if data.account then
					kills = data.account.kills
				end
				SendNetworkEvent(player,"rat_wars:PlayerList",GetPlayerId(other),GetPlayerName(other),dsl.role_colors.GetColorIndex(other),kills)
			end
			SendNetworkEvent(other,"rat_wars:PlayerList",GetPlayerId(player),GetPlayerName(player),index,kills)
		end
	else
		for player,data in pairs(gLobby) do
			local index,kills = 0,0
			if dsl.role_colors then
				index = dsl.role_colors.GetColorIndex(player)
			end
			if data.account then
				kills = data.account.kills
			end
			for other in pairs(gLobby) do
				SendNetworkEvent(other,"rat_wars:PlayerList",GetPlayerId(player),GetPlayerName(player),index,kills)
			end
		end
	end
end
function F_UpdateLobbyReady(player)
	local count,total = 0,0
	for _,v in pairs(gLobby) do
		if v.ready then
			count = count + 1
		end
		total = total + 1
	end
	if player then
		if gReadyCountdown ~= -1 then
			local passed = GetSyncTimer() - gReadyStarted
			if passed < gReadyCountdown then
				SendNetworkEvent(player,"rat_wars:ReadyTimer",gReadyCountdown-passed)
			else
				SendNetworkEvent(player,"rat_wars:ReadyTimer",0)
			end
		end
	elseif count == 0 then -- nobody is ready abort countdown
		if gReadyCountdown ~= -1 then
			for player in pairs(gLobby) do
				SendNetworkEvent(player,"rat_wars:ReadyTimer")
			end
			TerminateThread(gReadyThread)
			gReadyCountdown = -1
			gReadyStarted = nil
			gReadyThread = nil
		end
	elseif not next(gPlayers) and (TEST_MODE or total >= READY_MINIMUM_PLAYERS) then
		if count == total then -- all players ready - start asap
			if gReadyCountdown == -1 then
				gReadyStarted = GetSyncTimer()
				gReadyThread = CreateThread("T_ReadyTimer")
				for player in pairs(gLobby) do
					SendNetworkEvent(player,"rat_wars:ReadyTimer",0)
				end
			end
			gReadyCountdown = 0
		elseif gReadyCountdown == -1 then -- at least someone is ready - start countdown
			gReadyCountdown = READY_COUNTDOWN_MS
			gReadyStarted = GetSyncTimer()
			gReadyThread = CreateThread("T_ReadyTimer")
			for player in pairs(gLobby) do
				SendNetworkEvent(player,"rat_wars:ReadyTimer",gReadyCountdown)
			end
		end
	end
end
function F_UpdateLobbyMaps(player)
	local maps = {}
	for i,v in ipairs(gVoteMaps) do
		maps[i] = {gMaps[v.name].index,v.votes}
	end
	if player then
		SendNetworkEvent(player,"rat_wars:VoteMaps",maps)
	else
		for player in pairs(gLobby) do
			SendNetworkEvent(player,"rat_wars:VoteMaps",maps)
		end
	end
end

-- ready timer
function T_ReadyTimer()
	local when
	while true do
		if GetSyncTimer() - gReadyStarted >= gReadyCountdown then
			if not when then
				for player in pairs(gLobby) do
					SendNetworkEvent(player,"rat_wars:StartLoading")
				end
				when = GetAccurateTimer()
			elseif GetAccurateTimer() - when >= READY_LOAD_TIME_MS then
				local started = false
				for player in pairs(gLobby) do
					if started then
						F_JoinLate(player)
					else
						F_StartGame(player)
						started = true
					end
					SendNetworkEvent(player,"rat_wars:FinishLoading",gMap.area)
				end
				when = nil -- thread is gonna terminate soon anyway
			end
		end
		Wait(0)
	end
end

-- rat wars controller
function F_CreatePlayer(player,ped)
	return {
		-- .primary and .secondary can also be set
		class = gLobby[player].class,
		score = 0, -- kill count
		deaths = 0,
		streak = 0,
		save = false, -- a player account flush is needed
		pay = 0, -- used later on to send payment result
	}
end
function F_StartGame(player)
	local maps = {}
	local highest = 0
	for _,v in ipairs(gVoteMaps) do
		highest = math.max(highest,v.votes)
	end
	for _,v in ipairs(gVoteMaps) do
		if v.votes == highest then
			table.insert(maps,v.name)
		end
	end
	if TEST_MODE then
		gMapId = "warehouse"
	else
		gMapId = maps[math.random(table.getn(maps))]
	end
	if gReadyCountdown ~= -1 then
		TerminateThread(gReadyThread)
		gReadyCountdown = -1
		gReadyStarted = nil
		gReadyThread = nil
	end
	gMap = gMaps[gMapId]
	gThread = CreateThread("T_RatWars")
	gPickups = {} -- [entity] = weapon
	gPickupTimer = GetAccurateTimer()
	gStarted = GetSyncTimer()
	gStarting = true
	gGameOver = false
	if gMap.weather then
		WeatherSet(gMap.weather)
	else
		dsl["sync+"].InheritWeather()
	end
	if gMap.chapter then
		ChapterSet(gMap.chapter)
	else
		dsl["sync+"].InheritChapter()
	end
	if gMap.clock then
		ClockSet(unpack(gMap.clock))
		ClockSetTickRate(10)
	else
		dsl["sync+"].InheritClock()
	end
	if gMap.objects and dsl.object_spawner then
		for _,set in ipairs(gMap.objects) do
			dsl.object_spawner.Activate(set)
		end
	end
	SendNetworkEvent(player,"rat_wars:SetPlaying",MATCH_TIME,F_Time(),gMapId)
	SendNetworkEvent(player,"rat_wars:SetClass",gLobby[player].class)
	gPlayers[player] = F_CreatePlayer(player,GetSyncPlayerPed(player))
	gPeakPlayers = 1
	F_UpdatePlayerScores()
end
function F_JoinLate(player)
	local count = 0
	local ped = GetSyncPlayerPed(player)
	SendNetworkEvent(player,"rat_wars:SetPlaying",MATCH_TIME,F_Time(),gMapId)
	SendNetworkEvent(player,"rat_wars:SetClass",gLobby[player].class)
	for peer in pairs(gPlayers) do
		SendNetworkEvent(player,"rat_wars:AddPlayer",GetSyncPlayerPed(peer))
		SendNetworkEvent(peer,"rat_wars:AddPlayer",ped)
	end
	for rat in pairs(gBots) do
		SendNetworkEvent(player,"rat_wars:AddPlayer",rat)
	end
	for pickup,data in pairs(gPickups) do
		if not data.powerup then
			SendNetworkEvent(player,"rat_wars:SpawnPickup",pickup,data.stats.icon_index)
		else
			SendNetworkEvent(player,"rat_wars:SpawnPickup",pickup)
		end
	end
	gPlayers[player] = F_CreatePlayer(player,ped)
	count = 0
	for _ in pairs(gPlayers) do
		count = count + 1
	end
	if count > gPeakPlayers then
		gPeakPlayers = count
	end
	F_UpdatePlayerScores()
	if not gStarting then
		F_InitPlayer(player,ped)
	end
end
function F_LeaveGame(player)
	gPlayers[player] = nil
	if next(gPlayers) then
		F_UpdatePlayerScores()
	else
		TerminateThread(gThread)
		F_Cleanup()
	end
end
function F_UpdatePlayerCount(player)
	local count = 0
	for _ in pairs(gLobby) do
		count = count + 1
	end
	if player then
		SendNetworkEvent(player,"rat_wars:UpdateOnline",count)
	else
		for player in pairs(gReady) do
			SendNetworkEvent(player,"rat_wars:UpdateOnline",count)
		end
	end
end
function F_UpdatePlayerScores(player)
	local scores = {}
	if dsl.role_colors then
		for player,data in pairs(gPlayers) do
			local name = GetPlayerName(player) -- kinda lazy patch for now since swegta.com doesn't allow duplicate usernames anyway
			if not scores[name] or data.score > scores[name][1] then
				scores[name] = {data.score,data.deaths,dsl.role_colors.GetColorIndex(player)}
			end
		end
	else
		for player,data in pairs(gPlayers) do
			local name = GetPlayerName(player)
			if not scores[name] or data.score > scores[name][1] then
				scores[GetPlayerName(player)] = {data.score,data.deaths,0}
			end
		end
	end
	if player then
		SendNetworkEvent(player,"rat_wars:UpdateScores",scores)
	else
		for player in pairs(gPlayers) do
			SendNetworkEvent(player,"rat_wars:UpdateScores",scores)
		end
	end
end

-- main rat thread
function T_RatWars()
	gStarting = false -- signals late joining players they'll need to init
	for player in pairs(gPlayers) do
		F_InitPlayer(player,GetSyncPlayerPed(player))
	end
	for i = 1,ADD_BOTS do
		local rat = CreateSyncPed(136)
		for player in pairs(gPlayers) do
			SendNetworkEvent(player,"rat_wars:AddPlayer",rat)
		end
		gBots[rat] = {}
		F_InitPlayer(nil,rat)
	end
	while next(gPlayers) and F_Time() > 0 do
		F_UpdateRespawns()
		F_RespawnBots()
		F_UpdatePickups()
		F_UpdateAdrenaline()
		Wait(0)
	end
	F_PayRewards(gPeakPlayers)
	gGameOver = true
	for player,data in pairs(gPlayers) do
		SendNetworkEvent(player,"rat_wars:DisplayResults",data.pay)
	end
	Wait(RESULTS_TIME)
	F_Cleanup()
end
function F_Cleanup()
	local count = 0
	F_SaveStats()
	for player in pairs(gPlayers) do
		local data = gLobby[player]
		if data.save then
			if not SavePlayerAccountTable(player) then
				PrintWarning("failed to save player stats")
			end
			data.save = false
		end
		SendNetworkEvent(player,"rat_wars:SetLobby",data.class)
		gPlayers[player] = nil
	end
	for _,data in pairs(gLobby) do
		data.ready = false
		count = count + 1
	end
	F_SetupVoteMaps()
	F_UpdateLobbyPlayers()
	F_UpdateLobbyReady()
	F_UpdateLobbyMaps()
	for player in pairs(gReady) do
		SendNetworkEvent(player,"rat_wars:UpdateOnline",count)
	end
	for rat in pairs(gBots) do
		DeleteSyncEntity(rat)
		gBots[rat] = nil
	end
	gPickups = {}
	gRespawning = {}
	gGameOver = nil
	gStarting = nil
	gStarted = nil
	gThread = nil
end
function F_Time()
	if INFINITE_TIMER then
		return 1 / 0
	end
	return MATCH_TIME - (GetSyncTimer() - gStarted)
end

-- rat spawning
function F_InitPlayer(player,ped)
	SetSyncEntityDimension(ped,gDimension)
	if not TEST_MODE or GetSyncEntityArea(ped) ~= gMap.area then
		SetSyncEntityPos(ped,F_GetSpawn())
	end
	SetSyncEntityModel(ped,136)
	return F_SpawnPlayer(player,ped)
end
function F_SpawnPlayer(player,ped)
	if player then
		F_KillPlayer(player,false)
		F_SetPlayerWeapon(player,true,DEFAULT_WEAPON)
	else
		PedWander(ped)
	end
	PedSetMaxHealth(ped,MAX_HEALTH)
	PedSetHealth(ped,MAX_HEALTH)
	GameSetPedStat(ped,0,-1)
	GameSetPedStat(ped,1,0)
	F_UpdateRatClass(player)
end
function F_KillPlayer(player,killed)
	local data = gPlayers[player]
	if data then
		if killed then
			data.deaths = data.deaths + 1
		end
		if data.streak >= GIANT_RAT_STREAK then
			local ped = GetSyncPlayerPed(player)
			for player in pairs(gPlayers) do
				SendNetworkEvent(player,"rat_wars:GiantRat",ped)
			end
		end
		if data.adrenaline then
			SendNetworkEvent(player,"rat_wars:SetAdrenaline")
			data.adrenaline = nil
		end
		if DROP_WEAPONS then
			F_DropWeapon(player)
		end
		data.streak = 0
	end
end
function F_RespawnBots()
	for rat,data in pairs(gBots) do
		if PedIsDead(rat) then
			if not data.respawn then
				data.respawn = GetAccurateTimer()
			elseif GetAccurateTimer() - data.respawn >= BOT_RESPAWN_TIMER then
				PedSetDead(rat,false)
				SetSyncEntityPos(rat,F_GetSpawn())
				F_SpawnPlayer(nil,rat)
			end
		elseif data.respawn then
			F_SpawnPlayer(nil,rat)
			data.respawn = nil
		end
	end
end
function F_UpdateRespawns()
	local now = GetAccurateTimer()
	for ped,when in pairs(gRespawning) do
		if now - when >= INVULNERABLE_TIMER then
			gRespawning[ped] = nil
		end
	end
end

-- rat weapons
function F_DropWeapon(player)
	local data = gPlayers[player]
	if data and data.primary and data.primary.id ~= DEFAULT_WEAPON then
		local count = 0
		local timer = GetAccurateTimer()
		local oldest,age
		for pickup,data in pairs(gPickups) do
			if data.pickup == "loot" then
				local passed = timer - data.dropped
				if not oldest or age < passed then
					oldest,age = pickup,passed
				end
				count = count + 1
			end
		end
		if oldest and count > PICKUP_LOOT then
			DeleteSyncEntity(oldest)
			gPickups[oldest] = nil
		end
		if count < PICKUP_LOOT then
			local pickup = CreateSyncEntity(10152)
			local x,y,z = GetSyncEntityPos(GetSyncPlayerPed(player))
			SetSyncEntityPos(pickup,x,y,z)
			LockSyncEntityOwner(pickup,nil)
			for player in pairs(gPlayers) do
				SendNetworkEvent(player,"rat_wars:SpawnPickup",pickup,data.primary.stats.icon_index)
			end
			gPickups[pickup] = data.primary
			data.primary.pickup = "loot"
			data.primary.dropped = timer
			SendNetworkEvent(player,"rat_wars:SetWeapon")
			data.primary = nil
		end
	end
end
function F_SetPlayerWeapon(player,only,id,state)
	local data = gPlayers[player]
	if data then
		local stats = gWeapons[id]
		if only then
			data.secondary = nil
		elseif data.primary and (not data.secondary or (not ANY_SECONDARY and not stats.secondary and not data.secondary.stats.secondary and data.primary.stats.secondary)) then
			data.secondary = data.primary
		end
		if stats then
			if not state then
				state = {cocked = true,semi = false,scope = 0}
				if stats.open_bolt then
					state.ammo = stats.magazine_size
					state.chamber = false
				else
					state.ammo = stats.magazine_size - 1
					state.chamber = true
				end
			else
				state.id = nil
				state.stats = nil
			end
			SendNetworkEvent(player,"rat_wars:SetWeapon",id,state)
			state.id = id
			state.stats = stats
			data.primary = state -- .id, .stats, .ammo, .chamber, .cocked, .semi, .scope
		elseif data.primary then
			SendNetworkEvent(player,"rat_wars:SetWeapon")
			data.primary = nil
		end
	end
end
function F_UpdatePlayerWeapon(player)
	local data = gPlayers[player]
	if data then
		local state = {}
		for k,v in pairs(data.primary) do
			state[k] = v
		end
		state.id = nil
		state.stats = nil
		SendNetworkEvent(player,"rat_wars:UpdateWeapon",state)
	end
end

-- rat pickups
function F_UpdatePickups()
	if GetAccurateTimer() - gPickupTimer >= PICKUP_TIMER then
		local count = 0
		for _,data in pairs(gPickups) do
			if data.pickup == "stage" then
				count = count + 1
			end
		end
		if count < PICKUP_STAGE then
			local spots = {n = 0}
			for _,spot in ipairs(gMap.pickups) do
				if not F_ArePickupsNearby(unpack(spot)) then
					table.insert(spots,spot)
				end
			end
			if spots.n > 0 then
				local ptype = F_GetPickupType()
				if ptype == "weapon" then
					local state = {pickup = "stage",cocked = true,semi = false,scope = 0}
					local pickup = CreateSyncEntity(10152)
					SetSyncEntityPos(pickup,unpack(spots[math.random(spots.n)]))
					LockSyncEntityOwner(pickup,nil)
					state.id = PICKUP_WEAPONS[math.random(table.getn(PICKUP_WEAPONS))]
					state.stats = gWeapons[state.id]
					if state.open_bolt then
						state.ammo = state.stats.magazine_size
						state.chamber = false
					else
						state.ammo = state.stats.magazine_size - 1
						state.chamber = true
					end
					for player in pairs(gPlayers) do
						SendNetworkEvent(player,"rat_wars:SpawnPickup",pickup,state.stats.icon_index)
					end
					gPickups[pickup] = state
				elseif ptype == "health" then
					local pickup = CreateSyncEntity(2225)
					SetSyncEntityPos(pickup,unpack(spots[math.random(spots.n)]))
					LockSyncEntityOwner(pickup,nil)
					for player in pairs(gPlayers) do
						SendNetworkEvent(player,"rat_wars:SpawnPickup",pickup)
					end
					gPickups[pickup] = {pickup = "stage",powerup = ptype}
				elseif ptype == "adrenaline" then
					local pickup = CreateSyncEntity(2222)
					SetSyncEntityPos(pickup,unpack(spots[math.random(spots.n)]))
					LockSyncEntityOwner(pickup,nil)
					for player in pairs(gPlayers) do
						SendNetworkEvent(player,"rat_wars:SpawnPickup",pickup)
					end
					gPickups[pickup] = {pickup = "stage",powerup = ptype}
				end
			end
		end
		gPickupTimer = GetAccurateTimer()
	end
end
function F_UpdateAdrenaline()
	for player,data in pairs(gPlayers) do
		if data.adrenaline and GetAccurateTimer() - data.adrenaline >= data.adrenaline_duration then
			SendNetworkEvent(player,"rat_wars:SetAdrenaline")
			data.adrenaline = nil
		end
	end
end
function F_GetPickupType()
	local weight = 0
	for _,v in ipairs(PICKUP_CHANCES) do
		weight = weight + v[2]
	end
	weight = math.random(weight)
	for _,v in ipairs(PICKUP_CHANCES) do
		if weight <= v[2] then
			return v[1]
		end
		weight = weight - v[2]
	end
end
function F_ArePickupsNearby(x1,y1,z1)
	for pickup in pairs(gPickups) do
		local x2,y2,z2 = GetSyncEntityPos(pickup)
		local dx,dy,dz = x2-x1,y2-y1,z2-z1
		if dx*dx+dy*dy+dz*dz < 4 then
			return true
		end
	end
	return false
end

-- rat payment
function F_PayRewards(count)
	local scoreboard = F_GetScoreboard()
	local bonus = 1 + PAYOUT_BONUS_MULT * math.random()
	if count >= PAYOUT_MINIMUM_COUNT then
		local placement = math.max(1,math.floor(count*PAYOUT_REWARD_RATIO))
		local payout = math.floor(PAYOUT_MAX_CENTS * gPayoutMultiplier)
		if PAYOUT_MINIMUM_COUNT < PAYOUT_COUNT_MAXIMUM then
			payout = payout * (1 - (1 - math.min(1,(count-PAYOUT_MINIMUM_COUNT)/(PAYOUT_COUNT_MAXIMUM-PAYOUT_MINIMUM_COUNT))) * PAYOUT_COUNT_FACTOR) * bonus
		end
		if dsl.inventory and payout >= 25 then
			for _,v in ipairs(scoreboard) do
				local player,place,score = unpack(v)
				if place <= placement and score > 0 then
					local pay = payout * (1 - ((place - 1) / (placement - 1)) * PAYOUT_PLACE_FACTOR)
					if placement <= 1 then
						pay = payout
					end
					if score >= PAYOUT_KILL_COUNT_2 then
						pay = pay * PAYOUT_KILL_BONUS_2
					elseif score >= PAYOUT_KILL_COUNT_1 then
						pay = pay * PAYOUT_KILL_BONUS_1
					end
					if pay >= 25 then
						pay = math.floor(pay / 25) * 25
						if type(player) ~= "string" then
							dsl.inventory.RewardPlayerMoney(player,pay)
							gPlayers[player].pay = pay
						else
							PrintOutput(string.format("[%d] %s: $%.2f",place,player,pay/100))
						end
					end
				elseif type(player) == "string" then
					PrintOutput(string.format("[%d] %s: $0.00",place,player))
				end
			end
		end
	end
end
function F_GetScoreboard()
	local scoreboard = {}
	local place,score = 0,-1
	for player,data in pairs(gPlayers) do
		table.insert(scoreboard,{player,0,data.score})
	end
	table.sort(scoreboard,F_SortScoreboard)
	for i,v in ipairs(scoreboard) do
		if v[3] == score then -- same score? treat ties as the next placement.
			place = place + 1
			for b = 1,i-1 do
				if scoreboard[b][3] == score then
					scoreboard[b][2] = place
				end
			end
		else
			place,score = i,v[3]
		end
		v[2] = place
	end
	return scoreboard
end
function F_SortScoreboard(a,b)
	return a[3] > b[3]
end
function F_TestPayments(text,sample)
	PrintOutput(text)
	for _,v in ipairs(sample) do
		gPlayers[v[1]] = {score = v[2]}
	end
	F_PayRewards(table.getn(sample))
	gPlayers = {}
end

-- rat utility
function F_GetSpawns()
	local spawns = {}
	for _,spawn in ipairs(gMap.spawns) do
		local x1,y1,z1 = unpack(spawn)
		for player in pairs(gPlayers) do
			local x2,y2,z2 = GetSyncEntityPos(GetSyncPlayerPed(player))
			local dx,dy,dz = x2-x1,y2-y1,z2-z1
			if dx*dx+dy*dy+dz*dz < SPAWN_SHIELD_RADIUS*SPAWN_SHIELD_RADIUS then
				x1 = nil
				break
			end
		end
		if x1 then
			table.insert(spawns,spawn)
		end
	end
	if not spawns[1] then
		local best,distance
		for _,spawn in ipairs(gMap.spawns) do
			local dist = 100 -- distance to closest player
			local x1,y1,z1 = unpack(spawn)
			for player in pairs(gPlayers) do
				local x2,y2,z2 = GetSyncEntityPos(GetSyncPlayerPed(player))
				local dx,dy,dz = x2-x1,y2-y1,z2-z1
				dist = math.min(dist,dx*dx+dy*dy+dz*dz)
			end
			if not best or dist > distance then
				best,distance = spawn,dist -- get spawn with farthest players
			end
		end
		spawns[1] = best -- no spawns were considered safe, so get best
	end
	return spawns
end
function F_GetSpawn()
	local spawns = F_GetSpawns()
	local x,y,z,h = unpack(spawns[math.random(table.getn(spawns))])
	local r = math.rad(math.random(0,359))
	local d = math.random(0,80) / 100
	return x-math.sin(r)*d,y+math.cos(r)*d,z,h
end

-- activity manager
function F_JoinActivity(player)
	if dsl.activity then
		return dsl.activity.StartActivity(player,"rat_wars",nil,nil,{
			announce = true,
			title = "Rat Wars",
			description = "Compete in a competitive first person shooter where you play as a rat!",
			warp_pos = {}, -- empty table means it'll have to be set during event to do anything
		})
	end
	return false
end
function F_LeaveActivity(player)
	if dsl.activity then
		dsl.activity.LeaveActivity(player,"rat_wars")
	end
end

-- payout multiplier
SetCommand("rat_wars_payout",function(mult)
	mult = tonumber(mult)
	if mult and mult >= 0 and mult <= 5 then
		PrintOutput("set multiplier: "..math.floor(mult*100).."%")
		gPayoutMultiplier = mult
	else
		PrintError("invalid multiplier")
	end
end,false,"Usage: rat_wars_payout <mult>\nSet a multiplier for Rat Wars payouts until the server restarts.")

-- test payments
if not TEST_PAYMENT then return end
TEST_PARTICIPANTS = {"Xx_Yubari_xX","PixeL","MSTVD","SWEGTA","rockstarfanatic","Snowy","puppy","Another","Example","Username","Adam","Sandler"}
for count = 1,PAYOUT_COUNT_MAXIMUM do
	local test = {}
	local participants = {n = 0}
	for _,v in ipairs(TEST_PARTICIPANTS) do
		table.insert(participants,v)
	end
	for i = 1,count do
		table.insert(test,{table.remove(participants,math.random(participants.n)),i})
	end
	F_TestPayments("Example Rat Wars ( < 30 ) "..count,test)
end
for count = 1,PAYOUT_COUNT_MAXIMUM do
	local test = {}
	local participants = {n = 0}
	for _,v in ipairs(TEST_PARTICIPANTS) do
		table.insert(participants,v)
	end
	for i = 1,count do
		table.insert(test,{table.remove(participants,math.random(participants.n)),30+i})
	end
	F_TestPayments("Example Rat Wars ( >= 30 ) "..count,test)
end
