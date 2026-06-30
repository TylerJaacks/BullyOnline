gArchives = {act="Act.img",cuts="Cuts.img",trigger="Trigger.img",ide="ide.img",scripts="Scripts.img",world="World.img"}
gHashes = {archive = {}}

function main()
	local cfg = GetScriptConfig()
	for what in pairs(gArchives) do
		local str = GetConfigString(cfg,"check_"..what.."_img")
		if str then
			gHashes.archive[what] = ObjectNameToHashID("#"..str)
		end
	end
	if GetConfigBoolean(cfg,"check_custom_scripts") then
		local hashes = {}
		for what in AllConfigStrings(cfg,"allow_custom_script") do
			hashes[ObjectNameToHashID("#"..what)] = true
		end
		gHashes.custom = hashes
	end
	if GetConfigBoolean(cfg,"only_allow_launcher",false) then
		RegisterLocalEventHandler("PlayerListing",CB_PlayerListing)
		RegisterLocalEventHandler("PlayerConnecting",CB_PlayerConnecting)
	end
	if next(gHashes.archive) or gHashes.custom then
		RegisterLocalEventHandler("PlayerConnected",CB_PlayerConnected)
	end
end
function CB_PlayerListing(player,listing)
	if not DidPlayerUseLauncher(player) then
		listing.info = "You can only join this server through the launcher."
	end
end
function CB_PlayerConnecting(player)
	if not DidPlayerUseLauncher(player) then
		KickPlayer(player,"You must join this server through the launcher.")
	end
end
function CB_PlayerConnected(player,hashes)
	for what,hash in pairs(gHashes.archive) do
		if hash ~= hashes[what] then
			KickPlayer(player,string.format(GetConfigString(GetScriptConfig(),"kick_for_archive","modified %s"),gArchives[what]))
			return
		end
	end
	if gHashes.custom then
		for _,v in ipairs(hashes) do
			if not gHashes.custom[v.hash] then
				KickPlayer(player,string.format(GetConfigString(GetScriptConfig(),"kick_for_custom","unallowed %s"),v.name))
				return
			end
		end
	end
end
