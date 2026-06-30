function main()
	local persist = GetPersistentDataTable("Xx_Yubari_xX") -- .volume = {...}
	local volume = {[0]="cutscene","music","speech","ambient","effects","unknown"}
	local saved = {}
	local save
	if not persist.volume then
		persist.volume = {}
	end
	persist = persist.volume
	for i,k in pairs(volume) do
		if not persist[k] then
			persist[k] = GetVolumeSetting(i)
		end
		SetVolumeSetting(i,persist[k])
		saved[i] = persist[k]
	end
	while true do
		for i,k in pairs(volume) do
			local v = GetVolumeSetting(i)
			if v ~= saved[i] then
				persist[k] = v
				saved[i] = v
				if save then
					TerminateThread(save)
				end
				save = CreateThread(function()
					Wait(10000) -- give a moment in case the player changes more settings
					SavePersistentDataTables()
					save = nil
				end)
			end
		end
		Wait(0)
	end
end
