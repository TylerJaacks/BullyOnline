-- SYNC+ | ped actions | Xx_Yubari_xX
--  provides server side action node / tree sync

LoadScript("data/utility/shared/keys.lua")
LoadScript("data/utility/shared/actions.lua")

local st = GetScriptSharedTable()
local peds = setmetatable({},{__mode = "k"})

-- events:
RegisterLocalEventHandler("sync:PreUpdatePed",function(ped)
	-- update _act_timer when a ped is owned by the server *before* scripts run
	if not GetSyncEntityOwner(ped) then
		local timing = peds[ped]
		if not timing then
			timing = {ped[KEY_ACT_TIMER],GetAccurateTimer()}
			peds[ped] = timing
		end
		ped[KEY_ACT_TIMER] = timing[1] + (GetAccurateTimer() - timing[2]) / 1000
	elseif peds[ped] then
		peds[ped] = nil
	end
end)
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_ACT_TREE then
		return type(value) ~= "string" or string.find(value,"[^/%u%d_]") or (value ~= "" and not F_GetTreeFile(value))
	elseif key == KEY_ACT_NODE then
		return type(value) ~= "string" or not F_IsNodeAllowed(value)
	elseif key == KEY_ACT_TIMER or key == KEY_ACT_COUNT then
		return not st.finite(value)
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	F_InitPed(ped)
end)

-- initialize:
function F_InitPed(ped)
	ped[KEY_ACT_TREE] = ""
	ped[KEY_ACT_NODE] = "/#026A69A7" -- /Global
	ped[KEY_ACT_TIMER] = 0
	ped[KEY_ACT_COUNT] = 0
end
for ped in AllSyncPeds() do
	F_InitPed(ped)
end

-- api:
RegisterFunction("PedGetActionNode",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_ACT_NODE]
end)
RegisterFunction("PedGetActionTree",function(ped) -- "" means default
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_ACT_TREE]
end)
RegisterFunction("PedGetNodeTime",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	return ped[KEY_ACT_TIMER]
end)
RegisterFunction("PedIsPlaying",function(ped,node,lenient)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(node) ~= "string" then
		typerror(2,"string")
	end
	node = F_ConvertNode(node)
	if lenient then
		return string.find(ped[KEY_ACT_NODE],"^"..node)
	end
	return ped[KEY_ACT_NODE] == node
end)
RegisterFunction("PedMePlaying",function(ped,node)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(node) ~= "string" then
		typerror(2,"string")
	end
	node = ObjectNameToHashID(node)
	for str in string.gfind(ped[KEY_ACT_NODE],"/([^/]+)") do
		if ObjectNameToHashID(str) == node then
			return true
		end
	end
	return false
end)
RegisterFunction("PedSetActionNode",function(ped,node)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(node) ~= "string" then
		typerror(2,"string")
	end
	ped[KEY_ACT_NODE] = F_ConvertNode(node)
	ped[KEY_ACT_TIMER] = 0
	ped[KEY_ACT_COUNT] = math.mod(ped[KEY_ACT_COUNT]+1,1000)
end)
RegisterFunction("PedSetActionTree",function(ped,tree) -- "" means default
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(tree) ~= "string" then
		typerror(2,"string")
	elseif tree ~= "" and not F_GetTreeFile(tree) then
		argerror(2,"unsupported action tree")
	end
	ped[KEY_ACT_TREE] = tree
	if tree then
		ped[KEY_ACT_NODE] = tree
	else
		ped[KEY_ACT_NODE] = "/#026A69A7" -- /Global
	end
	ped[KEY_ACT_TIMER] = 0
	ped[KEY_ACT_COUNT] = math.mod(ped[KEY_ACT_COUNT]+1,1000)
end)
