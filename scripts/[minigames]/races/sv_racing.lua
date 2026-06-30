LoadScript("races.lua")

PAYOUT_SINGLE_PLAYER = {0,0}
PAYOUT_MINIMUM_COUNT = 2 -- must be at least this many players
PAYOUT_REWARD_RATIO = 0.8 -- how much of the scoreboard gets paid (always at least 1st place though)
PAYOUT_MAX_CENTS = 1800
PAYOUT_COUNT_MAXIMUM = 9 -- how many players to get the full payment
PAYOUT_COUNT_FACTOR = 0.62 -- how much of the price gets reduced by having under maximum players
PAYOUT_PLACE_FACTOR = 0.68 -- how much of the price gets reduced by player placement
PAYOUT_BONUS_MULT = 0.15 -- maximum random bonus multiplier

COLLISION_VOTE_RATIO = 0.5

RESULTS_MS = 15000
BLIP_RANGE = 3 -- bigger than the actual blip for delay
DEBUGGING = false -- show debugging chat messages

gPlayers = {} -- players recognized by the script
gRaces = {} -- active races

gPayoutMultiplier = 1

RegisterLocalEventHandler("PlayerDropped",function(player)
	local data = gPlayers[player]
	if data then
		local race = gRaces[data.race]
		if race then
			local vehicle = race.racers[player].vehicle
			if IsSyncVehicleValid(vehicle) then
				DeleteSyncEntity(vehicle)
			end
			race.racers[player] = nil
			if next(race.racers) then
				F_UpdateVote(race)
				for other in pairs(race.racers) do
					SendNetworkEvent(other,"races:SetResult",GetPlayerId(player))
				end
				if race.setup then
					race.active = false
					for _,v in pairs(race.racers) do
						if not v.finished then
							race.active = true -- someone is still racing
							break
						end
					end
				else
					local loading = false
					for _,v in pairs(race.racers) do
						if v.loading then
							loading = true
						end
					end
					if not loading then
						F_Setup(race)
					end
				end
			else
				F_Cleanup(race)
				gRaces[data.race] = nil
			end
		end
		gPlayers[player] = nil
	end
end)
RegisterLocalEventHandler("spawner:Respawning",function(player,f_set)
	local data = gPlayers[player]
	if data and data.race then
		local race = gRaces[data.race]
		local data = race.racers[player] -- racer data (different than player data that just contains .race)
		race = race.race
		if data.finished then
			local x,y,z,d = unpack(race.spectator_spawn)
			local h = math.random() * math.pi * 2
			f_set(x-math.sin(h)*d,y+math.cos(h)*d,z,h)
		elseif data.checkpoint > 0 then
			local sx,sy,sz = unpack(race.checkpoints[data.checkpoint])
			local tx,ty,tz = unpack(race.checkpoints[data.checkpoint+1] or race.checkpoints[1])
			f_set(sx,sy,sz,math.deg(math.atan2(sx-tx,ty-sy)))
		else
			f_set(unpack(race.spawns[math.random(table.getn(race.spawns))]))
		end
	end
end)
RegisterLocalEventHandler("spawner:Respawned",function(player)
	local data = gPlayers[player]
	if data and data.race then
		local race = gRaces[data.race].race
		if dsl["sync+"] and race.health then
			local ped = GetSyncPlayerPed(player)
			PedSetMaxHealth(ped,race.health)
			PedSetHealth(ped,race.health)
		end
	end
end)
RegisterLocalEventHandler("sync+:SwapModel",function(ped)
	local data = gPlayers[GetSyncPlayerFromPed(ped)]
	if data and data.race then
		local race = gRaces[data.race].race
		if dsl["sync+"] and race.health then
			PedSetMaxHealth(ped,race.health)
			PedSetHealth(ped,race.health)
		end
	end
end)

RegisterNetworkEventHandler("races:InitScript",function(player)
	if not gPlayers[player] then
		if DoesPlayerHaveRole(player,"admin") then
			SendNetworkEvent(player,"races:SetAdmin")
			gPlayers[player] = {admin = true,pay = 0}
		else
			gPlayers[player] = {admin = false,pay = 0}
		end
	end
end)
RegisterNetworkEventHandler("races:StartRace",function(player,index)
	local race = RACES[index]
	local data = gPlayers[player]
	SetSyncActiveDimension(GetSyncMainDimension())
	if race and data and not data.race and F_Available(race) then
		local ped = GetSyncPlayerPed(player)
		local x1,y1,z1 = GetSyncEntityPos(ped)
		local x2,y2,z2 = unpack(race.blip)
		local dx,dy,dz = x2-x1,y2-y1,z2-z1
		if dsl.activity and dx*dx+dy*dy+dz*dz < BLIP_RANGE*BLIP_RANGE and GetSyncEntityArea(ped) == race.area then
			local name = race.name
			local cutoff = string.find(name,"%s*%(")
			if cutoff then
				name = string.sub(name,1,cutoff-1)
			end
			dsl.activity.StartActivity(player,"race_"..race.id,CB_StartRace,index,{
				title = name,
				description = race.description or "A competitive race where the first player to hit all the checkpoints wins!",
				announce = true,
				area = race.area,
				center = {x2,y2,z2},
				range = race.blip[4],
				max_players = table.getn(race.spawns),
				timer_ms = 45000,
				warp_pos = race.warp_pos or {x2,y2,z2},
				warp_range = race.warp_range or 0.5,
			})
		end
	end
	SendNetworkEvent(player,"races:AllowRequest")
end)
RegisterNetworkEventHandler("races:FadedScreen",function(player)
	local data = gPlayers[player]
	if data and data.race then
		local race = gRaces[data.race]
		race.racers[player].loading = false
		for _,v in pairs(race.racers) do
			if v.loading then
				return -- someone is still loading
			end
		end
		F_Setup(race)
	end
end)
RegisterNetworkEventHandler("races:HitCheckpoint",function(player,cx,cy,cz)
	local data = gPlayers[player]
	if data and data.race then
		local index
		local race = gRaces[data.race]
		local data = race.racers[player]
		race = race.race
		if not race.shuffle then
			local i = math.mod(data.checkpoint,table.getn(race.checkpoints)) + 1
			local vx,vy,vz = unpack(race.checkpoints[i])
			if vx == cx and vy == cy and vz == cz then
				index = i
			end
		else
			for i,v in ipairs(race.checkpoints) do
				local vx,vy,vz = unpack(v)
				if vx == cx and vy == cy and vz == cz then
					index = i
					break
				end
			end
		end
		if index and (race.shuffle or index == math.mod(data.checkpoint,table.getn(race.checkpoints)) + 1) then
			if not race.checkpoints[index+1] and data.lap < race.laps then
				data.lap = data.lap + 1
			end
			data.checkpoint = index
		elseif DEBUGGING and dsl.chat then
			if index then
				dsl.chat.Say(GetPlayerName(player).." was denied checkpoint #"..index)
			else
				dsl.chat.Say(GetPlayerName(player).." reported an invalid checkpoint")
			end
		end
	end
end)
RegisterNetworkEventHandler("races:AttemptRespawn",function(player,cx,cy,cz,ch)
	local data = gPlayers[player]
	if data and data.race and type(cx) == "number" and type(cy) == "number" and type(cz) == "number" then
		local valid = false
		local race = gRaces[data.race]
		local data = race.racers[player]
		race = race.race
		for _,v in ipairs(race.spawns) do
			local vx,vy,vz = unpack(v)
			local dx,dy,dz = cx-vx,cy-vy,cz-vz
			if dx*dx+dy*dy+dz*dz < 100 then
				valid = true
				break
			end
		end
		for _,v in ipairs(race.checkpoints) do
			local vx,vy,vz = unpack(v)
			local dx,dy,dz = cx-vx,cy-vy,cz-vz
			if dx*dx+dy*dy+dz*dz < 100 then
				valid = true
				break
			end
		end
		if valid and (not data.respawned or GetAccurateTimer() - data.respawned >= 8000) then
			if data.vehicle then
				if IsSyncVehicleValid(data.vehicle) then
					DeleteSyncEntity(data.vehicle)
				end
				if type(data.model) == "number" then
					data.vehicle = CreateSyncVehicle(data.model)
				elseif dsl.propcars then
					data.vehicle = dsl.propcars.CreateVehicle(data.model)
				else
					data.vehicle = nil
				end
				if data.vehicle then
					if type(ch) == "number" and ch >= -720 and ch <= 720 then
						SetSyncEntityPos(data.vehicle,cx,cy,cz,ch)
					end
					SetSyncPedVehicle(GetSyncPlayerPed(player),data.vehicle)
				end
			end
			data.respawned = GetAccurateTimer()
		end
	end
end)
RegisterNetworkEventHandler("races:FinishRace",function(player,failure)
	local data = gPlayers[player]
	if data and data.race then
		local race = gRaces[data.race]
		local data = race.racers[player]
		if not data.finished and (failure or (not race.race.checkpoints[data.checkpoint+1] and data.lap == race.race.laps)) then
			local result = GetSyncTimer() - race.started
			data.finished = result
			for other in pairs(race.racers) do
				if failure then
					SendNetworkEvent(other,"races:SetResult",GetPlayerId(player),GetPlayerName(player))
				else
					SendNetworkEvent(other,"races:SetResult",GetPlayerId(player),GetPlayerName(player),result)
				end
			end
			for _,v in pairs(race.racers) do
				if not v.finished then
					return -- someone is still racing
				end
			end
			race.active = false
		elseif DEBUGGING and dsl.chat then
			if data.finished then
				dsl.chat.Say(GetPlayerName(player).." double finished")
			elseif not failure then
				dsl.chat.Say(GetPlayerName(player).." was denied finishing")
			end
		end
	end
end)
RegisterNetworkEventHandler("races:ExitVehicle",function(player)
	local data = gPlayers[player]
	if data and data.race then
		data = gRaces[data.race].racers[player]
		if data.finished and data.vehicle then
			if IsSyncVehicleValid(data.vehicle) then
				DeleteSyncEntity(data.vehicle)
			end
			data.vehicle = nil
		end
	end
end)
RegisterNetworkEventHandler("races:ForceTime",function(player,index)
	local race = RACES[index]
	local data = gPlayers[player]
	if race and data and data.admin and dsl["sync+"] and not F_Available(race) then
		ClockSet(unpack(race.start_time))
	end
end)
RegisterNetworkEventHandler("races:VoteCollision",function(player)
	local data = gPlayers[player]
	if data and data.race then
		local race = gRaces[data.race]
		local data = race.racers[player]
		if race.voting and data.collision then
			data.collision = false
			F_UpdateVote(race)
		end
	end
end)

function F_UpdateVote(race)
	local count,total = 0,0
	for _,data in pairs(race.racers) do
		if not data.collision then
			count = count + 1
		end
		total = total + 1
	end
	race.collision = count < total * COLLISION_VOTE_RATIO
	for player in pairs(race.racers) do
		if race.collision then
			SendNetworkEvent(player,"races:UpdateCollision",count/total,true)
		else
			SendNetworkEvent(player,"races:UpdateCollision",count/total)
		end
	end
end

function CB_StartRace(players,index)
	local i = 1
	local race = RACES[index]
	local racers = {}
	local peds = {}
	local id = 1
	while gRaces[id] do
		id = id + 1
	end
	for _,player in ipairs(players) do
		local data = gPlayers[player]
		if (data and data.race) or not IsPlayerValid(player) then
			error("inconsistent player state")
		end
	end
	for count,player in ipairs(players) do
		if gPlayers[player] and race.spawns[count] then
			table.insert(peds,GetSyncPlayerPed(player))
		end
	end
	for count,player in ipairs(players) do
		local data = gPlayers[player]
		if data and race.spawns[count] then
			SendNetworkEvent(player,"races:SetRace",index,count)
			SendNetworkEvent(player,"races:AddRacers",peds)
			racers[player] = {spawn = count,loading = true,checkpoint = 0,lap = 1,collision = true}
			data.race = id
		end
	end
	i = 0
	for _ in pairs(racers) do
		i = i + 1
	end
	gRaces[id] = {
		active = true, -- at least 1 racer doesn't have .finished yet
		setup = false, -- the race hasn't been setup (see F_Setup)
		dimension = F_InitDimension(CreateSyncDimension("race_"..id)),
		thread = CreateThread("T_Race",id),
		started = GetSyncTimer(),
		count = i, -- start racer count, used to calculate payment later
		racers = racers,
		race = race,
		collision = true,
		voting = true,
	}
end
function F_InitDimension(dimension)
	local api = dsl["sync+"]
	if api then
		api.InheritClock()
		api.InheritChapter()
		api.InheritWeather()
	end
	return dimension
end
function F_Available(race)
	if dsl["sync+"] then
		local hour,minute = ClockGet()
		local open = race.start_time[1] * 60 + race.start_time[2]
		local close = race.end_time[1] * 60 + race.end_time[2]
		minute = hour * 60 + minute
		if open > close then
			return minute >= open or minute < close
		end
		return minute >= open and minute < close
	end
	return true
end
function T_Race(id)
	local race = gRaces[id]
	while race.active and GetSyncTimer() - race.started < 15000 do
		Wait(0)
	end
	race.voting = false
	while race.active and GetSyncTimer() - race.started < (race.race.max_timer + 15) * 1000 do
		Wait(0)
	end
	for player,data in pairs(race.racers) do
		if not data.finished then
			for other in pairs(race.racers) do
				SendNetworkEvent(other,"races:SetResult",GetPlayerId(player),GetPlayerName(player))
			end
			data.finished = 1 / 0
		end
	end
	F_PayRewards(id,race.count,race.race.payout or 1)
	for player in pairs(race.racers) do
		SendNetworkEvent(player,"races:FinishRace",gPlayers[player].pay)
	end
	Wait(RESULTS_MS)
	F_Cleanup(race)
	gRaces[id] = nil
end
function F_Setup(race)
	SetSyncActiveDimension(race.dimension)
	if race.race.weather then
		WeatherSet(race.race.weather)
	end
	if race.race.chapter then
		ChapterSet(race.race.chapter)
	end
	if race.race.clock then
		ClockSet(unpack(race.race.clock))
		ClockSetTickRate(10)
	end
	if race.race.objects and dsl.object_spawner then
		for _,set in ipairs(race.race.objects) do
			dsl.object_spawner.Activate(set)
		end
	end
	for player,data in pairs(race.racers) do
		local vehicle
		local ped = GetSyncPlayerPed(player)
		SetSyncEntityDimension(ped,race.dimension)
		if dsl["sync+"] and race.race.health then
			PedSetMaxHealth(ped,race.race.health)
			PedSetHealth(ped,race.race.health)
		end
		if race.race.vehicle then
			local value = race.race.vehicle
			if type(value) == "table" then
				value = value[math.random(table.getn(value))]
			end
			if type(value) == "number" then
				if value ~= -1 then
					vehicle = CreateSyncVehicle(value)
				end
			elseif dsl.propcars then
				vehicle = dsl.propcars.CreateVehicle(value)
			end
			data.model = value
		end
		if vehicle then
			SetSyncEntityPos(vehicle,unpack(race.race.spawns[data.spawn]))
			SetSyncPedVehicle(ped,vehicle)
			data.vehicle = vehicle
		else
			SetSyncEntityPos(ped,unpack(race.race.spawns[data.spawn]))
		end
		SendNetworkEvent(player,"races:UnfadeScreen")
	end
	race.setup = true
end
function F_Cleanup(race)
	if dsl.activity then
		dsl.activity.StopActivity("race_"..race.race.id)
	end
	for player,data in pairs(race.racers) do
		if IsSyncVehicleValid(data.vehicle) then
			DeleteSyncEntity(data.vehicle)
		end
		if dsl["sync+"] then
			PedSetDead(GetSyncPlayerPed(player),false)
		end
		SendNetworkEvent(player,"races:SetRace")
		gPlayers[player].race = nil
	end
	if race.thread then
		TerminateThread(race.thread)
	end
	DeleteSyncDimension(race.dimension)
end

function F_PayRewards(id,count,multiplier)
	local scoreboard = F_GetScoreboard(id)
	local bonus = 1 + PAYOUT_BONUS_MULT * math.random()
	if count >= PAYOUT_MINIMUM_COUNT then
		local placement = math.max(1,math.floor(count*PAYOUT_REWARD_RATIO))
		local payout = math.floor(PAYOUT_MAX_CENTS * gPayoutMultiplier * multiplier)
		if PAYOUT_MINIMUM_COUNT < PAYOUT_COUNT_MAXIMUM then
			payout = payout * (1 - (1 - math.min(1,(count-PAYOUT_MINIMUM_COUNT)/(PAYOUT_COUNT_MAXIMUM-PAYOUT_MINIMUM_COUNT))) * PAYOUT_COUNT_FACTOR) * bonus
		end
		if dsl.inventory and payout >= 25 then
			for _,v in ipairs(scoreboard) do
				local player,place,ndnf = unpack(v)
				if ndnf and place <= placement then
					local pay = payout * (1 - ((place - 1) / (placement - 1)) * PAYOUT_PLACE_FACTOR)
					if placement <= 1 then
						pay = payout
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
	elseif dsl.inventory and count == 1 then
		for _,v in ipairs(scoreboard) do
			local player = v[1]
			local pay = math.floor(math.random(unpack(PAYOUT_SINGLE_PLAYER))/25)*25
			if pay > 0 then
				if type(player) ~= "string" then
					dsl.inventory.RewardPlayerMoney(player,pay)
					gPlayers[player].pay = pay
				else
					PrintOutput(string.format("[1] %s: $%.2f",player,pay/100))
				end
			end
		end
	end
end
function F_GetScoreboard(id)
	local scoreboard = {}
	local place,score = 0,-1
	for player,data in pairs(gPlayers) do
		if data.race == id then
			local race = gRaces[data.race]
			local data = race.racers[player]
			local finished
			if data.finished and data.finished < 1 / 0 then
				finished = data.finished
			end
			if type(player) == "string" then -- for F_TestPayments
				table.insert(scoreboard,{player,player,finished})
			else
				table.insert(scoreboard,{player,GetPlayerName(player),finished})
			end
		end
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
		v[2] = place -- now its {player,place,time}
	end
	return scoreboard
end
function F_SortScoreboard(a,b)
	if a[3] == b[3] then
		return string.lower(a[2]) < string.lower(b[2])
	elseif a[3] and b[3] then
		return a[3] < b[3]
	end
	return a[3]
end
function F_TestPayments(text,sample)
	PrintOutput(text)
	gRaces = {test = {racers = {}}}
	for _,v in ipairs(sample) do
		gPlayers[v[1]] = {race = "test"}
		gRaces.test.racers[v[1]] = {finished = v[2]}
	end
	F_PayRewards("test",table.getn(sample),1)
	gPlayers = {}
	gRaces = {}
end

function F_AssertUniqueRaces()
	local races = {}
	for _,race in ipairs(RACES) do
		if races[race.id] then
			error("duplicate race id: "..race.id)
		end
		races[race.id] = true
	end
end
F_AssertUniqueRaces()

SetCommand("races_payout",function(mult)
	mult = tonumber(mult)
	if mult and mult >= 0 and mult <= 5 then
		PrintOutput("set multiplier: "..math.floor(mult*100).."%")
		gPayoutMultiplier = mult
	else
		PrintError("invalid multiplier")
	end
end,false,"Usage: races_payout <mult>\nSet a multiplier for race payouts until the server restarts.")

if not DEBUGGING then return end
TEST_PARTICIPANTS = {"Xx_Yubari_xX","PixeL","MSTVD","SWEGTA","rockstarfanatic","Snowy","puppy","Another","Example","Username","Adam","Sandler"}
for count = 1,PAYOUT_COUNT_MAXIMUM do
	local test = {}
	local participants = {n = 0}
	for _,v in ipairs(TEST_PARTICIPANTS) do
		table.insert(participants,v)
	end
	for i = 1,count do
		if i ~= 1 then
			table.insert(test,{table.remove(participants,math.random(participants.n)),i})
		else
			table.insert(test,{table.remove(participants,math.random(participants.n))})
		end
	end
	F_TestPayments("Example Race "..count,test)
end
