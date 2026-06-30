RegisterLocalEventHandler("PlayerListing",function(player,listing)
	listing.info = "Server is in whitelist-only mode."
end)
RegisterLocalEventHandler("PlayerConnecting",function(player)
	for role in AllConfigStrings(GetScriptConfig(),"allow_role") do
		if DoesPlayerHaveRole(player,role) then
			return
		end
	end
	KickPlayer(player,"You are not allowed on this server.")
end)
