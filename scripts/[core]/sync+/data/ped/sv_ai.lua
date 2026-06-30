-- SYNC+ | ped ai | Xx_Yubari_xX
--  provides server side ai sync

LoadScript("data/utility/shared/keys.lua")
LoadScript("data/utility/shared/ai.lua")

local st = GetScriptSharedTable()
local peds = setmetatable({},{__mode = "k"})

local force_player_ai = GetConfigBoolean(GetScriptConfig(),"force_player_ai",false)

-- utility:
function F_GetData(ped)
	local data = peds[ped]
	if not data then
		if not IsSyncPedValid(ped) then
			return nil -- api functions should now call typerror
		end
		data = {default = TASK.IDLE,queue = {}}
		peds[ped] = data
	end
	return data
end
function F_SetTask(ped,set)
	for k,v in pairs(set) do
		ped[k] = v
	end
	ped[KEY_AI_VALID] = true
end
function F_AddTask(ped,set)
	local id = gAiTasks[ped[KEY_AI_TASK]].id
	if id == "IDLE" or id == "WANDER" then
		F_SetTask(ped,set)
	else
		table.insert(F_GetData(ped).queue,set)
	end
end
function F_ConvertNode(convert)
	local result = ""
	for str in string.gfind(convert,"/([^/]+)") do
		result = result.."/"..GetHashString(ObjectNameToHashID(str)) -- forces into #XXXXXXXX
	end
	return result
end
function F_GetTreeIndex(tree)
	for i,v in ipairs(gAiTrees) do
		if v[1] == tree then
			return i
		end
	end
	error("unsupported ai tree",2)
end

-- events:
RegisterLocalEventHandler("sync:PreUpdatePed",function(ped)
	local id = gAiTasks[ped[KEY_AI_TASK]].id
	if force_player_ai then -- force PlayerAI on players
		local index = F_GetTreeIndex("/GLOBAL/PLAYERAI")
		if GetSyncPlayerFromPed(ped) then
			if ped[KEY_AI_TREE] ~= index then
				ped[KEY_AI_TREE] = index
			end
		elseif ped[KEY_AI_TREE] == index then
			ped[KEY_AI_TREE] = F_GetTreeIndex("/GLOBAL/AI")
		end
	end
	if id == "IDLE" or id == "WANDER" then -- update task queue since we're a default task
		local data = F_GetData(ped)
		if data and data.queue[1] then
			F_SetTask(ped,table.remove(data.queue,1))
		elseif ped[KEY_AI_TASK] ~= data.default then
			ped[KEY_AI_TASK] = data.default
		end
	end
end)
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_AI_TREE then
		return not gAiTrees[value]
	elseif key == KEY_AI_TASK then
		return not gAiTasks[value]
	elseif key == KEY_AI_VALID then
		return type(value) ~= "boolean"
	elseif key == KEY_AI_TARGET then
		return not st.finite(value)
	elseif key == KEY_AI_XYZ then
		return true -- no tasks using xyz are supported from the client right now
	elseif key == KEY_AI_ARG then
		return not st.finite(value)
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	local id = GetSyncEntityId(ped)
	for other in AllSyncPeds() do
		if other[KEY_AI_TARGET] == id then
			other[KEY_AI_TARGET] = -1 -- clear targets set to this new ped's id
		end
	end
	F_InitPed(ped)
end)
RegisterLocalEventHandler("sync:CreatePlayer",function(player,ped)
	ped[KEY_AI_TREE] = F_GetTreeIndex("/GLOBAL/PLAYERAI")
end)

-- initialize:
function F_InitPed(ped)
	ped[KEY_AI_TREE] = F_GetTreeIndex("/GLOBAL/AI")
	ped[KEY_AI_TASK] = TASK.IDLE
	ped[KEY_AI_VALID] = true -- if false, the task doesn't have enough info to be reset by the client if not playing on a ped
	ped[KEY_AI_TARGET] = -1 -- for tasks that have a target (like attack or flee)
	ped[KEY_AI_XYZ] = {0,0,0} -- for tasks that have a position (like move)
	ped[KEY_AI_ARG] = 0 -- for tasks that have any other numeric argument
end
for ped in AllSyncPeds() do
	F_InitPed(ped)
	if GetSyncPlayerFromPed(ped) then
		ped[KEY_AI_TREE] = F_GetTreeIndex("/GLOBAL/PLAYERAI")
	end
end

-- api (tasks):
RegisterFunction("PedAttack",function(ped,victim,priority)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif not IsSyncPedValid(victim) then
		typerror(2,"ped")
	elseif type(priority) ~= "number" then
		typerror(3,"number")
	end
	F_AddTask(ped,{[KEY_AI_TASK] = TASK.ATTACK,[KEY_AI_TARGET] = GetSyncEntityId(victim),[KEY_AI_ARG] = priority})
end)
RegisterFunction("PedFaceHeading",function(ped,heading,task) -- task is optional, and is zero to set instantly or non-zero to use a task
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(heading) ~= "number" then
		typerror(2,"number")
	elseif task ~= nil and type(task) ~= "number" then
		typerror(3,"number")
	elseif not task or task == 0 then
		local x,y,z = GetSyncEntityPos(ped)
		SetSyncEntityPos(ped,x,y,z,heading)
	else
		F_AddTask(ped,{[KEY_AI_TASK] = TASK.FACE_HEADING,[KEY_AI_ARG] = heading})
	end
end)
RegisterFunction("PedFlee",function(ped,from)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif not IsSyncPedValid(from) then
		typerror(2,"ped")
	end
	F_AddTask(ped,{[KEY_AI_TASK] = TASK.FLEE,[KEY_AI_TARGET] = GetSyncEntityId(from)})
end)
RegisterFunction("PedMoveToXYZ",function(ped,speed,x,y,z)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(speed) ~= "number" then
		typerror(2,"number")
	elseif type(x) ~= "number" then
		typerror(3,"number")
	elseif type(y) ~= "number" then
		typerror(4,"number")
	elseif type(z) ~= "number" then
		typerror(5,"number")
	end
	F_AddTask(ped,{[KEY_AI_TASK] = TASK.MOVE_XYZ,[KEY_AI_XYZ] = {x,y,z},[KEY_AI_ARG] = speed})
end)

-- api (query):
RegisterFunction("PedIsInCombat",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return gAiTasks[ped[KEY_AI_TASK]].id == "ATTACK"
end)

-- api (general):
RegisterFunction("PedClearObjective",function(ped)
	local data = F_GetData(ped)
	if not data then
		typerror(1,"ped")
	elseif data.queue[1] then
		F_SetTask(ped,table.remove(data.queue,1))
	else
		ped[KEY_AI_TASK] = data.default
		ped[KEY_AI_VALID] = true
	end
end)
RegisterFunction("PedClearObjectives",function(ped)
	local data = F_GetData(ped)
	if not data then
		typerror(1,"ped")
	end
	data.queue = {} -- clear the queue
	ped[KEY_AI_TASK] = data.default -- and clear current
	ped[KEY_AI_VALID] = true
end)
RegisterFunction("PedGetAITree",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return gAiTrees[ped[KEY_AI_TREE]][1]
end)
RegisterFunction("PedIsDoingTask",function(ped,node,lenient)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(node) ~= "string" then
		typerror(2,"string")
	end
	node = F_ConvertNode(node)
	for _,v in ipairs(gAiTasks[ped[KEY_AI_TASK]].nodes) do
		local check = F_ConvertNode(v)
		if check == node or (lenient and string.find(check,"^"..node)) then
			return string.find(check,"^"..F_ConvertNode(gAiTrees[ped[KEY_AI_TREE]][1]))
		end
	end
	return false
end)
RegisterFunction("PedSetAITree",function(ped,tree)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(tree) ~= "string" then
		typerror(2,"string")
	end
	tree = string.upper(tree)
	for i,v in ipairs(gAiTrees) do
		if v[1] == tree then
			ped[KEY_AI_TREE] = i
			return
		end
	end
	argerror(2,"unsupported ai tree")
end)
RegisterFunction("PedStop",function(ped)
	local data = F_GetData(ped)
	if not data then
		typerror(1,"ped")
	end
	data.queue = {} -- clear the queue
	data.default = TASK.IDLE -- set default to idle
	ped[KEY_AI_TASK] = data.default -- and also set current
	ped[KEY_AI_VALID] = true
end)
RegisterFunction("PedWander",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	F_GetData(ped).default = TASK.WANDER -- set default to wander
end)
