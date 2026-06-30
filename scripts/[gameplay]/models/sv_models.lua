LoadScript("characters.lua")

SWITCH_DELAY_HOURS = 6
FORCE_RESET_SAVES = false

gPlayers = {}

RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterLocalEventHandler("spawner:Spawned",function(player)
	local data = F_GetPlayer(player)
	if data then
		if not data.save.picked and not data.picker then
			F_StartPicker(player,data,true)
		end
		SetSyncEntityModel(GetSyncPlayerPed(player),data.model)
	end
end)
RegisterLocalEventHandler("spawner:Respawned",function(player)
	local data = F_GetPlayer(player)
	if data and RunLocalEvent("models:SwitchModel",player) then
		SetSyncEntityModel(GetSyncPlayerPed(player),data.model)
	end
end)

RegisterNetworkEventHandler("models:StartScript",function(player)
	local data = F_GetPlayer(player)
	if data then
		if data.admin then
			SendNetworkEvent(player,"models:AllowCommands")
		end
		SetSyncEntityModel(GetSyncPlayerPed(player),data.model)
	end
end)
RegisterNetworkEventHandler("models:ResetDelay",function(player,id)
	local data = F_GetPlayer(player)
	if data and data.admin and dsl.playtime_tracker then
		if id then
			player = nil
			for v in AllPlayers() do
				if GetPlayerId(v) == id then
					player = v
					break
				end
			end
		end
		if player then
			dsl.playtime_tracker.ClearEvent(player,"switched_character")
		end
	end
end)
RegisterNetworkEventHandler("models:RequestPicker",function(player)
	local data = F_GetPlayer(player)
	if data then
		if not data.picker then
			F_StartPicker(player,data,false)
		end
		SendNetworkEvent(player,"models:StopWaiting")
	end
end)
RegisterNetworkEventHandler("models:BuyCharacter",function(player,id)
	local char = F_GetCharacter(id)
	local data = F_GetPlayer(player)
	if char and data and data.picker and not data.picker.first and not data.save.owned[id] and (not char.locked or data.save.unlocked[id]) and F_SpendMoney(player,char.price*100) then
		data.save.unlocked[id] = true
		data.save.owned[id] = true
		F_SavePlayerData(player)
		SendNetworkEvent(player,"models:BoughtCharacter",id)
	end
end)
RegisterNetworkEventHandler("models:SwitchCharacter",function(player,id)
	local char = F_GetCharacter(id)
	local data = F_GetPlayer(player)
	if char and data and data.picker and not data.picker.hours and (data.save.owned[id] or (char.starter and data.picker.first)) then
		if not data.picker.first then
			dsl.playtime_tracker.MarkEvent(player,"switched_character")
		end
		data.save.character = id
		data.save.variant = char.variants[1].id
		data.save.unlocked[id] = true
		data.save.owned[id] = true
		data.save.picked = true
		data.model = char.variants[1].model
		SetSyncEntityModel(GetSyncPlayerPed(player),data.model)
		F_SavePlayerData(player)
		F_QuitPicker(player,data)
	end
end)
RegisterNetworkEventHandler("models:CancelPicker",function(player)
	local data = F_GetPlayer(player)
	if data.picker and not data.picker.first then
		F_QuitPicker(player,data)
	end
end)

function F_GetPlayer(player)
	if IsPlayerValid(player,false) then
		local data = gPlayers[player]
		if not data then
			local account,save = F_InitSaveData(player)
			data = {
				admin = DoesPlayerHaveRole(player,"admin"),
				account = account,
				save = save,
				model = F_GetCharacterModel(save.character,save.variant) or 70, -- default to constantinos
				-- can also have "picker" and "dimension"
			}
			gPlayers[player] = data
		end
		return data
	end
end
function F_InitSaveData(player)
	local account = true
	local save = GetPlayerAccountTable(player,"models")
	if not save then
		account = false
		save = {}
	end
	if not next(save) or FORCE_RESET_SAVES then
		local starters = {}
		for _,char in ipairs(gCharacters) do
			if char.starter then
				table.insert(starters,char)
			end
		end
		starters = starters[math.random(table.getn(starters))]
		save.character = starters.id
		save.variant = starters.variants[math.random(table.getn(starters.variants))].id
		save.picked = false -- haven't picked a character yet, so do initial pick on spawn
		save.unlocked = {} -- [id] = true for each unlocked character
		save.owned = {} -- [id] = true for each owned character
	end
	for id in pairs(save.owned) do
		save.unlocked[id] = true -- anything owned is also treated as unlocked
	end
	return account,save
end
function F_SavePlayerData(player)
	local data = gPlayers[player]
	if data and data.account and not SavePlayerAccountTable(player) then
		PrintWarning("Failed to save player data.")
	end
end
function F_SpendMoney(player,cents)
	if dsl.inventory then
		return dsl.inventory.SpendPlayerMoney(player,cents)
	end
	return false
end

function F_GetCharacter(id)
	for _,char in ipairs(gCharacters) do
		if char.id == id then
			return char
		end
	end
end
function F_GetCharacterModel(id,v)
	for _,char in ipairs(gCharacters) do
		if char.id == id then
			for _,var in ipairs(char.variants) do
				if var.id == v then
					return var.model
				end
			end
			break
		end
	end
end
function F_GetPickerInfo(player,data,first)
	local passed,hours,minutes
	if not first and dsl.playtime_tracker then
		passed,hours,minutes = dsl.playtime_tracker.PassedEvent(player,"switched_character",SWITCH_DELAY_HOURS,0)
	end
	return {
		initial = data.save.character,
		first = first,
		unlocked = data.save.unlocked, -- it's okay this and owned are references, they're just sent to client
		owned = data.save.owned,
		hours = hours, -- if ~= nil, can't switch (only for buying and browsing)
		minutes = minutes,
	}
end

function F_StartPicker(player,data,first)
	local ped = GetSyncPlayerPed(player)
	data.picker = F_GetPickerInfo(player,data,first)
	data.dimension = CreateSyncDimension("character_selection")
	SetSyncEntityDimension(ped,data.dimension)
	if dsl["sync+"] then
		SetSyncActiveDimension(data.dimension)
		dsl["sync+"].InheritChapter()
	end
	SendNetworkEvent(player,"models:SetPicker",true,data.picker)
	SetSyncEntityPos(ped,-745.79,-531.91,7.93)
end
function F_QuitPicker(player,data)
	local x,y,z,h = 633.89,-89.98,8.42,90
	local angle = math.random() * math.pi * 2
	local dist = math.random() * 1.6
	if not data.picker.first then
		x,y,z,h = 526.21,-59.41,5.30,90
	end
	SendNetworkEvent(player,"models:SetupTransition",0,x-math.sin(angle)*dist,y+math.cos(angle)*dist,z,h)
	SendNetworkEvent(player,"models:SetPicker")
	if IsSyncDimensionValid(data.dimension) then
		DeleteSyncDimension(data.dimension)
	end
	data.dimension = nil
	data.picker = nil
end

function exports.RestoreModel(player)
	local data = F_GetPlayer(player)
	if data then
		SetSyncEntityModel(GetSyncPlayerPed(player),data.model)
	end
end
