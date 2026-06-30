--[[
	revive:
	"/GLOBAL/1_11X2/ANIMATIONS/GARYLIGHTBAG","1_11X2.ACT"
	
	getup:
	"/GLOBAL/5_04/MANDYSTAND","5_04.ACT"
	"/GLOBAL/4_05/ANIMS/PUSHUPS/START/END","4_05.ACT"
	
	unused:
	"/GLOBAL/6_02/PLAYERGETUP/GETUP","6_02.ACT"
	"/GLOBAL/HITTREE/STANDING/POSTHIT/BELLYDOWN/BELLYDOWNGETUP/BELLYDOWNGETUP",""
	"/GLOBAL/5_04/GURNEYDEFEATED/GURNEYDEFEATED_CHILD/GURNEYDEFEATED_CHILD_CHILD","5_04.ACT"
]]

gRevive = false
gFaded = false
gDelay = 1000

function exports.SetSpawnDelay(delay)
	if type(delay) ~= "number" then
		typerror(1,"number")
	elseif not (delay >= 1 and delay < 1 / 0) then
		argerror(1,"invalid delay")
	end
	gDelay = math.floor(delay)
end

RegisterNetworkEventHandler("spawner:_Revive",function()
	-- only used if sync+ isn't running, otherwise sync+ is used to mark the ped as alive again
	gRevive = true
end)

function main()
	local dying
	local unfading
	if IsNetworkLoading() then
		while not F_IsPlayerReady() do
			Wait(0)
		end
		Wait(100)
		while AreaIsLoading() or IsStreamingBusy() do
			Wait(0)
		end
		FinishNetworkLoading(1000)
	end
	SendNetworkEvent("spawner:_Init")
	while true do
		if gRevive then
			PedSetDead(gPlayer,false)
			gRevive = false
		end
		if PedIsDead(gPlayer) then
			if not dying then
				gDelay = 2000
				if RunLocalEvent("spawner:Respawning") then
					dying = GetAccurateTimer()
				end
			elseif GetAccurateTimer() - dying >= gDelay then
				if gFaded then
					SendNetworkEvent("spawner:_Dead")
					dying = GetAccurateTimer()
					gDelay = 8000
				else
					CameraFade(650,0)
					dying = GetAccurateTimer()
					gDelay = 700
					gFaded = true
				end
			end
			unfading = nil
		elseif dying then
			dying = nil
		end
		if gFaded and not dying then
			if not unfading then
				unfading = GetAccurateTimer()
			elseif GetAccurateTimer() - unfading >= 500 and RunLocalEvent("spawner:Unfade") then
				CameraFade(650,1)
				unfading = nil
				gFaded = false
			end
		end
		Wait(0)
	end
end
function MissionCleanup()
	if gFaded then
		CameraFade(0,1)
	end
end
function F_IsPlayerReady()
	local sped = GetSyncPlayerPed()
	return sped and IsSyncEntityReady(sped)
end
