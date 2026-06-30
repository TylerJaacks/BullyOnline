gPlayers = {}

RegisterLocalEventHandler("inventory:Use",function(player,id,_,items,slot)
	-- need at least 4 slots because we need 5 slots but we're removing 1 item
	if id == "sweden_gift" and items == "day1_gift" and dsl.inventory.GetPlayerSpace(player) >= 4 and dsl.inventory.RemoveItemFromPlayer(player,id,1,slot) then
		SendNetworkEvent(player,"gift_items:PlaySound")
		dsl.inventory.GiveItemToPlayer(player,"note_v1rel",1)
		dsl.inventory.GiveItemToPlayer(player,"blue_flowers",1)
		dsl.inventory.GiveItemToPlayer(player,"skateboard",1)
		dsl.inventory.GiveItemToPlayer(player,"blank_paper",20)
		dsl.inventory.RewardPlayerMoney(player,2000)
	elseif id == "america_gift" and items == "yubari_gift" and dsl.inventory.GetPlayerSpace(player) >= 3 and dsl.inventory.RemoveItemFromPlayer(player,id,1,slot) then
		SendNetworkEvent(player,"gift_items:PlaySound")
		dsl.inventory.GiveUniqueItemToPlayer(player,"written_paper","Thank you for playing Bully Online. This note is part of a rare gift you got for being online during a random gift drop. I hope you enjoy it!\n\nIn here you'll find a skateboard, a stack of 20 papers for writing notes, and $50.\n\nP.S. Chat improvements are coming soon - including ways to customize the chat, turn it off entirely, and even proximity chat.\n\n~ Xx_Yubari_xX, Dec 23rd 2025","Xx_Yubari_xX")
		dsl.inventory.GiveItemToPlayer(player,"skateboard",1)
		dsl.inventory.GiveItemToPlayer(player,"blank_paper",20)
		dsl.inventory.RewardPlayerMoney(player,5000)
	elseif id == "whacky_gift" and (items == "yubari_gift_2" or items == nil) and dsl.inventory.GetPlayerSpace(player) >= 3 and dsl.inventory.RemoveItemFromPlayer(player,id,1,slot) then
		SendNetworkEvent(player,"gift_items:PlaySound")
		dsl.inventory.GiveUniqueItemToPlayer(player,"written_paper","Thank you for playing Bully Online! This note came with a rare gift you got for being online during a random gift drop! I hope you enjoy the skateboard, 20 papers, and $100. <3\n\n~ Xx_Yubari_xX ~ Jan 1st 2026\n\nYubari is forcing me to add something so Idk HI MOM I'M IN A BULLY ONLINE NOTE!\n\n~ PixeL","Xx_Yubari_xX")
		dsl.inventory.GiveItemToPlayer(player,"skateboard",1)
		dsl.inventory.GiveItemToPlayer(player,"blank_paper",20)
		dsl.inventory.RewardPlayerMoney(player,10000)
	end
end)

SetCommand("give_gift",function()
	if not dsl.inventory then
		PrintError("failed to give gift")
		return
	end
	for player in AllPlayers() do
		if GetPlayerName(player) == "Xx_Yubari_xX" then
			dsl.inventory.GiveUniqueItemToPlayer(player,"whacky_gift","A rare gift from Xx_Yubari_xX and pixeL.","yubari_gift_2")
		end
	end
end,false,"Usage: give_gift\nFor Xx_Yubari_xX to give her gifts out.")
