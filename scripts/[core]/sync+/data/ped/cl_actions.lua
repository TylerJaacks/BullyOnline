-- SYNC+ | ped actions | Xx_Yubari_xX
--  provides client side action node / tree sync

LoadScript("data/utility/shared/keys.lua")
LoadScript("data/utility/shared/actions.lua")

local peds = setmetatable({},{__mode = "k"})
local anchored = setmetatable({},{__mode = "k"})

local correct_node_delay = GetConfigNumber(GetScriptConfig(),"correct_node_delay",1000)

-- utility:
function F_GetData(sped)
	local data = peds[sped]
	if not data then
		data = {--[[ node = node, timer = timer, count = count, wrong = timer ]]}
		peds[sped] = data
	end
	return data
end

-- reset when respawned:
RegisterLocalEventHandler("sync:SpawnPed",function(sped)
	peds[sped] = nil
end)

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		if (WasSyncEntityUpdated(sped,KEY_ACT_TREE) or not IsSyncEntityOwned(sped)) and string.upper(PedGetActionTree(ped)) ~= sped[KEY_ACT_TREE] and not sped[KEY_DEAD] then
			-- i was going to make a system to load trees in seperate virtual scripts, but in my testing it's never needed
			-- the limit is 50 action trees loaded (by any function) per script object, but they only use space if not already loaded
			PedSetActionTree(ped,sped[KEY_ACT_TREE],F_GetTreeFile(sped[KEY_ACT_TREE]) or "")
		end
		if WasSyncEntityUpdated(sped,KEY_ACT_NODE) or not IsSyncEntityOwned(sped) then
			local node = PedGetActionNode(ped)
			local data = F_GetData(sped)
			data.node = sped[KEY_ACT_NODE]
			data.timer = sped[KEY_ACT_TIMER]
			if node ~= sped[KEY_ACT_NODE] then
				if not data.wrong then
					-- track when we started having the wrong node so we can correct it if needed after a grace period
					data.wrong = GetAccurateTimer()
				end
			elseif data.wrong then
				data.wrong = nil
			end
			if data.count ~= sped[KEY_ACT_COUNT] or (data.wrong and GetAccurateTimer() - data.wrong >= correct_node_delay) then
				-- set a new node on server update *or* count change *or* after being wrong for a while
				if not (string.find(sped[KEY_ACT_NODE],"^/#026A69A7/#58CC3EB9") and PedIsPlaying(ped,sped[KEY_ACT_NODE],true)) and (not PedIsModel(ped,136) or string.find(sped[KEY_ACT_NODE],"^/#026A69A7/#42951BDF")) and RunLocalEvent("sync+:SetAction",ped) then
					-- if we're already playing the node from /Global/HitTree then just count it as predicted
					ForceActionNode(ped,sped[KEY_ACT_NODE])
				end
				data.count = sped[KEY_ACT_COUNT]
				data.wrong = nil
			elseif data.wrong and string.find(node,"^"..sped[KEY_ACT_NODE]) and not string.find(node,"^/#026A69A7/#58CC3EB9") then
				-- playing the right node, but deeper than we want so cut it (unless it's hittree then w/e)
				PedSetActionNodeSimple(ped,"/GLOBAL")
				data.wrong = nil
			elseif data.wrong and PedIsInCombat(ped) and not IsSyncEntityOwned(sped) then
				-- stop ped attacks when not the owner
				for _,pattern in ipairs(gStopAttacks) do
					if string.find(node,pattern) then
						PedSetActionNodeSimple(ped,"/GLOBAL")
						data.wrong = nil
						break
					end
				end
			end
		end
	end
	if PedIsValid(ped) and PedIsAnchored(ped) then
		if not anchored[sped] then
			PauseSyncEntityPos(sped)
			anchored[sped] = true
		end
	elseif anchored[sped] then
		UnpauseSyncEntityPos(sped)
		anchored[sped] = nil
	end
end)

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local data = F_GetData(sped)
		local tree = string.upper(PedGetActionTree(ped))
		local node = PedGetActionNode(ped)
		local timer = PedGetNodeTime(ped)
		if tree ~= sped[KEY_ACT_TREE] and (tree == "" or F_GetTreeFile(tree)) then
			sped[KEY_ACT_TREE] = tree
		end
		if F_IsNodeAllowed(node) then
			if node ~= data.node or timer < data.timer then
				data.node = node
				data.count = math.mod(sped[KEY_ACT_COUNT]+1,1000)
				sped[KEY_ACT_NODE] = node
				sped[KEY_ACT_COUNT] = data.count
			end
			if timer ~= data.timer then
				data.timer = timer
				sped[KEY_ACT_TIMER] = timer
			end
		elseif data.node ~= "/#026A69A7/#26AB0B7D/#0EC298F9" then -- /GLOBAL/SIMPLELOCO/DEFAULT_KEY
			data.node = "/#026A69A7/#26AB0B7D/#0EC298F9"
			data.count = math.mod(sped[KEY_ACT_COUNT]+1,1000)
			data.timer = 0
			sped[KEY_ACT_NODE] = data.node
			sped[KEY_ACT_COUNT] = data.count
			sped[KEY_ACT_TIMER] = data.timer
		end
	end
end)

-- cleanup:
RegisterLocalEventHandler("ScriptShutdown",function(s)
	if s == GetCurrentScript() then
		PedSetActionTree(gPlayer,"","")
	end
end)
