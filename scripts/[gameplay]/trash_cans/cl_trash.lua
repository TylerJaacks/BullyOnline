function main()
	local event
	local timer
	while true do
		if event and GetTimer() - timer >= 1500 then
			RemoveEventHandler(event)
			event = nil
			timer = nil
		end
		if PedIsPlaying(gPlayer,"/GLOBAL/GARBAGECAN/PEDPROPSACTIONS",true) and (PedMePlaying(gPlayer,"HIDEGETIN",false) or PedMePlaying(gPlayer,"HIDEGETINFROMRUN",false)) then
			PedSetActionNode(gPlayer,"/GLOBAL/GARBAGECAN/PEDPROPSACTIONS/STEALTH/CAUGHTBANK/CAUGHT/CAUGHTREQUEST/CAUGHTANIM/CAUGHT_GIVE","")
			CameraReturnToPlayer()
			while PedIsPlaying(gPlayer,"/GLOBAL/GARBAGECAN/PEDPROPSACTIONS/STEALTH/CAUGHTBANK/CAUGHT/CAUGHTREQUEST/CAUGHTANIM/CAUGHT_GIVE",true) do
				if PedGetNodeTime(gPlayer) >= 0.7 then
					if not event then
						event = RegisterLocalEventHandler("ControllerUpdating",CB_ControllerUpdating)
					end
					timer = GetTimer()
					SendNetworkEvent("trash_cans:OpenTrash")
					PedSetActionNode(gPlayer,"/GLOBAL","")
					break
				end
				Wait(0)
			end
		end
		Wait(0)
	end
end
function CB_ControllerUpdating(c)
	if c == 0 then
		SetButtonPressed(9,0,false)
	end
end
