gText = ""

function T_Draw()
	while true do
		SetTextFont("Georgia")
		SetTextBold()
		SetTextColor(230,230,230,255)
		SetTextOutline()
		SetTextAlign("C","T")
		SetTextPosition(0.5,0)
		SetTextScale(0.55)
		DrawText(gText)
		Wait(0)
	end
end
function CB_Command(text)
	if text and text ~= "" then
		SendNetworkEvent("quick_text:Update",text)
	else
		SendNetworkEvent("quick_text:Update")
	end
end

RegisterNetworkEventHandler("quick_text:Update",function(text)
	if gText ~= text then
		if text == "" then
			TerminateThread(gThread)
			gThread = nil
		else
			gThread = CreateDrawingThread("T_Draw")
		end
		gText = text
	end
end)
RegisterNetworkEventHandler("quick_text:Permit",function()
	SetCommand("quick_text",CB_Command,true,"Usage: quick_text [...]\nSet text shown to all players on the server.")
end)

SendNetworkEvent("quick_text:Start")
