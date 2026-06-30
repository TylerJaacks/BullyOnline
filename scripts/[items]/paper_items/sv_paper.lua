TEXT_LIMIT = GetConfigNumber(GetScriptConfig(),"max_length",560)

RegisterLocalEventHandler("inventory:Use",function(player,id,str)
	if id == "written_paper" then
		SendNetworkEvent(player,"paper_items:ReadPaper",str)
	elseif id == "note_v1rel" then
		SendNetworkEvent(player,"paper_items:ReadRelease")
	end
end)
RegisterNetworkEventHandler("paper_items:WritePaper",function(player,id,slot,text)
	if dsl.inventory and id == "blank_paper" and type(text) == "string" and string.find(text,"%S") and not string.find(text,"\t") then
		local length = utf8.len(text)
		if length and length <= TEXT_LIMIT then
			local author
			if IsPlayerSignedIn(player) then
				author = GetPlayerName(player)
			end
			if dsl.inventory.RemoveItemFromPlayer(player,id,1,slot) > 0 and dsl.inventory.GiveUniqueItemToPlayer(player,"written_paper",text,author) < 1 then
				dsl.inventory.GiveItemToPlayer(player,id,1)
			end
		end
	end
end)
