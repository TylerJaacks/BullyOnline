local gNews

RegisterLocalEventHandler("PlayerListing",function(player,listing)
	if not gNews then
		local f,size = OpenFile("news.txt","rb")
		gNews = ReadFile(f,size)
		CloseFile(f)
	end
	listing.news = gNews
end)
