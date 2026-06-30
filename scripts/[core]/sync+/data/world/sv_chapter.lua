-- SYNC+ | chapter | Xx_Yubari_xX
--  provides server side chapter sync

gDimensions = setmetatable({},{__mode = "k"}) -- [dimension] = chapter
gPlayers = {}

-- api
RegisterFunction("ChapterGet",function()
	return gDimensions[GetSyncActiveDimension()] or 0
end)
RegisterFunction("ChapterSet",function(chapter)
	local dimension = GetSyncActiveDimension()
	if type(chapter) ~= "number" then
		typerror(1,"number")
	elseif not (chapter >= 0 and chapter <= 6) then
		argerror(1,"invalid chapter")
	elseif chapter ~= 0 then
		gDimensions[dimension] = math.floor(chapter)
	else
		gDimensions[dimension] = nil
	end
	for player,di in pairs(gPlayers) do
		if di == dimension then
			SendNetworkEvent(player,"sync+:SetChapter",chapter)
		end
	end
end)

-- exports
function exports.InheritChapter()
	local dimension = GetSyncActiveDimension()
	local main = GetSyncMainDimension()
	if dimension ~= main then
		gDimensions[dimension] = gDimensions[main] or 0
		for player,di in pairs(gPlayers) do
			if di == dimension then
				SendNetworkEvent(player,"sync+:SetChapter",gDimensions[dimension])
			end
		end
	end
end

-- players
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterLocalEventHandler("sync:SwapPlayer",function(player,ped)
	if gPlayers[player] then
		F_SetDimension(player,GetSyncEntityDimension(ped))
	end
end)
RegisterLocalEventHandler("sync:SwapDimension",function(ped)
	if IsSyncPedValid(ped) then
		local player = GetSyncPlayerFromPed(ped)
		if gPlayers[player] then
			F_SetDimension(player,GetSyncEntityDimension(ped))
		end
	end
end)
RegisterNetworkEventHandler("sync+:GetChapter",function(player)
	F_SetDimension(player,GetSyncEntityDimension(GetSyncPlayerPed(player)))
end)

-- utility
function F_SetDimension(player,dimension)
	if gPlayers[player] ~= dimension then
		SendNetworkEvent(player,"sync+:SetChapter",gDimensions[dimension] or 0)
		gPlayers[player] = dimension
	end
end
