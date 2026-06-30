gLoaded = false
gPlayers = {}

-- player permissions
RegisterNetworkEventHandler("set_chapter:RequestPermission",function(player)
	if DoesPlayerHaveRole(player,"admin") then
		SendNetworkEvent(player,"set_chapter:GivePermission")
		gPlayers[player] = true
	end
end)
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)

-- set chapter (sync+)
RegisterNetworkEventHandler("set_chapter:SetChapter",function(player,chapter)
	if gLoaded and dsl["sync+"] and gPlayers[player] and type(chapter) == "number" and math.floor(chapter) == chapter and chapter >= 0 and chapter <= 6 then
		local file = OpenFile("chapter.txt","wb")
		WriteFile(file,tostring(chapter))
		CloseFile(file)
		ChapterSet(chapter)
	end
end)

-- load chapter
CreateThread(function()
	local file,bytes = OpenFile("chapter.txt","rb")
	local chapter = tonumber(ReadFile(file,bytes))
	CloseFile(file)
	if chapter and dsl["sync+"] then
		ChapterSet(chapter)
	elseif chapter then
		PrintWarning("sync+ isn't available, so the chapter wasn't set")
	else
		PrintWarning("failed to load chapter.txt, so the chapter wasn't set")
	end
	gLoaded = true
end)
