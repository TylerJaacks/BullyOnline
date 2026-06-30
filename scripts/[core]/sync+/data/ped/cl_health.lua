-- SYNC+ | ped health | Xx_Yubari_xX
--  provides client side health / death sync

LoadScript("data/utility/shared/keys.lua")

local invulnerable = setmetatable({},{__mode = "k"})
local minimum = setmetatable({},{__mode = "k"})
local undead = setmetatable({},{__mode = "k"})

local server_max_hp = GetConfigBoolean(GetScriptConfig(),"server_max_hp",false)

-- don't respawn when dead:
RegisterLocalEventHandler("sync:SpawnPed",function(sped)
	-- clear ped from tables when they spawn
	invulnerable[sped] = nil
	minimum[sped] = nil
	undead[sped] = nil
	return sped[KEY_DEAD]
end)

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		if sped[KEY_INVULNERABLE] then
			PedSetInvulnerable(ped,true)
			invulnerable[sped] = true
		elseif invulnerable[sped] then
			PedSetInvulnerable(ped,false)
			invulnerable[sped] = nil
		end
		if IsSyncEntityOwned(sped) then
			if minimum[sped] then
				PedSetMinHealth(ped,-100)
				minimum[sped] = nil
			end
			if undead[sped] then
				PedSetFlag(ped,58,false)
				undead[sped] = nil
			end
			if WasSyncEntityUpdated(sped,KEY_HP) then
				PedSetHealth(ped,sped[KEY_HP])
			end
			if WasSyncEntityUpdated(sped,KEY_DEAD) then
				F_UpdateDeath(sped,ped)
			end
		else
			if sped[KEY_HP] > 0 then
				PedSetMinHealth(ped,1) -- don't allow zero health until the server says so
				minimum[sped] = true
			elseif minimum[sped] then
				PedSetMinHealth(ped,-100)
				minimum[sped] = nil
			end
			if not sped[KEY_DEAD] then
				PedSetFlag(ped,58,true) -- don't allow death until the server says so
				undead[sped] = true
			elseif undead[sped] then
				PedSetFlag(ped,58,false)
				undead[sped] = nil
			end
			--if not PedIsPlaying(ped,"/GLOBAL/HITTREE",true) then -- allow health prediction
				PedSetHealth(ped,sped[KEY_HP])
			--end
			F_UpdateDeath(sped,ped)
		end
		if (server_max_hp or WasSyncEntityUpdated(sped,KEY_MAXHP) or not IsSyncEntityOwned(sped)) and PedGetMaxHealth(ped) ~= sped[KEY_MAXHP] then
			PedSetMaxHealth(ped,sped[KEY_MAXHP]) -- set max after since setting health can change max
		end
	end
end)
function F_UpdateDeath(sped,ped)
	if PedIsDead(ped) then
		if not sped[KEY_DEAD] then
			PedSetDead(ped,false)
		end
	elseif sped[KEY_DEAD] then
		PedSetDead(ped,true)
		if PedMePlaying(ped,"DEFAULT_KEY",true) then
			if PedIsModel(ped,136) then
				ForceActionNode(ped,"/GLOBAL/AN_RAT/HITRAT/DEATH/DEAD")
			else
				ForceActionNode(ped,"/GLOBAL/HITTREE/STANDING/POSTHIT/BELLYDOWN/DEAD/KOREACTIONS/WRITHE")
			end
		end
	end
end

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local hp = PedGetHealth(ped)
		local dead = PedIsDead(ped)
		if not server_max_hp then -- only the server is allowed to set maxhp when force is on
			local maxhp = PedGetMaxHealth(ped)
			if sped[KEY_MAXHP] ~= maxhp then
				sped[KEY_MAXHP] = maxhp
			end
		end
		if sped[KEY_HP] ~= hp then
			sped[KEY_HP] = hp
		end
		if sped[KEY_DEAD] ~= dead and (not dead or not sped[KEY_INVULNERABLE]) then
			sped[KEY_DEAD] = dead
		end
	end
end)
