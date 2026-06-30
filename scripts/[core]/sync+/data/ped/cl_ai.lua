-- SYNC+ | ped ai | Xx_Yubari_xX
--  provides client side ai sync

LoadScript("data/utility/shared/keys.lua")
LoadScript("data/utility/shared/ai.lua")

local peds = setmetatable({},{__mode = "k"}) -- time that a task was set

local check = {} -- used to check if a task is still playing correct
local apply = {} -- used when we need to apply server stuff
local update = {} -- used when we want to update the server

-- utility:
function F_GetPedTreeIndex(ped)
	for index,tree in ipairs(gAiTrees) do
		if PedIsDoingTask(ped,tree[1],true) then
			return index
		end
	end
end
function F_GetPedTaskIndex(ped)
	for index,task in ipairs(gAiTasks) do
		for _,node in ipairs(task.nodes) do
			if PedIsDoingTask(ped,node,true) then
				return index
			end
		end
	end
end
function F_ShouldUpdateTask(ped,sped,index)
	if F_GetPedTaskIndex(ped) == sped[KEY_AI_TASK] then
		local func = check[gAiTasks[sped[KEY_AI_TASK]].id]
		if func then
			return not func(ped,sped)
		end
		return false
	end
	return true
end

-- apply:
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	if PedIsValid(ped) then
		local tree = gAiTrees[sped[KEY_AI_TREE]]
		if WasSyncEntityUpdated(sped,KEY_AI_TREE) or (not IsSyncEntityOwned(sped) and not PedIsDoingTask(ped,tree[1],true)) then
			PedSetAITree(ped,unpack(tree))
		end
		if WasSyncEntityUpdated(sped,KEY_AI_TASK) or (not IsSyncEntityOwned(sped) and F_ShouldUpdateTask(ped,sped,sped[KEY_AI_TASK])) then
			PedClearObjectives(ped) -- actual task queue is managed by the server, on the client only one task is set at a time
			if sped[KEY_AI_VALID] then
				local id = gAiTasks[sped[KEY_AI_TASK]].id
				if ped ~= gPlayer or (id ~= "IDLE" and id ~= "WANDER") then
					-- only play tasks on the player that aren't idle / wander
					peds[sped] = GetAccurateTimer() -- prevents the client from updating the task for a moment
					apply[id](ped,sped,sped[KEY_AI_TASK])
				end
			elseif ped ~= gPlayer then
				PedStop(ped) -- if the task is invalid, just go idle
			end
		end
	end
end)

-- check callbacks (optional, returns if a task is still playing correctly):
function check.ATTACK(ped,sped)
	local target = PedGetTargetPed(ped)
	return not PedIsValid(target) or target == PedFromSyncId(sped[KEY_AI_TARGET])
end

-- apply callbacks (required, applies the task if it needs to be applied):
function apply.IDLE(ped,sped,index)
	PedStop(ped)
end
function apply.WANDER(ped,sped,index)
	if IsSyncEntityOwned(sped) then
		PedWander(ped)
	elseif index ~= TASK.IDLE then
		PedStop(ped) -- wander is just idle if not owned
	end
end
function apply.ATTACK(ped,sped,index)
	local victim = PedFromSyncId(sped[KEY_AI_TARGET])
	if PedIsValid(victim) and victim ~= ped then
		local priority = math.floor(sped[KEY_AI_ARG])
		if priority >= 1 and priority <= 3 then
			PedAttack(ped,victim,priority)
		else
			PedAttack(ped,victim,1)
		end
	elseif index ~= TASK.IDLE then
		PedStop(ped) -- if we can't attack just idle i guess
	end
end
function apply.FLEE(ped,sped,index)
	local from = PedFromSyncId(sped[KEY_AI_TARGET])
	if PedIsValid(from) and from ~= ped then
		PedFlee(ped,from)
	else
		PedFlee(ped,gPlayer) -- at least run away from someone i guess lol
	end
end
function apply.MOVE_XYZ(ped,sped,index)
	-- speed is interpreted in a switch with a safe default, so it's fine for us to not check it
	PedMoveToXYZ(ped,sped[KEY_AI_ARG],table.unpack(sped[KEY_AI_XYZ]))
end
function apply.FACE_HEADING(ped,sped,index)
	PedFaceHeading(ped,sped[KEY_AI_ARG],1)
end

-- update:
RegisterLocalEventHandler("sync:PostUpdatePed",function(sped)
	local ped = PedFromSyncPed(sped)
	local delay = peds[sped]
	if delay and GetAccurateTimer() - delay >= 1000 then
		peds[sped] = nil
		delay = nil
	end
	if PedIsValid(ped) then
		local tree = F_GetPedTreeIndex(ped)
		local task = F_GetPedTaskIndex(ped)
		if tree and tree ~= sped[KEY_AI_TREE] then
			sped[KEY_AI_TREE] = tree
		end
		if task then
			if not delay then -- wait a moment since we just set a task from the server
				update[gAiTasks[task].id](ped,sped,task)
			end
		elseif PedIsDoingTask(ped,"/GLOBAL/AI/CONTROLLER",true) and sped[KEY_AI_TASK] ~= TASK.IDLE then
			sped[KEY_AI_TASK] = TASK.IDLE -- tell the server a ped is idle if they're being locally controlled
			sped[KEY_AI_VALID] = true
		end
	end
end)

-- update callbacks (required, updates the ped data fields if needed):
function update.IDLE(ped,sped,index)
	if sped[KEY_AI_TASK] ~= index then
		sped[KEY_AI_TASK] = index
		sped[KEY_AI_VALID] = true
	end
end
function update.WANDER(ped,sped,index)
	if sped[KEY_AI_TASK] ~= index then
		sped[KEY_AI_TASK] = index
		sped[KEY_AI_VALID] = true
	end
end
function update.ATTACK(ped,sped,index)
	local target = PedGetTargetPed(ped)
	if PedIsValid(target) then
		target = PedGetSyncPed(target)
		if target then
			local id = GetSyncEntityId(target)
			if sped[KEY_AI_TASK] ~= index or sped[KEY_AI_TARGET] ~= id then
				-- update if the task is different *or* the target changed
				sped[KEY_AI_TASK] = index
				sped[KEY_AI_VALID] = true
				sped[KEY_AI_TARGET] = id
				sped[KEY_AI_ARG] = 1
			end
		end
	end
	-- if the target isn't valid no task is set, hopefully they'll be valid soon
end
function update.FLEE(ped,sped,index)
	if sped[KEY_AI_TASK] ~= index then
		sped[KEY_AI_TASK] = index
		sped[KEY_AI_TARGET] = -1
	end
end
function update.MOVE_XYZ(ped,sped,index)
	if sped[KEY_AI_TASK] ~= index then
		sped[KEY_AI_TASK] = index
		sped[KEY_AI_VALID] = false
	end
end
function update.FACE_HEADING(ped,sped,index)
	if sped[KEY_AI_TASK] ~= index then
		sped[KEY_AI_TASK] = index
		sped[KEY_AI_VALID] = false
	end
end
