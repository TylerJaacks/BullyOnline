gPlayingSound = false

RegisterLocalEventHandler("inventory:Text",function(id,desc,result)
	if id == "sweden_gift" or id == "america_gift" or id == "whacky_gift" then
		result.text = desc
	end
end)
RegisterNetworkEventHandler("gift_items:PlaySound",function()
	if not gPlayingSound then
		CreateThread("T_Sound")
		gPlayingSound = true
	end
end)

function T_Sound()
	if dsl.sounds then
		dsl.sounds.Play("LckrRummage","LckPick.bnk")
	else
		SoundPlay2D("LckrRummage")
	end
	gPlayingSound = false
end
