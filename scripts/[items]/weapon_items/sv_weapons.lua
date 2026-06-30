-- JUST THE SKATEBOARD FOR NOW BECAUSE WE'RE IN A RUSH

gPlayers = {}
gItems = {
	skateboard = 437,
}

RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterLocalEventHandler("inventory:Update",function(player)
	if gPlayers[player] then
		F_UpdatePlayer(player)
	end
end)
RegisterNetworkEventHandler("weapon_items:StartScript",function(player)
	gPlayers[player] = {}
	SendNetworkEvent(player,"weapon_items:ClearWeapons")
	F_UpdatePlayer(player)
end)

function F_UpdatePlayer(player)
	local weapons = gPlayers[player]
	if dsl.inventory then
		local updates = {}
		for id,weapon in pairs(gItems) do
			local count = dsl.inventory.GetPlayerItemCount(player,id)
			if weapons[weapon] ~= count then
				weapons[weapon] = count
				updates[weapon] = count
			end
		end
		if next(updates) then
			SendNetworkEvent(player,"weapon_items:UpdateWeapons",updates)
		end
	elseif next(weapons) then
		SendNetworkEvent(player,"weapon_items:ClearWeapons")
		gPlayers[player] = {}
	end
end
