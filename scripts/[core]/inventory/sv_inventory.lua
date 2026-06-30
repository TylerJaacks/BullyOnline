LoadScript("items.lua")

MAX_SLOTS = 30
MAX_TOTAL = 0 -- calculated later

gPlayers = {} -- [player] = inv
gStorage = setmetatable({},{__mode = "v"}) -- [id] = inv
gSaved = LoadTable("storage.bin") -- [id] = items

-- player state stuff
RegisterLocalEventHandler("PlayerConnected",function(player)
	if IsPlayerValid(player,false) then
		F_InitPlayer(player)
	end
end)
RegisterLocalEventHandler("PlayerDropped",function(player)
	local inv = gPlayers[player]
	if inv then
		if inv.other then
			inv.other.players[player] = nil
		end
		inv.players[player] = nil
		gPlayers[player] = nil
	end
end)
function F_InitPlayer(player)
	local at = GetPlayerAccountTable(player,"inventory")
	if not at and IsPlayerSignedIn(player) then
		PrintWarning("failed to initialize inventory for "..GetPlayerName(player))
		KickPlayer("The server failed to initialize you.")
		return
	end
	gPlayers[player] = {
		-- some non-inventory state is mixed in the player table
		admin = DoesPlayerHaveRole(player,"admin"),
		players = {}, -- players that must be updated [player] = own
		account = at and player,
		items = at or {},
	}
end

-- normal network events
RegisterNetworkEventHandler("inventory:InitScript",function(player)
	local items = {}
	local inv = gPlayers[player]
	--F_ClearItems(inv)
	for slot,item in pairs(inv.items) do
		items[slot] = item
	end
	if inv.admin then
		SendNetworkEvent(player,"inventory:GiveAdmin")
	end
	SendNetworkEvent(player,"inventory:UpdateInventory",F_GetUpdateTable(items))
	inv.players[player] = true
end)
RegisterNetworkEventHandler("inventory:UseMoney",function(player,count)
	if gItemIndex.money and F_IsCountValid(count) and F_RemoveItems(gPlayers[player],"money",count) < 1 then
		SendNetworkEvent(player,"inventory:UpdateMoney")
	end
end)
RegisterNetworkEventHandler("inventory:CloseOther",function(player)
	if gPlayers[player].other then
		F_SetPlayerOther(player,nil)
	end
end)
RegisterNetworkEventHandler("inventory:TakeItems",function(player,id,slot,count)
	if gItemIndex[id] and F_IsSlotValid(slot) and F_IsCountValid(count) then
		local dest_inv = gPlayers[player]
		local src_inv = dest_inv.other
		if src_inv then
			local item = src_inv.items[slot]
			if item and gItemStats[item.index].id == id then
				count = F_DropItems(src_inv,slot,math.min(item.count,count))
				if count > 0 then
					local unique,unique_sv = item.unique,item.unique_sv
					local added = F_AddItems(dest_inv,id,count,unique,unique_sv)
					if added < count then
						count = count - added
						if F_AddItems(src_inv,id,count,unique,unique_sv) < count then -- try to refund
							PrintWarning("Lost item(s) while trying to take.")
						end
					end
				end
			end
		end
	end
end)
RegisterNetworkEventHandler("inventory:DumpItems",function(player,id,slot,count)
	if gItemIndex[id] and F_IsSlotValid(slot) and F_IsCountValid(count) then
		local src_inv = gPlayers[player]
		local dest_inv = src_inv.other
		if dest_inv then
			local item = src_inv.items[slot]
			if item and gItemStats[item.index].id == id then
				count = F_DropItems(src_inv,slot,math.min(item.count,count))
				if count > 0 then
					local unique,unique_sv = item.unique,item.unique_sv
					local added = F_AddItems(dest_inv,id,count,unique,unique_sv)
					if added < count then
						count = count - added
						if F_AddItems(src_inv,id,count,unique,unique_sv) < count then -- try to refund
							PrintWarning("Lost item(s) while trying to dump.")
						end
					end
				end
			end
		end
	end
end)
RegisterNetworkEventHandler("inventory:MoveItem",function(player,dest,src)
	if type(dest) == "table" and type(src) == "table" and F_IsSlotValid(dest.slot) and F_IsSlotValid(src.slot) then
		local inv = gPlayers[player]
		if inv.other or not (dest.side or src.side) then -- verify other side still exists if needed
			local dinv = dest.side and inv.other or inv
			local sinv = src.side and inv.other or inv
			local ditem = dinv.items[dest.slot]
			local sitem = sinv.items[src.slot]
			if sitem and sitem.index == src.index and (ditem and ditem.index) == dest.index then -- verify no affected slots changed
				if ditem then
					if ditem ~= sitem and src.count == nil then -- ensure a valid merge or swap was intended
						if ditem.index == sitem.index and gItemStats[ditem.index].max_count > 1 then
							F_MergeItems(dinv,dest.slot,sinv,src.slot)
						else
							F_SwapItems(dinv,dest.slot,sinv,src.slot)
						end
					end
				elseif F_IsCountValid(src.count) and src.count < sitem.count then
					F_SplitItem(dinv,dest.slot,sinv,src.slot,src.count)
				else
					F_MoveItem(dinv,dest.slot,sinv,src.slot)
				end
			end
		end
	end
end)
RegisterNetworkEventHandler("inventory:GiveItem",function(player,ped,id,slot,count)
	if (ped == nil or IsSyncPedValid(ped)) and gItemIndex[id] and F_IsSlotValid(slot) and F_IsCountValid(count) then
		local src_inv = gPlayers[player]
		local item = src_inv.items[slot]
		if item and item.count >= count and gItemStats[item.index].id == id then
			if ped and F_ArePedsNearby(GetSyncPlayerPed(player),ped) and F_DropItems(src_inv,slot,count) > 0 then
				local gifted = GetSyncPlayerFromPed(ped)
				local dest_inv = gPlayers[gifted]
				if dest_inv then
					local unique,unique_sv = item.unique,item.unique_sv
					local given = F_AddItems(dest_inv,id,count,unique,unique_sv)
					if given > 0 then
						SendNetworkEvent(gifted,"inventory:AlertGift",GetPlayerName(player),item.index,given)
					else
						SendNetworkEvent(player,"inventory:DenyGift",GetPlayerName(gifted))
					end
					if given < count then
						count = count - given
						if F_AddItems(src_inv,id,count,unique,unique_sv) < count then -- try to refund
							PrintWarning("Lost item(s) while trying to gift.")
						end
					end
				end
			end
		end
	end
end)
RegisterNetworkEventHandler("inventory:UseItem",function(player,id,slot)
	if gItemIndex[id] and F_IsSlotValid(slot) then
		local inv = gPlayers[player]
		local item = inv.items[slot]
		if item then
			local stats = gItemStats[item.index]
			if stats.use_cost < 1 or (item.count >= stats.use_cost and F_DropItems(inv,slot,stats.use_cost) > 0) then
				RunLocalEvent("inventory:Use",player,id,item.unique,item.unique_sv,slot)
			end
		end
	end
end)

-- admin network events
RegisterNetworkEventHandler("inventory:MeowItem",function(player,id,count)
	local inv = gPlayers[player]
	if inv.admin and gItemIndex[id] and F_IsCountValid(count) and not F_IsItemRestricted(player,id) then
		F_AddItems(inv,id,count)
	end
end)
RegisterNetworkEventHandler("inventory:GiveRandom",function(player)
	local inv = gPlayers[player]
	if inv.admin then
		--F_ClearItems(inv)
		for i = math.random(4,11),1,-1 do
			local stats = gItemStats[math.random(table.getn(gItemStats))]
			if not F_IsItemRestricted(player,stats.id) then
				F_AddItems(inv,stats.id,math.random(stats.max_count))
			end
		end
	end
end)
RegisterNetworkEventHandler("inventory:ClearItems",function(player)
	local inv = gPlayers[player]
	if inv.admin then
		F_ClearItems(inv)
	end
end)
RegisterNetworkEventHandler("inventory:AdminStorage",function(player)
	if gPlayers[player].admin then
		F_SetPlayerOther(player,F_GetStorage("admin"),"Admin Storage")
	end
end)

-- network checking
function F_ArePedsNearby(a,b)
	local x1,y1,z1 = GetSyncEntityPos(a)
	local x2,y2,z2 = GetSyncEntityPos(b)
	local dx,dy,dz = x2-x1,y2-y1,z2-z1
	return dx*dx+dy*dy+dz*dz < 20*20
end
function F_IsItemRestricted(player,id)
	if GetPlayerIp(player) ~= "127.0.0.1" then
		if id == "tungsten_cube" then
			return not IsPlayerSignedIn(player) or GetPlayerName(player) ~= "Xx_Yubari_xX"
		end
	end
	return false
end
function F_IsCountValid(count)
	return type(count) == "number" and math.floor(count) == count and count >= 1 and count <= MAX_TOTAL
end
function F_IsSlotValid(slot)
	return type(slot) == "number" and math.floor(slot) == slot and slot >= 1 and slot <= MAX_SLOTS
end

-- client items
function F_GetUpdateTable(update)
	local result = {}
	for slot,item in pairs(update) do
		if item then
			item = {count = item.count,index = item.index,unique = item.unique}
		end
		result[slot] = item
	end
	return result
end

-- player stuff
function F_SetPlayerOther(player,other,title)
	local inv = gPlayers[player]
	if inv then
		if inv.other then
			SendNetworkEvent(player,"inventory:ClearInventory",true)
			inv.other.players[player] = nil
			inv.other = nil
		end
		if other then
			SendNetworkEvent(player,"inventory:NameInventory",title)
			SendNetworkEvent(player,"inventory:UpdateInventory",F_GetUpdateTable(other.items),true)
			other.players[player] = false
			inv.other = other
		end
		return true
	end
	return false
end

-- storage stuff
function F_GetStorage(id)
	local inv = gStorage[id]
	if not inv then
		local items = gSaved[id]
		if not items then
			items = {}
			gSaved[id] = items
		end
		inv = {
			id = id,
			players = {},
			storage = true,
			items = items,
		}
		gStorage[id] = inv
	end
	return inv
end
function F_UpdateStorage()
	local save = {}
	for k,v in pairs(gSaved) do
		if next(v) then
			save[k] = v
		end
	end
	return (pcall(SaveTable,"storage.bin",save))
end

-- inventory utility
function F_FindItem(inv,index)
	local items = inv.items
	for slot = 1,MAX_SLOTS do
		local item = items[slot]
		if item and item.index == index then
			return item
		end
	end
end
function F_FindOrAddItem(inv,index)
	local items = inv.items
	local stats = gItemStats[index]
	for slot = 1,MAX_SLOTS do
		local item = items[slot]
		if item and item.index == index then
			if item.count < stats.max_count then
				return item,slot
			elseif not stats.can_have_multiple then
				return
			end
		end
	end
	for slot = 1,MAX_SLOTS do
		if not items[slot] then
			local item = {count = 0,index = index} -- ITEMS CREATED HERE (but can be "duplicated" in F_SplitItem)
			items[slot] = item
			return item,slot
		end
	end
end
function F_UpdateInventory(inv,update)
	if inv.account then
		if not SavePlayerAccountTable(inv.account) then
			return false
		end
	elseif inv.storage and not F_UpdateStorage() then
		return false
	end
	if update then
		for player,own in pairs(inv.players) do
			if own then
				SendNetworkEvent(player,"inventory:UpdateInventory",F_GetUpdateTable(update))
			else
				SendNetworkEvent(player,"inventory:UpdateInventory",F_GetUpdateTable(update),true)
			end
		end
	end
	for player,own in pairs(inv.players) do
		if own then
			RunLocalEvent("inventory:Update",player)
		end
	end
	return true
end

-- inventory core
function F_ClearItems(inv)
	local backup = {}
	local items = inv.items
	local count = 0
	for slot,item in pairs(items) do
		count = count + 1
		items[slot] = nil
		backup[slot] = item
	end
	if count == 0 then
		return 0
	elseif F_UpdateInventory(inv,nil) then
		for k in pairs(backup) do
			backup[k] = false
		end
		for player,own in pairs(inv.players) do
			if own then
				SendNetworkEvent(player,"inventory:ClearInventory",update)
			else
				SendNetworkEvent(player,"inventory:ClearInventory",update,true)
			end
		end
		return count
	end
	for slot,item in pairs(backup) do
		items[slot] = item
	end
	return 0
end
function F_AddItems(inv,id,count,data,sv_data)
	local update = {}
	local backup = {}
	local started = count
	local index = gItemIndex[id]
	local max_count = gItemStats[index].max_count
	local item,slot = F_FindOrAddItem(inv,index)
	while item do
		local adding = math.min(count,max_count-item.count)
		if max_count == 1 then -- attach unique data
			item.unique = data
			item.unique_sv = sv_data
		end
		backup[slot] = item.count
		item.count = item.count + adding
		update[slot] = item
		count = count - adding
		if count < 1 then
			break
		end
		item,slot = F_FindOrAddItem(inv,index)
	end
	if count == started then
		return 0 -- items given
	else
		if F_UpdateInventory(inv,update) then
			return started - count -- items given
		end
	end
	for slot,count in pairs(backup) do -- restore backup if it couldn't save
		if count > 0 then
			inv.items[slot].count = count
		else
			inv.items[slot] = nil
		end
	end
	return 0 -- items given
end
function F_RemoveItems(inv,id,count)
	local update = {}
	local backup_counts = {}
	local backup_items = {}
	local started = count
	local index = gItemIndex[id]
	local items = inv.items
	while count > 0 do
		local none = true
		for slot = MAX_SLOTS,1,-1 do
			local item = items[slot]
			if item and item.index == index then
				none = false
				if item.count > count then
					backup_counts[item] = item.count
					item.count = item.count - count
					update[slot] = item
					count = 0
					break
				end
				backup_items[slot] = item
				items[slot] = nil
				update[slot] = false
				count = count - item.count
			end
		end
		if none then
			break
		end
	end
	if count == started then
		return 0
	elseif F_UpdateInventory(inv,update) then
		return started - count -- items removed
	end
	for item,count in pairs(backup_counts) do
		item.count = count
	end
	for slot,item in pairs(backup_items) do
		items[slot] = item
	end
	return 0 -- items removed
end
function F_MoveItem(dest_inv,dest_slot,src_inv,src_slot)
	local item = src_inv.items[src_slot]
	if item and not dest_inv.items[dest_slot] and (dest_inv == src_inv or gItemStats[item.index].can_have_multiple or not F_FindItem(dest_inv,item.index)) then
		dest_inv.items[dest_slot] = item
		src_inv.items[src_slot] = nil
		if dest_inv == src_inv then
			if F_UpdateInventory(dest_inv,{[dest_slot] = item,[src_slot] = false}) then
				return true -- success
			end
		elseif F_UpdateInventory(src_inv,{[src_slot] = false}) then
			if F_UpdateInventory(dest_inv,{[dest_slot] = item}) then
				return true -- success
			end
			dest_inv.items[dest_slot] = nil -- we failed to update dest_inv, so revert
			src_inv.items[src_slot] = item
			if F_UpdateInventory(src_inv,{[src_slot] = false}) then -- try to revert since dest failed to save
				return false -- failure
			end
			src_inv.items[src_slot] = nil -- we failed to update src_inv, so revert
			PrintWarning("Lost item(s) while trying to move.")
			return false -- critical
		end
		dest_inv.items[dest_slot] = nil
		src_inv.items[src_slot] = item
	end
	return false -- failure
end
function F_SplitItem(dest_inv,dest_slot,src_inv,src_slot,count)
	local sitem = src_inv.items[src_slot]
	if sitem and not dest_inv.items[dest_slot] and (gItemStats[sitem.index].can_have_multiple or (dest_inv ~= src_inv and not F_Item(dest_inv,sitem.index))) and sitem.count > count then
		local ditem = {count = count,index = sitem.index} -- only splitable if more than 1, so unique items cannot be broke
		dest_inv.items[dest_slot] = ditem
		sitem.count = sitem.count - count
		if dest_inv == src_inv then
			if F_UpdateInventory(dest_inv,{[dest_slot] = ditem,[src_slot] = sitem}) then
				return true -- success
			end
		elseif F_UpdateInventory(src_inv,{[src_slot] = sitem}) then
			if F_UpdateInventory(dest_inv,{[dest_slot] = ditem}) then
				return true -- success
			end
			dest_inv.items[dest_slot] = nil
			sitem.count = sitem.count + count
			if F_UpdateInventory(src_inv,{[src_slot] = sitem}) then
				return false -- failure
			end
			sitem.count = sitem.count - count
			PrintWarning("Lost item(s) while trying to split.")
			return false -- critical
		end
		dest_inv.items[dest_slot] = nil
		sitem.count = sitem.count + count
	end
	return false -- failure
end
function F_SwapItems(dest_inv,dest_slot,src_inv,src_slot)
	local ditem = dest_inv.items[dest_slot]
	local sitem = src_inv.items[src_slot]
	if ditem and sitem then
		dest_inv.items[dest_slot] = sitem
		src_inv.items[src_slot] = ditem
		if dest_inv == src_inv then
			if F_UpdateInventory(dest_inv,{[dest_slot] = sitem,[src_slot] = ditem}) then
				return true -- success, only affected one inventory
			end
		elseif F_UpdateInventory(src_inv,{[src_slot] = ditem}) then
			if F_UpdateInventory(dest_inv,{[dest_slot] = sitem}) then
				return true -- success, updated both inventories
			end
			dest_inv.items[dest_slot] = ditem
			src_inv.items[src_slot] = sitem
			if F_UpdateInventory(src_inv,{[src_slot] = sitem}) then
				return false -- failure
			end
			src_inv.items[src_slot] = ditem
			PrintWarning("Lost item(s) and duplicated other item(s) while trying to swap.")
			return false -- critical
		end
		dest_inv.items[dest_slot] = ditem
		src_inv.items[src_slot] = sitem
	end
	return false -- failure
end
function F_MergeItems(dest_inv,dest_slot,src_inv,src_slot)
	local ditem = dest_inv.items[dest_slot]
	local sitem = src_inv.items[src_slot]
	if ditem and sitem and ditem.index == sitem.index then
		local count = math.min(sitem.count,gItemStats[ditem.index].max_count-ditem.count)
		if count < 1 then -- only can be merged if max_count is more than 1, so unique items cannot be merged
			return 0 -- failure?
		end
		ditem.count = ditem.count + count
		if sitem.count > count then
			sitem.count = sitem.count - count
		else
			src_inv.items[src_slot] = nil
			sitem = false
		end
		if dest_inv == src_inv then
			if F_UpdateInventory(dest_inv,{[dest_slot] = ditem,[src_slot] = sitem}) then
				return count -- success
			end
		elseif F_UpdateInventory(src_inv,{[src_slot] = sitem}) then
			if F_UpdateInventory(dest_inv,{[dest_slot] = ditem}) then
				return count -- success
			end
			ditem.count = ditem.count - count
			if sitem then
				sitem.count = sitem.count + count
			else
				sitem = {count = count,index = ditem.index}
				src_inv.items[src_slot] = sitem
			end
			if F_UpdateInventory(src_inv,{[src_slot] = sitem}) then
				return 0 -- failure
			end
			if sitem.count > count then
				sitem.count = sitem.count - count
			else
				src_inv.items[src_slot] = nil
				sitem = false
			end
			PrintWarning("Lost item(s) while trying to merge.")
			return 0 -- critical
		end
		ditem.count = ditem.count - count
		if sitem then
			sitem.count = sitem.count + count
		else
			sitem = {count = count,index = ditem.index}
			src_inv.items[src_slot] = sitem
		end
	end
	return 0 -- failure
end
function F_DropItems(inv,slot,count)
	local item = inv.items[slot]
	if item then
		local backup
		count = math.min(item.count,count)
		if count < 1 then
			return 0
		end
		if item.count > count then
			item.count = item.count - count
		else
			inv.items[slot] = nil
			backup = item
			item = false
		end
		if F_UpdateInventory(inv,{[slot] = item}) then
			return count
		end
		if item then
			item.count = item.count + count
		else
			inv.items[slot] = backup
			item = backup
		end
	end
	return 0
end
function F_GetItemCount(inv,id)
	local count = 0
	local index = gItemIndex[id]
	for _,item in pairs(inv.items) do
		if item.index == index then
			count = count + item.count
		end
	end
	return count
end
function F_SetItemCount(inv,id,count)
	count = count - F_GetItemCount(inv,id)
	if count < 0 then
		return -F_RemoveItems(inv,id,-count)
	end
	return F_AddItems(inv,id,count)
end

-- player api
function exports.GiveUniqueItemToPlayer(player,id,data,sv_data)
	local inv = gPlayers[player]
	if inv and gItemIndex[id] and (data == nil or type(data) == "string") and (sv_data == nil or type(sv_data) == "string") then
		return F_AddItems(inv,id,1,data,sv_data)
	end
	return 0
end
function exports.GiveItemToPlayer(player,id,count)
	local inv = gPlayers[player]
	if inv and gItemIndex[id] and type(count) == "number" and count >= 1 then
		return F_AddItems(inv,id,math.floor(count))
	end
	return 0
end
function exports.RemoveItemFromPlayer(player,id,count,slot) -- [, slot]
	local inv = gPlayers[player]
	if inv and gItemIndex[id] and type(count) == "number" and count >= 1 then
		if slot == nil then
			return F_RemoveItems(inv,id,math.floor(count))
		elseif F_IsSlotValid(slot) then
			local item = inv.items[slot]
			if item and gItemStats[item.index].id == id then
				return F_DropItems(inv,slot,count)
			end
		end
	end
	return 0
end
function exports.GetPlayerItemData(player,slot) -- returns id, unique, unique_sv
	local inv = gPlayers[player]
	if inv and F_IsSlotValid(slot) then
		local item = inv.items[slot]
		if item then
			return gItemStats[item.index].id,item.unique,item.unique_sv
		end
	end
end
function exports.GetPlayerItemCount(player,id)
	local inv = gPlayers[player]
	if inv and gItemIndex[id] then
		return F_GetItemCount(inv,id)
	end
	return 0
end
function exports.SetPlayerItemCount(player,id,count)
	local inv = gPlayers[player]
	if inv and gItemIndex[id] and type(count) == "number" and count >= 0 then
		return F_SetItemCount(inv,id,math.floor(count))
	end
	return 0
end
function exports.GetPlayerMoney(player)
	local inv = gPlayers[player]
	if inv and gItemIndex.money then
		return F_GetItemCount(inv,"money") * 25
	end
	return 0
end
function exports.SetPlayerMoney(player,money)
	local inv = gPlayers[player]
	if inv and gItemIndex.money and type(money) == "number" and money >= 0 then
		return F_SetItemCount(inv,"money",math.floor(money/25))
	end
	return 0
end
function exports.GetPlayerStorage(player)
	local inv = gPlayers[player]
	return inv and inv.other and inv.other.id
end
function exports.SetPlayerStorage(player,sid,name)
	if type(sid) == "string" or sid == nil then
		if sid then
			return F_SetPlayerOther(player,F_GetStorage(sid),tostring(name))
		end
		return F_SetPlayerOther(player,nil)
	end
	return false
end
function exports.GetPlayerSpace(player)
	local inv = gPlayers[player]
	if inv then
		local count = 0
		for _ in pairs(inv.items) do
			count = count + 1
		end
		return MAX_SLOTS - count
	end
	return 0
end
function exports.RewardPlayerMoney(player,money)
	local inv = gPlayers[player]
	if inv and gItemIndex.money and type(money) == "number" and money >= 0 then
		return F_AddItems(inv,"money",math.floor(money/25)) ~= 0
	end
	return false
end
function exports.SpendPlayerMoney(player,money)
	local inv = gPlayers[player]
	if inv and gItemIndex.money and type(money) == "number" and money >= 0 then
		local count = F_GetItemCount(inv,"money")
		money = math.floor(money/25)
		if count >= money then
			return F_RemoveItems(inv,"money",money) ~= 0
		end
	end
	return false
end

-- storage api
function exports.GiveUniqueItemToStorage(sid,id,data,sv_data)
	local inv = F_GetStorage(sid)
	if inv and gItemIndex[id] and (data == nil or type(data) == "string") and (sv_data == nil or type(sv_data) == "string") then
		return F_AddItems(inv,id,1,data,sv_data)
	end
	return 0
end
function exports.GiveItemToStorage(sid,id,count)
	local inv = F_GetStorage(sid)
	if inv and gItemIndex[id] and type(count) == "number" and count >= 1 then
		return F_AddItems(inv,id,math.floor(count))
	end
	return 0
end
function exports.RemoveItemFromStorage(sid,id,count,slot) -- [, slot]
	local inv = F_GetStorage(sid)
	if inv and gItemIndex[id] and type(count) == "number" and count >= 1 then
		if slot == nil then
			return F_RemoveItems(inv,id,math.floor(count))
		elseif F_IsSlotValid(slot) then
			local item = inv.items[slot]
			if item and gItemStats[item.index].id == id then
				return F_DropItems(inv,slot,count)
			end
		end
	end
	return 0
end
function exports.GetStorageItemData(sid,slot) -- returns id, unique, unique_sv
	local inv = F_GetStorage(sid)
	if inv and F_IsSlotValid(slot) then
		local item = inv.items[slot]
		if item then
			return gItemStats[item.index].id,item.unique,item.unique_sv
		end
	end
end
function exports.GetStorageItemCount(sid,id)
	local inv = F_GetStorage(sid)
	if inv and gItemIndex[id] then
		return F_GetItemCount(inv,id)
	end
	return 0
end
function exports.SetStorageItemCount(sid,id,count)
	local inv = F_GetStorage(sid)
	if inv and gItemIndex[id] and type(count) == "number" and count >= 0 then
		return F_SetItemCount(inv,id,math.floor(count))
	end
	return 0
end
function exports.GetStorageMoney(sid)
	local inv = F_GetStorage(sid)
	if inv and gItemIndex.money then
		return F_GetItemCount(inv,"money") * 25
	end
	return 0
end
function exports.SetStorageMoney(sid,money)
	local inv = F_GetStorage(sid)
	if inv and gItemIndex.money and type(money) == "number" and money >= 0 then
		return F_SetItemCount(inv,"money",math.floor(money/25))
	end
	return 0
end

-- calculate maximum
for _,stats in ipairs(gItemStats) do
	MAX_TOTAL = math.max(MAX_TOTAL,stats.max_count)
end
MAX_TOTAL = MAX_TOTAL * MAX_SLOTS

-- init players
for player in AllPlayers() do
	F_InitPlayer(player)
end
