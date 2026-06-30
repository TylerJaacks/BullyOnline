LoadScript("effects.lua")

gPlaying = {} -- peds playing an action node
gShooting = {} -- speds that should shoot
gShot = {} -- speds that were shot

SHOT_TIMEOUT_MS = 800
EFFECT_DISTANCE = 0.2
HEADSHOT_MULT = 2

RegisterNetworkEventHandler("psync:ShootWeapon",function(sped,action,weapon)
	gShooting[sped] = {action,weapon}
end)
RegisterNetworkEventHandler("psync:ShotPed",function(sped,weapon,health,headshot)
	gShot[sped] = {
		show = true,
		when = GetAccurateTimer(),
		weapon = weapon,
		health = health,
		headshot = headshot,
	}
end)

RegisterLocalEventHandler("sync:DeletePed",function(sped)
	gShooting[sped] = nil
	gShot[sped] = nil
end)
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	local current = gShooting[sped]
	if current then
		local ped = PedFromSyncPed(sped)
		if PedIsValid(ped) and not PedIsModel(ped,136) then
			if dsl["sync+"] and PedGetWeapon(ped) ~= current[2] then
				dsl["sync+"].SetPedWeapon(ped,current[2],1)
			end
			if PedGetWeapon(ped) == current[2] then
				local node = F_TranslateShooting(current[1])
				if node then
					if not PedSetActionNode(ped,node,"") then
						PrintWarning("failed to play "..node)
					end
					gPlaying[ped] = node
				end
			end
		end
		gShooting[sped] = nil
	end
end)
RegisterLocalEventHandler("sync+:SetAction",function(ped)
	-- sync+ won't set an action while we're trying to play our action
	return gPlaying[ped]
end)

function main()
	local shooting = {}
	local shot = {}
	SendNetworkEvent("psync:InitScript")
	while true do
		for ped,node in pairs(gPlaying) do
			if not PedIsValid(ped) or not PedIsPlaying(ped,node,true) then
				gPlaying[ped] = nil
			end
		end
		for ped in pairs(shooting) do
			if not PedIsValid(ped) then
				shooting[ped] = nil
			end
		end
		for ped in pairs(shot) do
			if not PedIsValid(ped) then
				shot[ped] = nil
			end
		end
		for ped in AllPeds() do
			local sped = PedGetSyncPed(ped)
			local action = F_GetShooting(ped)
			local weapon = PedGetWeapon(ped)
			if sped and action and weapon ~= -1 then
				local current = shooting[ped]
				if not current or (current[1] ~= action or current[2] ~= weapon) then
					if sped then
						SendNetworkEvent("psync:ShootWeapon",sped,action,weapon)
					end
					shooting[ped] = {action,weapon}
				end
			elseif shooting[ped] then
				shooting[ped] = nil
			end
			if sped and PedIsHit(ped,2,100) and PedGetWhoHitMeLast(ped) == gPlayer then
				local weapon = PedGetLastHitWeapon(ped)
				if shot[ped] ~= weapon and PedIsPlaying(ped,"/GLOBAL/HITTREE",true) then
					if weapon ~= -1 then
						local damage = PedGetHitRecordDamage(ped)
						if damage > 0 then
							if PedMePlaying(ped,"HEAD",true) then
								SendNetworkEvent("psync:ShotPed",sped,weapon,damage*HEADSHOT_MULT,true)
							else
								SendNetworkEvent("psync:ShotPed",sped,weapon,damage)
							end
						end
					end
					shot[ped] = weapon
				end
			elseif shot[ped] then
				shot[ped] = nil
			end
		end
		for sped,data in pairs(gShot) do
			local ped = PedFromSyncPed(sped)
			if PedIsValid(ped) and GetAccurateTimer() - data.when < SHOT_TIMEOUT_MS then
				if data.show then
					local name = gWeaponEffects[data.weapon]
					if name then
						local x,y,z = F_GetPosition(ped,data.headshot)
						local h = PedGetHeading(ped)
						local fx = EffectCreate(name,x-math.sin(h)*EFFECT_DISTANCE,y+math.cos(h)*EFFECT_DISTANCE,z)
						EffectSetDirection(fx,-math.sin(h),math.cos(h),0)
					end
					if PedMePlaying(ped,"DEFAULT_KEY",true) and not PedIsPlaying(ped,"/GLOBAL/HITTREE",true) and not PedIsModel(ped,136) then
						if data.health == 0 then
							ForceActionNode(ped,"/GLOBAL/HITTREE/STANDING/RANGED/DEFAULTPROJECTILE/TORSO/FRONT/SLINGSHOT_CHARGED")
						else
							ForceActionNode(ped,"/GLOBAL/HITTREE/STANDING/RANGED/DEFAULTPROJECTILE/TORSO/FRONT/DEFAULT")
						end
					end
					data.show = false
				elseif PedGetHealth(ped) < data.health then
					PedSetHealth(ped,data.health)
				end
			else
				gShot[sped] = nil
			end
		end
		Wait(0)
	end
end
function F_GetPosition(ped,headshot)
	local px,py,pz = PedGetPosXYZ(ped)
	local hx,hy,hz = PedGetHeadPos(ped)
	local dx,dy,dz = hx-px,hy-py,hz-pz
	local ratio = 2 / 3
	if headshot then
		ratio = 0.95
	end
	return px+dx*ratio,py+dy*ratio,pz+dz*ratio
end
function F_GetShooting(ped)
	if PedIsPlaying(ped,"/GLOBAL/GUN/GUN/DEFAULT_KEY",true) and PedMePlaying(ped,"FIRE",true) then
		if PedMePlaying(ped,"BROCKET",true) then
			return "BROCKET"
		elseif PedMePlaying(ped,"SPUDG",true) then
			return "SPUDG"
		end
	elseif PedIsPlaying(ped,"/GLOBAL/SLINGSHOT/SLINGSHOT/DEFAULT_KEY",true) and PedMePlaying(ped,"RELEASE",true) then
		if PedMePlaying(ped,"SLINGSHOT",true) then
			return "SLINGSHOT"
		elseif PedMePlaying(ped,"SUPERSLINGSHOT",true) then
			return "SUPERSLINGSHOT"
		end
	elseif PedIsPlaying(ped,"/GLOBAL/THROWN/THROWN/DEFAULT_KEY",true) and PedMePlaying(ped,"RELEASE",true) then
		if PedMePlaying(ped,"2HANDED",true) then
			return "2HANDED"
		elseif PedMePlaying(ped,"FRISBEE",true) then
			return "FRISBEE"
		elseif PedMePlaying(ped,"OVERHAND",true) then
			if PedMePlaying(ped,"ALTFIRE",true) then
				if PedMePlaying(ped,"BANANA",true) then
					return "ALTFIRE/BANANA"
				elseif PedMePlaying(ped,"CHERRYBOMB",true) then
					return "ALTFIRE/CHERRYBOMB"
				end
				return "ALTFIRE/STINKBOMB"
			elseif PedMePlaying(ped,"RBANDBALL",true) then
				return "RBANDBALL"
			end
			return "RELEASE"
		elseif PedMePlaying(ped,"UNDERHAND",true) then
			if PedMePlaying(ped,"ALTFIRE",true) then
				if PedMePlaying(ped,"ITCHINGPOWDER",true) then
					return "ALTFIRE/ITCHINGPOWDER"
				end
				return "ALTFIRE/MARBLES"
			end
			return "THROW"
		end
	end
end
function F_TranslateShooting(what)
	if what == "BROCKET" or what == "SPUDG" then
		return "/GLOBAL/GUN/GUN/ACTIONS/CONTROLLER/UPPERBODY/FIREACTIONS/"..what.."/RELEASE/FIRE/PRIMARY/FIRE"
	elseif what == "SLINGSHOT" or what == "SUPERSLINGSHOT" then
		return "/GLOBAL/SLINGSHOT/SLINGSHOT/ACTIONS/CONTROLLER/UPPERBODY/FIREACTIONS/CHARGE/RELEASE/RELEASE"
	elseif what == "2HANDED" or what == "FRISBEE" then
		return "/GLOBAL/THROWN/THROWN/ACTIONS/CONTROLLER/UPPERBODY/"..what.."/CHARGE/RELEASE"
	elseif what == "RELEASE" or what == "RBANDBALL" or what == "ALTFIRE/STINKBOMB" or what == "ALTFIRE/CHERRYBOMB" or what == "ALTFIRE/BANANA" then
		return "/GLOBAL/THROWN/THROWN/ACTIONS/CONTROLLER/UPPERBODY/OVERHAND/THROW/CHARGE/RELEASE/"..what
	elseif what == "THROW" or what == "ALTFIRE/MARBLES" or what == "ALTFIRE/ITCHINGPOWDER" then
		return "/GLOBAL/THROWN/THROWN/ACTIONS/CONTROLLER/UPPERBODY/UNDERHAND/CHARGE/RELEASE/"..what
	end
end
