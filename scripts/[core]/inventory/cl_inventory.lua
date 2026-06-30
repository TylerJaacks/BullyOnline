require("utility/texture")
LoadScript("cl_icons.lua") -- F_PrepareIcon
LoadScript("items.lua")

MAX_SLOTS = 30

gFirstMoney = true
gActive = false
gOpened = false
gGiving = {}
gEquip = {}
gGifts = {}

gPlayerInventory = {items = {},index = 1,title = GetPlayerName(player)}
gOtherInventory = {}

gMoney = 0

gControlTextures = {} -- 3 textures for each of the 3 actions
gControlsRepeat = {} -- which controls are held down and when they'll repeat
gControlsTimer = {} -- which controls are held down and when
gControlsLast = {} -- copy of gControlsNow
gControlsNow = {}

gInputDelay = false -- turn to true after a give control

-- ui metrics
gMetrics = {
	debug = false,
	
	background_color = {49,85,90,230},
	titlebar_color = {24,40,41,230},
	title_color = {249,174,29,255},
	
	x = 0.09, -- x offset from center, adjusted by aspect
	y = 0.2, -- y offset from top
	width = 0.49, -- total width, adjusted by aspect
	height = 0.6, -- total height
	
	titlebar_h = 0.057, -- titlebar height
	title_ratio = 0.59, -- title height compared to titlebar
	title_y = -0.006, -- extra title offset
	
	border_y = -0.005, -- border offset
	border_w = 0.022, -- border width adjustment, adjusted by aspect
	border_h = 0.029, -- border height adjustment
	
	window_padding = 0.01, -- padding on all sides, adjusted by aspect for x
	item_padding = 0.005, -- for each item
	item_columns = 6, -- determines size
	item_rows = 5,
	item_count_ratio = 0.37, -- how much of an item boxes height is used for count text
	money_count_ratio = 0.19, -- seperate ratio just for money items
	item_cursor_color = {0,0,0,100},
	item_moving_color = {255,255,128,100},
	item_cursor_speed = 1.5,
	
	info_height = 0.115,
	info_title_color = {249,174,29,255},
	info_desc_color = {230,230,230,255},
	info_title_ratio = 0.21,
	info_count_ratio = 0.19,
	info_title_y = -0.007,
	info_desc_ratio = 0.16,
	info_desc_y = 0.01,
	
	controls_height = 0.037,
	controls_padding_x = 0.027,
	controls_padding_y = 0.005,
	controls_text_left = 0.002,
	controls_text_right = 0.007,
	controls_text_ratio = 0.7,
	
	quantity_color_a = {49,85,90,230}, -- background
	quantity_color_b = {249,174,29,230}, -- border, lines
	quantity_color_c = {249,174,29,255}, -- cursor
	quantity_width = 0.35, -- adjusted by aspect
	quantity_height = 0.15,
	quantity_thickness = 0.001, -- thickness of the bar
	quantity_edge_size = 0.02, -- the height of vertical lines at the ends of the bars
	quantity_cursor_size = 0.012,
	quantity_border = 0.002, -- applied to all sides outside of width / height
	quantity_padding = 0.02, -- applied to all sides inside width / height
	quantity_text_scale = 0.95, -- text scale, not relative to quantity window
}

-- inventory updates
RegisterNetworkEventHandler("inventory:UpdateInventory",function(update,other) -- update player *or* other inventory
	local items = gPlayerInventory.items
	if other then
		items = gOtherInventory.items
		if not items then
			if dsl.radar then
				dsl.radar.RegisterPanel("INVENTORY",1) -- in case it wasn't registered yet
				dsl.radar.ShowPanel("INVENTORY")
			end
			gOpened = true -- makes a :CloseOther event fire when the radar is closed
			items = {}
			gOtherInventory.items = items
		end
	end
	for slot,item in pairs(update) do
		if item then
			item = {
				count = item.count,
				index = item.index,
				stats = gItemStats[item.index],
				unique = item.unique,
			}
			F_UpdateItemText(item,"name")
			F_UpdateItemText(item,"description")
		end
		items[slot] = item or nil
	end
	if not other then
		F_UpdateMoney(gPlayerInventory)
		F_UpdateItems(gPlayerInventory)
	end
end)
RegisterNetworkEventHandler("inventory:ClearInventory",function(other) -- clear player *or* other inventory
	if not other then
		local items = gPlayerInventory.items
		for slot in pairs(items) do
			items[slot] = nil
		end
		F_UpdateMoney(gPlayerInventory)
		F_UpdateItems(gPlayerInventory)
	else
		gOtherInventory = {} -- when clearing other, also forget everything about it
	end
end)
RegisterNetworkEventHandler("inventory:NameInventory",function(name) -- name other inventory
	gOtherInventory.title = name
end)
RegisterNetworkEventHandler("inventory:UpdateMoney",function()
	F_UpdateMoney(gPlayerInventory)
end)
RegisterNetworkEventHandler("inventory:AlertGift",function(name,index,count)
	local stats = gItemStats[index]
	if stats.id == "money" then
		table.insert(gGifts,name.." gave you "..F_GetMoneyString(count)..".")
	elseif count ~= 1 then
		table.insert(gGifts,name.." gave you "..F_GetCountString(count).." "..stats.name..".")
	elseif ({a=true,e=true,i=true,o=true,u=true})[string.lower(string.sub(stats.name,1,1))] then
		table.insert(gGifts,name.." gave you an "..stats.name..".")
	else
		table.insert(gGifts,name.." gave you a "..stats.name..".")
	end
end)
RegisterNetworkEventHandler("inventory:DenyGift",function(name)
	table.insert(gGifts,name.." couldn't accept your gift.")
end)

-- admin init
RegisterNetworkEventHandler("inventory:GiveAdmin",function()
	RegisterLocalEventHandler("f2menu:Open",function(f_add)
		f_add({
			name = "Inventory Manager",
			description = "(admin only)\nManage your inventory.",
			thread = M_AdminMenu,
		})
	end)
end)

-- disable stuff
RegisterLocalEventHandler("chat:StartTyping",function()
	if gActive then
		return true
	end
end)

-- register panel
RegisterLocalEventHandler("radar:Open",function(f_register)
	f_register("INVENTORY",1)
	F_UnequipItem()
	gGiving = {}
end)

-- cleanup
function MissionCleanup()
	ToggleHUDMoneyVisibility(false)
	F_UnequipItem()
end

-- main
function main()
	local controls
	local selection = {index = 1,right = false} -- other possible values in F_ResetSelection
	SendNetworkEvent("inventory:InitScript")
	CreateThread("T_Money")
	CreateThread("T_Gifts")
	while true do
		local alpha = F_GetAlpha()
		if alpha ~= 0 or gInputDelay or gEquip.index or gGiving.index then
			if alpha ~= 0 and (gEquip.index or gGiving.index) then
				dsl.radar.Close()
			end
			if not controls then
				controls = RegisterLocalEventHandler("ControllerUpdating",CB_ControllerUpdating)
				ToggleHUDMoneyVisibility(true)
				F_SetupControlTextures()
				gActive = true
			elseif gEquip.index then
				local icon = gItemStats[gEquip.index].icon_name
				if icon and icon ~= "none" then
					F_DrawEquipped(icon,255)
				end
			elseif gGiving.index then
				F_UpdateGiving(255)
			elseif alpha ~= 0 then
				if gOtherInventory.items then
					F_UpdateSelection(selection,gPlayerInventory,gOtherInventory)
				else
					F_UpdateSelection(selection,gPlayerInventory)
				end
				if gOtherInventory.items then
					F_DrawInventory(selection,gPlayerInventory,"L",alpha)
					F_DrawInventory(selection,gOtherInventory,"R",alpha)
				else
					F_DrawInventory(selection,gPlayerInventory,"L",alpha)
				end
			end
		elseif controls then
			ToggleHUDMoneyVisibility(false)
			F_ResetSelection(selection,gPlayerInventory,gOtherInventory)
			RemoveEventHandler(controls)
			gControlTextures = {}
			gControlsRepeat = {}
			gControlsTimer = {}
			gControlsLast = {}
			gControlsNow = {}
			gGiving = {}
			F_UnequipItem()
			gActive = false
			controls = nil
		end
		if gOpened and not (dsl.radar and dsl.radar.IsActive()) then
			SendNetworkEvent("inventory:CloseOther")
			gOpened = false
		end
		Wait(0)
	end
end
function F_GetAlpha()
	if dsl.radar then
		return dsl.radar.GetPanelAlpha("INVENTORY") * 255
	end
	return 0
end

-- updates
function F_UpdateItems(inv)
	if gGiving.index then
		local item = inv.items[gGiving.slot]
		if not item or item.index ~= gGiving.index or item.count < gGiving.count then
			F_ReleaseControls()
			gGiving = {}
		end
	end
	if gEquip.index then
		local item = inv.items[gEquip.slot]
		if not item or item.index ~= gEquip.index or item.count < gEquip.count then
			F_UnequipItem()
		end
	end
end

-- money
function T_Money()
	PlayerSetMoney(0)
	while true do
		local money = PlayerGetMoney()
		if money > gMoney then
			PlayerSetMoney(gMoney) -- correct player (they should have less than they do)
		elseif money < gMoney then
			SendNetworkEvent("inventory:UseMoney",math.floor((gMoney-money)/25))
			gMoney = money
		end
		Wait(0)
	end
end
function F_UpdateMoney(inv)
	local money = 0
	for _,item in pairs(inv.items) do
		if item.stats.id == "money" then
			money = money + item.count
		end
	end
	gMoney = money * 25
	money = gMoney - PlayerGetMoney()
	if money ~= 0 then
		if gActive or gFirstMoney then
			PlayerSetMoney(gMoney)
			gFirstMoney = false
		else
			PlayerAddMoney(money)
		end
	end
end

-- alerts
function T_Gifts()
	while true do
		if gGifts[1] then
			local gift = table.remove(gGifts,1)
			TutorialShowString(gift,3000)
			Wait(3000)
		end
		Wait(0)
	end
end

-- controls
function CB_ControllerUpdating(c)
	if c == 0 then
		local t = GetTimer()
		for id,state in pairs(gControlsNow) do
			gControlsLast[id] = state
		end
		if gInputDelay then
			if not IsButtonPressed(7,0) and not IsButtonPressed(8,0) then
				gInputDelay = false
			end
			gControlsNow.left = false
			gControlsNow.right = false
			gControlsNow.up = false
			gControlsNow.down = false
			gControlsNow.move = false
			gControlsNow.use = false
			gControlsNow.cancel = false
			gControlsNow.give = false
			SetButtonPressed(7,0,false)
			SetButtonPressed(8,0,false)
		elseif gGiving.index then
			gControlsNow.left = false
			gControlsNow.right = false
			gControlsNow.up = false
			gControlsNow.down = false
			gControlsNow.move = false
			gControlsNow.use = false
			gControlsNow.cancel = IsButtonPressed(8,0)
			SetButtonPressed(8,0,false)
			gControlsNow.give = IsButtonPressed(7,0)
			SetButtonPressed(7,0,false)
			SetButtonPressed(6,0,false)
			SetButtonPressed(9,0,false)
		elseif gEquip.index then
			gControlsNow.left = false
			gControlsNow.right = false
			gControlsNow.up = false
			gControlsNow.down = false
			gControlsNow.move = false
			gControlsNow.use = false
			gControlsNow.cancel = false
			gControlsNow.give = false
		elseif IsUsingJoystick(0) then
			gControlsNow.left = IsButtonPressed(0,0)
			SetButtonPressed(0,0,false)
			gControlsNow.right = IsButtonPressed(1,0)
			SetButtonPressed(1,0,false)
			gControlsNow.up = IsButtonPressed(2,0)
			SetButtonPressed(2,0,false)
			gControlsNow.down = IsButtonPressed(3,0)
			SetButtonPressed(3,0,false)
			gControlsNow.move = IsButtonPressed(6,0)
			SetButtonPressed(6,0,false)
			gControlsNow.use = IsButtonPressed(7,0)
			SetButtonPressed(7,0,false)
			gControlsNow.cancel = IsButtonPressed(8,0)
			SetButtonPressed(8,0,false)
			gControlsNow.give = IsButtonPressed(9,0)
			SetButtonPressed(9,0,false)
		else
			gControlsNow.left = IsKeyPressed("LEFT")
			SetKeyPressed("LEFT",0,false)
			gControlsNow.right = IsKeyPressed("RIGHT")
			SetKeyPressed("RIGHT",0,false)
			gControlsNow.up = IsKeyPressed("UP")
			SetKeyPressed("UP",0,false)
			gControlsNow.down = IsKeyPressed("DOWN")
			SetKeyPressed("DOWN",0,false)
			gControlsNow.move = IsKeyPressed("F")
			SetKeyPressed("F",0,false)
			gControlsNow.use = IsKeyPressed("RETURN")
			SetKeyPressed("RETURN",0,false)
			gControlsNow.cancel = IsKeyPressed("SPACE")
			SetKeyPressed("SPACE",0,false)
			gControlsNow.give = IsKeyPressed("R")
			SetKeyPressed("R",0,false)
		end
		for _,id in ipairs({"left","right","up","down"}) do
			if gControlsNow[id] then
				if not gControlsRepeat[id] then
					gControlsRepeat[id] = t + 200
					gControlsTimer[id] = t
				elseif t >= gControlsRepeat[id] then
					gControlsRepeat[id] = t + 100
					gControlsLast[id] = nil -- force a new press
				end
			elseif gControlsRepeat[id] then
				gControlsRepeat[id] = nil
				gControlsTimer[id] = nil
			end
		end
	end
end
function F_IsControlPressed(id)
	return gControlsNow[id] and not gControlsLast[id]
end
function F_GetControlPressedScale(id,scale)
	if gControlsNow[id] and not gControlsLast[id] then
		local seconds = (GetTimer() - gControlsTimer[id]) / 1000
		if seconds > 0.5 then
			return 1 + scale * (seconds - 0.5)
		end
		return 1
	end
	return 0
end
function F_ResetSelection(s,inv1,inv2)
	for _,key in ipairs({"moving","giving"}) do
		if inv2 then
			inv2[key] = nil
		end
		inv1[key] = nil
		s[key] = nil
	end
	s.moving_index = nil
	s.moving_split = nil
	s.quantity = nil
	s.quantity_money = nil
	s.quantity_limit = nil
end
function F_UpdateSelection(s,inv1,inv2)
	local sound = s.index -- if index differs, play a sound
	local cols = gMetrics.item_columns
	local rows = gMetrics.item_rows
	if s.right ~= (inv2 ~= nil) then -- LAYOUT CHANGE
		if s.right then
			local r = math.mod(s.index-1,cols*2)
			if r >= cols then
				s.index = s.index - ((r + 1) - cols) -- snap to right column of left panel
			end
			s.index = s.index - math.floor((s.index-1)/(cols*2)) * cols
		else
			s.index = s.index + math.floor((s.index-1)/cols) * cols
		end
		s.right = inv2 ~= nil
		F_ResetSelection(s,inv1,inv2) -- reset stuff like .moving or .quantity
		F_SnapIndex(inv1,inv2)
		F_UpdateIndex(inv1,inv2,s.index,"index")
		sound = s.index
	end
	if inv2 then
		cols = cols * 2
	end
	if s.quantity then -- QUANTITY ADJUSTMENT (for move splitting or giving)
		if F_IsControlPressed("cancel") then
			F_ResetSelection(s,inv1,inv2)
			SoundPlay2D("NavInvalid")
		elseif s.moving and F_IsControlPressed("move") then
			if s.quantity > 0 and not F_GetItemFromInventory(inv1,inv2,"index") then
				F_MoveItem(inv1,inv2,s.quantity)
			end
			F_ResetSelection(s,inv1,inv2)
			SoundPlay2D("ButtonDown")
		elseif s.giving and F_IsControlPressed("give") then
			if s.quantity > 0 then
				F_GiveItem(inv1,s.quantity)
			end
			F_ResetSelection(s,inv1,inv2)
			SoundPlay2D("ButtonDown")
		elseif F_IsControlPressed("right") then
			if s.quantity < s.quantity_limit then
				local count = math.floor(F_GetControlPressedScale("right",s.quantity_limit/150))
				s.quantity = math.min(s.quantity+count,s.quantity_limit)
				SoundPlay2D("NavUp")
			else
				SoundPlay2D("NavInvalid")
			end
		elseif F_IsControlPressed("left") then
			if s.quantity > 0 then
				local count = math.floor(F_GetControlPressedScale("left",s.quantity_limit/150))
				s.quantity = math.max(0,s.quantity-count)
				SoundPlay2D("NavUp")
			else
				SoundPlay2D("NavInvalid")
			end
		end
		return
	elseif s.moving then -- MOVING ACTIONS
		local item = F_GetItemFromInventory(inv1,inv2,"moving")
		if not item or F_IsControlPressed("cancel") then
			F_ResetSelection(s,inv1,inv2)
			SoundPlay2D("NavInvalid")
		elseif F_IsControlPressed("move") then
			if item ~= F_GetItemFromInventory(inv1,inv2,"index") then
				F_MoveItem(inv1,inv2)
			end
			F_ResetSelection(s,inv1,inv2)
			SoundPlay2D("ButtonDown")
		elseif s.moving_split and F_IsControlPressed("give") and not F_GetItemFromInventory(inv1,inv2,"index") then
			s.quantity = 1
			s.quantity_limit = item.count
			s.quantity_money = item.stats.id == "money"
			SoundPlay2D("ButtonDown")
		end
	elseif F_IsControlPressed("use") then -- DEFAULT ACTIONS
		local item = inv1.items[inv1.index]
		if not item or not item.stats.use_verb or item.count < item.stats.use_cost then
			item = inv2 and inv2.items[inv2.index]
			if item then
				SendNetworkEvent("inventory:TakeItems",item.stats.id,inv2.index,item.count)
				SoundPlay2D("ButtonDown")
			else
				SoundPlay2D("NavInvalid")
			end
		elseif RunLocalEvent("inventory:Use",inv1.index,item.stats.id,item.unique) then
			SendNetworkEvent("inventory:UseItem",item.stats.id,inv1.index)
		end
	elseif F_IsControlPressed("move") then
		local item = F_GetItemFromInventory(inv1,inv2,"index")
		if item then
			s.moving = s.index
			s.moving_index = item.index
			s.moving_split = item.count > 1
			F_UpdateIndex(inv1,inv2,s.moving,"moving")
			SoundPlay2D("ButtonDown")
		else
			SoundPlay2D("NavInvalid")
		end
	elseif F_IsControlPressed("give") then
		local item = inv1.items[inv1.index]
		if item and F_CanGiveItems() then
			s.giving = s.index
			F_UpdateIndex(inv1,inv2,s.giving,"giving")
			if item.count > 1 then
				s.quantity = 1
				s.quantity_limit = item.count
				s.quantity_money = item.stats.id == "money"
			else
				F_GiveItem(inv1,1)
			end
			SoundPlay2D("ButtonDown")
		else
			SoundPlay2D("NavInvalid")
		end
	elseif F_IsControlPressed("cancel") then -- dump
		local item = inv1.items[inv1.index]
		if item and inv2 then
			SendNetworkEvent("inventory:DumpItems",item.stats.id,inv1.index,item.count)
			SoundPlay2D("ButtonDown")
		end
	end
	if F_IsControlPressed("left") then -- NAVIGATION CONTROLS
		if math.mod(s.index,cols) == 1 then
			s.index = s.index + (cols - 1)
			F_SnapIndex(inv1,inv2)
		else
			s.index = s.index - 1
			if inv2 and math.mod(s.index,cols) == cols / 2 then
				F_SnapIndex(inv1,inv2)
			end
		end
		F_UpdateIndex(inv1,inv2,s.index,"index")
	end
	if F_IsControlPressed("right") then
		if math.mod(s.index,cols) == 0 then
			s.index = s.index - (cols - 1)
			F_SnapIndex(inv1,inv2)
		else
			if inv2 and math.mod(s.index,cols) == cols / 2 then
				F_SnapIndex(inv1,inv2)
			end
			s.index = s.index + 1
		end
		F_UpdateIndex(inv1,inv2,s.index,"index")
	end
	if F_IsControlPressed("up") then
		if s.index <= cols then
			s.index = s.index + cols * (rows - 1)
			F_SnapIndex(inv1,inv2)
		else
			s.index = s.index - cols
		end
		F_UpdateIndex(inv1,inv2,s.index,"index")
	end
	if F_IsControlPressed("down") then
		if s.index > cols * (rows - 1) then
			s.index = s.index - cols * (rows - 1)
			F_SnapIndex(inv1,inv2)
		else
			s.index = s.index + cols
		end
		F_UpdateIndex(inv1,inv2,s.index,"index")
	end
	if s.index ~= sound then
		SoundPlay2D("NavUp")
	end
end
function F_UpdateIndex(inv1,inv2,index,key)
	local cols = gMetrics.item_columns
	if not inv2 then
		inv1[key] = index
	elseif math.mod(index-1,cols*2) < cols then
		inv1[key] = index - math.floor((index-1)/(cols*2)) * cols
		inv2[key] = nil
	else
		inv1[key] = nil
		inv2[key] = (index - cols) - math.floor(((index-cols)-1)/(cols*2)) * cols
	end
end
function F_SnapIndex(inv1,inv2)
	inv1.x = nil
	inv1.y = nil
	if inv2 then
		inv2.x = nil
		inv2.y = nil
	end
end

-- actions
function F_MoveItem(inv1,inv2,count)
	local dest,src = {},{}
	for t,k in pairs({[dest] = "index",[src] = "moving"}) do
		local item
		if inv1[k] then
			item = inv1.items[inv1[k]]
			t.slot = inv1[k]
			t.side = false
		else
			item = inv2.items[inv2[k]]
			t.slot = inv2[k]
			t.side = true
		end
		if item then
			t.index = gItemIndex[item.stats.id]
			if t == src and dest ~= src and not item.stats.can_drop then
				return
			end
		end
	end
	if count then
		src.count = count
	end
	SendNetworkEvent("inventory:MoveItem",dest,src)
end
function F_GiveItem(inv,count)
	local item = inv.items[inv.index]
	if item then
		gGiving = {index=item.index,count=count,name=item.name,slot=inv.index,tut=true}
	end
end

-- equip
function F_EquipItem(slot)
	local item = gPlayerInventory.items[slot]
	if item and not gGiving.index and item.count >= item.stats.use_cost then
		F_ReleaseControls()
		gEquip = {index=item.index,count=math.max(item.stats.use_cost,1),slot=slot}
		RunLocalEvent("inventory:Equip",slot,gItemStats[item.index].id,item.unique)
		return true
	end
	return false
end
function F_UnequipItem()
	if gEquip.index then
		RunLocalEvent("inventory:Equip")
		F_ReleaseControls()
		gEquip = {}
	end
end

-- giving
function F_UpdateGiving(alpha)
	local ped = PedGetTargetPed(gPlayer)
	local icon = gItemStats[gGiving.index].icon_name
	if icon and icon ~= "none" then
		F_DrawEquipped(icon,alpha)
	end
	if gGiving.name then
		local text = "~MANUAL_LOCK~ Lock on to give someone a"
		if ({a=true,e=true,i=true,o=true,u=true})[string.lower(string.sub(gGiving.name,1,1))] then
			text = text.."n"
		end
		if gItemStats[gGiving.index].id == "money" then
			TutorialShowString("~MANUAL_LOCK~ Lock on to give someone "..F_GetMoneyString(gGiving.count)..".")
		elseif gGiving.count == 1 then
			TutorialShowString(text.." "..gGiving.name..".")
		else
			TutorialShowString(text.." "..gGiving.name..". ( x "..F_GetCountString(gGiving.count).." )")
		end
		gGiving.name = nil
	elseif gGiving.tut and PedIsValid(ped) then
		TutorialShowString("~RUN~ Give item.\n~JUMP~ Cancel.")
		gGiving.tut = nil
	end
	if PedIsValid(ped) and F_IsControlPressed("give") then
		local item = gPlayerInventory.items[gGiving.slot]
		if item and item.index == gGiving.index and item.count >= gGiving.count then
			local sped = PedGetSyncPed(ped)
			local id = gItemStats[gGiving.index].id
			if (not sped or IsSyncEntityOwned(sped)) and not PedIsInCombat(ped) then
				SoundStopCurrentSpeechEvent(ped)
				if math.random(100) <= 85 and id == "money" then
					SoundPlayAmbientSpeechEvent(ped,({"BOISTEROUS","SEE_SOMETHING_COOL","THANK_YOU"})[math.random(3)])
				elseif math.random(100) <= 40 then
					if math.random(2) == 1 then
						SoundPlayAmbientSpeechEvent(ped,"GIFT_RECEIVE")
						if not SoundSpeechPlaying(ped,"GIFT_RECEIVE") then
							SoundPlayAmbientSpeechEvent(ped,"TY")
						end
					else
						SoundPlayAmbientSpeechEvent(ped,"TY")
					end
				elseif math.random(100) <= 25 then
					SoundPlayAmbientSpeechEvent(ped,"DISGUST")
				elseif math.random(100) <= 20 then
					SoundPlayAmbientSpeechEvent(ped,"FIGHT_INITIATE")
					PedAttackPlayer(ped,1)
				else
					SoundPlayAmbientSpeechEvent(ped,"CONFUSED")
				end
			end
			SendNetworkEvent("inventory:GiveItem",sped,id,gGiving.slot,gGiving.count)
		end
		F_ReleaseControls()
		gInputDelay = true
		gGiving = {}
	elseif F_IsControlPressed("cancel") or not F_CanGiveItems() then
		F_ReleaseControls()
		gInputDelay = true
		gGiving = {}
	end
end
function F_CanGiveItems()
	return PedGetWeapon(gPlayer) ~= 437
end

-- utility
function F_ReleaseControls()
	for b,v in pairs(gControlsNow) do
		if v then
			gControlsRepeat[b] = nil
			gControlsTimer[b] = nil
			gControlsLast[b] = true
			gControlsNow[b] = false
		end
	end
end
function F_GetItemFromInventory(inv1,inv2,key)
	if inv1[key] then
		return inv1.items[inv1[key]]
	elseif inv2 then
		return inv2.items[inv2[key]]
	end
end

-- interface
function F_SetupControlTextures()
	if IsUsingJoystick(0) then
		gControlTextures[1] = GetInputTexture(7,0) -- use
		gControlTextures[2] = GetInputTexture(6,0) -- move
		gControlTextures[3] = GetInputTexture(9,0) -- drop
		gControlTextures[4] = GetInputTexture(8,0) -- cancel
	else
		gControlTextures[1] = GetKeyboardTexture("RETURN") -- use
		gControlTextures[2] = GetKeyboardTexture("F") -- move
		gControlTextures[3] = GetKeyboardTexture("R") -- drop
		gControlTextures[4] = GetKeyboardTexture("SPACE") -- cancel
	end
end
function F_DrawInventory(s,inv,align,alpha)
	local item = inv.items[inv.index]
	local x,y = F_DrawBackdrop(inv,align,alpha)
	F_DrawItems(inv,alpha,x,y)
	if item then
		F_DrawInfo(item,alpha,x,y)
	elseif not next(inv.items) and inv == gPlayerInventory then
		F_DrawInfo(nil,alpha,x,y)
	end
	F_DrawControls(s,inv,item,alpha,x,y)
	if s.quantity then
		F_DrawQuantity(s,alpha)
	end
end
function F_DrawBackdrop(inv,align,alpha)
	local m = gMetrics
	local ar = GetDisplayAspectRatio()
	local x,y = 0.5,m.y
	if align == "L" then
		x = x - (m.x + m.width) / ar
	elseif align == "R" then
		x = x + m.x / ar
	else
		x = x - (m.width * 0.5) / ar
	end
	if m.debug then
		DrawRectangle(x-m.border_w/ar,y+m.border_y-m.border_h,(m.width+m.border_w*2)/ar,m.height+m.border_h*2,255,0,0,255)
	end
	DrawRectangle(x,y,m.width/ar,m.titlebar_h,F_Color(m.titlebar_color,alpha))
	DrawRectangle(x,y+m.titlebar_h,m.width/ar,m.height-m.titlebar_h,F_Color(m.background_color,alpha))
	DrawTexture(dsl.radar.GetBorder(),x-m.border_w/ar,y+m.border_y-m.border_h,(m.width+m.border_w*2)/ar,m.height+m.border_h*2,255,255,255,alpha)
	SetTextFont("Georgia")
	SetTextBold()
	SetTextColor(F_Color(m.title_color,alpha))
	SetTextOutline()
	SetTextHeight(m.titlebar_h*m.title_ratio)
	SetTextClipping(m.width/ar)
	SetTextAlign("C","B")
	SetTextPosition(x+(m.width*0.5)/ar,y+m.titlebar_h+m.title_y)
	DrawText(inv.title)
	return x,y
end
function F_DrawItems(inv,alpha,wx,wy)
	local m = gMetrics
	local ar = GetDisplayAspectRatio()
	local width = m.width - m.window_padding * 2
	local size = width * (1 / m.item_columns)
	wx = wx + m.window_padding / ar
	wy = wy + m.titlebar_h + m.window_padding
	if inv.moving then
		local sx = wx + (size / ar) * math.mod(inv.moving-1,m.item_columns)
		local sy = wy + size * math.floor((inv.moving-1)/m.item_columns)
		DrawRectangle(sx,sy,size/ar,size,F_Color(m.item_moving_color,alpha))
	end
	if inv.index then
		-- calculate selection position and smooth shown position (inv.x / inv.y)
		local sx = wx + (size / ar) * math.mod(inv.index-1,m.item_columns)
		local sy = wy + size * math.floor((inv.index-1)/m.item_columns)
		if not inv.x then
			inv.x = sx -- reset if inv.x wasn't set
			inv.y = sy
		elseif inv.x ~= sx or inv.y ~= sy then
			local dx,dy = sx-inv.x,sy-inv.y
			local dist = math.sqrt(dx*dx+dy*dy)
			local speed = GetFrameTime() * m.item_cursor_speed
			if speed < dist then
				inv.x = inv.x + (dx / dist) * speed -- smooth out
				inv.y = inv.y + (dy / dist) * speed
			else
				inv.x = sx -- snap to final position
				inv.y = sy
			end
		end
		DrawRectangle(inv.x,inv.y,size/ar,size,F_Color(m.item_cursor_color,alpha))
	end
	for slot,item in pairs(inv.items) do
		local ix = wx + (size / ar) * math.mod(slot-1,m.item_columns)
		local iy = wy + size * math.floor((slot-1)/m.item_columns)
		local tx = ix + m.item_padding / ar
		local ty = iy + m.item_padding
		local tw = (size - m.item_padding * 2) / ar
		local th = size - m.item_padding * 2
		if m.debug then
			local offset = math.mod(m.item_columns,2) == 0 and math.floor((slot-1)/m.item_columns) or 0
			local value = math.mod((slot-1)+offset,2) == 0 and 200 or 150
			DrawRectangle(ix,iy,size/ar,size,value,value,value,255)
			DrawRectangle(tx,ty,tw,th,0,value,0,255)
		end
		if item.unique and item.stats.unique_drawing then
			RunLocalEvent("inventory:Draw",item.stats.id,item.unique,tx,ty,tw,th,alpha)
		end
		if item.stats.icon_name ~= "none" then
			DrawTexture(F_PrepareIcon(item.stats.icon_name),tx,ty,tw,th,255,255,255,alpha)
		end
		if item.count ~= 1 or item.stats.id == "money" then
			SetTextFont("Georgia")
			SetTextBold()
			SetTextColor(255,255,255,alpha)
			SetTextOutline()
			SetTextAlign("R","B")
			SetTextPosition(tx+tw,ty+th)
			if item.stats.id == "money" then
				SetTextHeight(th*m.money_count_ratio)
				DrawText(F_GetMoneyString(item.count))
			else
				SetTextHeight(th*m.item_count_ratio)
				DrawText(item.count)
			end
		end
	end
end
function F_DrawInfo(item,alpha,x,y)
	local m = gMetrics
	local ar = GetDisplayAspectRatio()
	local width = m.width - m.window_padding * 2
	x = x + m.window_padding / ar
	y = y + m.titlebar_h + m.window_padding * 2 + ((m.width - m.window_padding * 2) * (1 / m.item_columns)) * m.item_rows
	if m.debug then
		DrawRectangle(x,y,width/ar,m.info_height,0,100,255,255)
		DrawRectangle(x,y+m.info_height*(m.info_title_ratio+m.info_desc_y),width/ar,m.info_height*(1-m.info_title_ratio),0,50,200,255)
	end
	if item then
		SetTextFont("Arial")
		SetTextBlack()
		SetTextColor(F_Color(m.info_title_color,alpha))
		SetTextShadow()
		SetTextHeight(m.info_height*m.info_title_ratio)
		SetTextClipping((m.width-m.window_padding*2)/ar)
		SetTextAlign("L","T")
		SetTextPosition(x,y+m.info_title_y)
		DrawText(item.name)
		SetTextFont("Arial")
		SetTextBlack()
		SetTextColor(F_Color(m.info_title_color,alpha))
		SetTextShadow()
		SetTextHeight(m.info_height*m.info_count_ratio)
		SetTextAlign("R","T")
		SetTextPosition(x+width/ar,y+m.info_title_y)
		if item.stats.id == "money" then
			DrawText(F_GetMoneyString(item.count).." / "..F_GetMoneyString(item.stats.max_count))
		else
			DrawText(F_GetCountString(item.count).." / "..F_GetCountString(item.stats.max_count))
		end
	end
	SetTextFont("Georgia")
	SetTextColor(F_Color(m.info_desc_color,alpha))
	SetTextShadow()
	SetTextHeight(m.info_height*m.info_desc_ratio)
	SetTextWrapping(width/ar)
	SetTextClipping(nil,m.info_height*(1-m.info_title_ratio))
	SetTextAlign("L","T")
	SetTextPosition(x,y+m.info_height*(m.info_title_ratio+m.info_desc_y))
	if item then
		DrawText(item.description)
	else
		DrawText("Your inventory is empty. Hopefully you can find something soon!")
	end
end
function F_DrawControls(s,inv,item,alpha,x,y)
	local m = gMetrics
	local ar = GetDisplayAspectRatio()
	local width = m.width + (m.border_w - m.controls_padding_x) * 2
	local height = m.controls_height - m.controls_padding_y * 2
	local verbs = {}
	if s.quantity then
		if inv.moving then
			verbs[2] = "Split"
			verbs[4] = "Cancel"
		elseif inv.giving then
			verbs[3] = "Give"
			verbs[4] = "Cancel"
		end
	elseif s.moving then
		if inv.moving then
			if not item then
				if s.moving_split then
					verbs[3] = "Split"
				end
				verbs[2] = "Place" -- no item here, place
			elseif inv.index == inv.moving then
				verbs[2] = "Place" -- same slot, place
			elseif item.index == s.moving_index and item.stats.max_count > 1 then
				verbs[2] = "Merge" -- same item types and not unique, merge
			else
				verbs[2] = "Swap" -- different item types or unique item type, swap
			end
			verbs[4] = "Cancel"
		end
	elseif item then
		if inv == gPlayerInventory then
			if gOtherInventory.items then
				verbs[4] = "Dump"
			end
			if item.count >= item.stats.use_cost then
				verbs[1] = item.stats.use_verb
			end
			verbs[3] = item.stats.can_drop and "Give"
		else
			verbs[1] = "Take"
		end
		verbs[2] = "Move"
	end
	x = x - (m.border_w - m.controls_padding_x) / ar
	y = y + m.height + m.border_h + m.border_y + m.controls_padding_y
	if m.debug then
		DrawRectangle(x,y,width/ar,height,100,100,100,255)
	end
	for i = 1,4 do
		local texture = gControlTextures[i]
		if texture and verbs[i] then
			local tw = height * GetTextureDisplayAspectRatio(texture)
			local tx = x + tw + m.controls_text_left / ar
			DrawTexture(texture,x,y,tw,height,255,255,255,alpha)
			SetTextFont("Georgia")
			SetTextBold()
			SetTextColor(255,255,255,alpha)
			SetTextShadow()
			SetTextHeight(height*m.controls_text_ratio)
			SetTextAlign("L","C")
			SetTextPosition(tx,y+height*0.5)
			x = x + tw + DrawText(verbs[i]) + (m.controls_text_right * 2) / ar
		end
	end
end
function F_DrawQuantity(s,alpha)
	local m = gMetrics
	local ar = GetDisplayAspectRatio()
	local width = m.quantity_width / ar
	local height = m.quantity_height
	local border = m.quantity_border
	local padding = m.quantity_padding
	local bar = m.quantity_thickness
	local edge = m.quantity_edge_size
	local cursor = m.quantity_cursor_size
	local x = 0.5 - width * 0.5
	local y = 0.5 - height * 0.5
	DrawRectangle(x,y,width,height,F_Color(m.quantity_color_a,alpha))
	DrawRectangle(x-border/ar,y-border,width+(border*2)/ar,border,F_Color(m.quantity_color_b,alpha)) -- top
	DrawRectangle(x-border/ar,y+height,width+(border*2)/ar,border,F_Color(m.quantity_color_b,alpha)) -- bottom
	DrawRectangle(x-border/ar,y,border/ar,height,F_Color(m.quantity_color_b,alpha)) -- left
	DrawRectangle(x+width,y,border/ar,height,F_Color(m.quantity_color_b,alpha)) -- right
	SetTextFont("Georgia")
	SetTextColor(F_Color(m.quantity_color_b,alpha))
	SetTextAlign("C","T")
	SetTextPosition(x+width*0.5,y+padding)
	SetTextScale(m.quantity_text_scale)
	if s.moving then
		DrawText("Move how many items?")
	else
		DrawText("Give how many items?")
	end
	DrawRectangle(x+padding/ar,y+(height-bar)*0.5,width-(padding*2)/ar,bar,F_Color(m.quantity_color_b,alpha)) -- horizontal line
	DrawRectangle(x+(padding-bar)/ar,y+(height-edge)*0.5,bar/ar,edge,F_Color(m.quantity_color_b,alpha)) -- left edge
	DrawRectangle(x+width-padding/ar,y+(height-edge)*0.5,bar/ar,edge,F_Color(m.quantity_color_b,alpha)) -- right edge
	DrawRectangle(x+(s.quantity/s.quantity_limit)*(width-(padding*2)/ar)+(padding-cursor*0.5)/ar,y+(height-cursor)*0.5,cursor/ar,cursor,F_Color(m.quantity_color_c,alpha)) -- cursor
	SetTextFont("Georgia")
	SetTextColor(F_Color(m.quantity_color_b,alpha))
	SetTextAlign("C","B")
	SetTextPosition(x+width*0.5,y+height-padding)
	SetTextScale(m.quantity_text_scale)
	if s.quantity_money then
		DrawText(F_GetMoneyString(s.quantity).." / "..F_GetMoneyString(s.quantity_limit))
	else
		DrawText(F_GetCountString(s.quantity).." / "..F_GetCountString(s.quantity_limit))
	end
end
function F_DrawEquipped(icon,alpha)
	local ar = GetDisplayAspectRatio()
	local size = 0.1 + 0.01 * math.sin((GetTimer() / 1500) * math.pi * 2)
	DrawTexture(F_PrepareIcon(icon),0.5-(size*0.5)/ar,0.9-size*0.5,size/ar,size,255,255,255,alpha)
end
function F_Color(rgb,alpha)
	return rgb[1],rgb[2],rgb[3],rgb[4]*(alpha/255)
end

-- text
function F_UpdateItemText(item,key)
	local str = item.stats[key]
	local start,finish,var = string.find(str,"%[(.-)%]")
	while start do
		if var == "COUNT" then
			var = F_GetCountString(item.count)
		elseif var == "MONEY" then
			var = F_GetMoneyString(item.count)
		elseif var == "UNIQUE" then
			var = F_GetUniqueString(item)
		else
			var = "?"
		end
		str = string.sub(str,1,start-1)..var..string.sub(str,finish+1)
		start,finish,var = string.find(str,"%[(.-)%]")
	end
	item[key] = str
end
function F_GetMoneyString(count)
	return string.format("$%s.%.2d",F_GetCountString(math.floor(count/4)),math.mod(count,4)*25)
end
function F_GetCountString(count)
	local str = string.format("%d",count)
	local length = string.len(str)
	if count < 0 then
		str = string.sub(str,2)
	end
	while length > 3 do
		str = string.sub(str,1,length-3)..","..string.sub(str,length-2)
		length = length - 3
	end
	if count < 0 then
		return "-"..count
	end
	return str
end
function F_GetUniqueString(item)
	local x = {text = "?"}
	if item.unique then -- only run if item has unique data
		RunLocalEvent("inventory:Text",item.stats.id,item.unique,x)
	end
	return tostring(x.text)
end

-- menu
function M_AdminMenu(parent,selected)
	local menu = parent:submenu(selected.name,selected.description)
	while menu:active() do
		if menu:option("Clear Items") then
			SendNetworkEvent("inventory:ClearItems")
		elseif menu:option("Give Nonsense") then
			SendNetworkEvent("inventory:GiveRandom")
		elseif menu:option("Open Admin Storage") then
			SendNetworkEvent("inventory:AdminStorage")
			dsl.f2menu.Close()
		elseif menu:option("Give Item") then
			M_GiveItem(menu,"id")
		elseif menu:option("Give Money") then
			O_GiveMoney(menu)
		end
		menu:draw()
		Wait(0)
	end
end
function M_GiveItem(parent,key)
	local x,y,w,h
	local help = {}
	local exclude = {id = true,name = true,description = true,icon_name = true}
	local sorted = {n = 0}
	local menu = parent:submenu("Give Item")
	for _,stats in ipairs(gItemStats) do
		table.insert(sorted,{string.lower(stats[key]),stats})
	end
	table.sort(sorted,function(a,b)
		return a[1] < b[1]
	end)
	for i,v in ipairs(sorted) do
		local list = {}
		for k,v in pairs(v[2]) do
			if not exclude[k] then
				table.insert(list,k.." = "..tostring(v))
			end
		end
		table.sort(list)
		help[i] = table.concat(list,"\n")
		sorted[i] = v[2]
	end
	while menu:active() do
		for _,stats in ipairs(sorted) do
			if menu:option(stats[key]) then
				O_GiveItem(menu,stats.id)
			elseif x and menu:hover() then
				local texture = F_PrepareIcon(stats.icon_name)
				local ar = GetDisplayAspectRatio()
				local size = 0.1
				SetDrawLayer("PRE_FADE2")
				DrawTexture(texture,x+(w-size/ar)*0.95,y+0.08,size/ar,size,255,255,255,255)
			end
		end
		SetDrawLayer("PRE_FADE")
		menu:help(help[menu.i])
		x,y,w,h = menu:draw()
		Wait(0)
	end
end
function O_GiveItem(menu,id)
	local typing = StartTyping()
	if typing then
		while menu:active() do
			if not IsTypingActive(typing) then
				if not WasTypingAborted(typing) then
					local count = tonumber(GetTypingString(typing))
					if count and count >= 1 then
						SendNetworkEvent("inventory:MeowItem",id,math.floor(count))
					end
				end
				break
			end
			menu:draw("amount: "..GetTypingString(typing,true))
			Wait(0)
		end
	end
end
function O_GiveMoney(menu)
	local typing = StartTyping()
	if typing then
		while menu:active() do
			if not IsTypingActive(typing) then
				if not WasTypingAborted(typing) then
					local count = tonumber(GetTypingString(typing))
					if count and count >= 0.25 then
						SendNetworkEvent("inventory:MeowItem","money",math.floor(count/0.25))
					end
				end
				break
			end
			menu:draw("amount: $"..GetTypingString(typing,true))
			Wait(0)
		end
	end
end

-- api
function exports.GetEquipped()
	if gEquip.index then
		local item = gPlayerInventory.items[gEquip.slot]
		return gItemStats[item.index].id,item.unique,gEquip.slot
	end
end
function exports.Equip(slot)
	if type(slot) == "number" and math.floor(slot) == slot and slot >= 1 and slot <= MAX_SLOTS then
		return F_EquipItem(slot)
	end
	return false
end
function exports.Unequip()
	F_UnequipItem()
end
function exports.Close()
	if dsl.radar then
		dsl.radar.Close()
	end
end
