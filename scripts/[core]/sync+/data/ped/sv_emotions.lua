-- SYNC+ | ped emotions | Xx_Yubari_xX
--  provides server side sync for ped emotions

LoadScript("data/utility/shared/keys.lua")

local st = GetScriptSharedTable()

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_EMOTIONS then
		if type(value) == "table" then
			for id,emo in pairs(value) do
				if not st.finite(id) or type(emo) ~= "number" or not (emo >= 0 and emo <= 8) then
					return true
				end
			end
			return false
		end
		return true
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	local id = GetSyncEntityId(ped)
	for other in AllSyncPeds() do
		local emotions = other[KEY_EMOTIONS]
		if emotions and emotions[id] then
			emotions[id] = nil
			ped[KEY_EMOTIONS] = emotions
		end
	end
	ped[KEY_EMOTIONS] = {} -- no initial emotions are set by the server
end)

-- initialize:
for ped in AllSyncPeds() do
	ped[KEY_EMOTIONS] = {}
end

-- api:
RegisterFunction("PedGetEmotionTowardsPed",function(ped,target)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif not IsSyncPedValid(target) then
		typerror(2,"ped")
	end
	return ped[KEY_EMOTIONS][GetSyncEntityId(target)] or 3
end)
RegisterFunction("PedSetEmotionTowardsPed",function(ped,target,emotion)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif not IsSyncPedValid(target) then
		typerror(2,"ped")
	elseif type(emotion) ~= "number" or not (emotion >= 0 and emotion <= 8) then
		argerror(3,"invalid emotion")
	end
	ped[KEY_EMOTIONS][GetSyncEntityId(target)] = emotion
end)
