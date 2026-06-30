RegisterLocalizedText("WARPS_PROMPT",100)
LoadScript("warps.lua")

gDebug = false
gWarping = false
gWaiting = false
gDimension = "n/a"

RegisterNetworkEventHandler("warps:ContinueTransition",function()
	gWaiting = false
end)
RegisterNetworkEventHandler("warps:SetDimension",function(name)
	gDimension = name
end)
RegisterNetworkEventHandler("warps:AllowDebug",function()
	SetCommand("warps_debug",CB_WarpsDebug,false,"Usage: warps_debug\nToggle debug view of warping blips.")
end)

function CB_WarpsDebug()
	gDebug = not gDebug
	PrintOutput("warp debugging: "..(gDebug and "ON" or "OFF"))
end

function main()
	SendNetworkEvent("warps:InitScript")
	while true do
		if F_NoActivity() then
			local area = AreaGetVisible()
			local px,py,pz = PlayerGetPosXYZ()
			for _,warp in ipairs(gWarps) do
				if F_Nearby(warp,area,px,py,pz,warp.trigger_area,warp.trigger) then
					F_Warp(warp,warp.trigger,warp.destination_area,warp.destination)
				end
				if warp.bi_directional and F_Nearby(warp,area,px,py,pz,warp.destination_area,warp.destination) then
					F_Warp(warp,warp.destination,warp.trigger_area,warp.trigger)
				end
			end
		end
		if gDebug then
			SetTextFont("Cascadia Mono")
			SetTextBold()
			SetTextColor(255,0,255,255)
			SetTextShadow()
			SetTextAlign("C","T")
			SetTextPosition(0.5,0.1)
			DrawText(gDimension)
		end
		Wait(0)
	end
end
function MissionCleanup()
	if gWarping then
		AreaDisableCameraControlForTransition(false)
		PedSetEffectedByGravity(gPlayer,true)
		PlayerSetControl(1)
		CameraFade(0,1)
	end
end

function F_NoActivity()
	if dsl.activity and dsl.activity.IsPlaying() then
		return false
	end
	return true
end
function F_Nearby(warp,pa,px,py,pz,area,pos)
	if pa == area and not (warp.visible_dimension and warp.visible_dimension ~= gDimension) then
		local wx,wy,wz = unpack(pos)
		local dx,dy,dz = px-wx,py-wy,pz-wz
		return dx*dx+dy*dy+dz*dz < 900 -- 30m
	end
	return false
end
function F_Warp(warp,trigger,area,dest)
	local tx,ty,tz = unpack(trigger)
	if PlayerIsInAreaXYZ(tx,ty,tz,1,warp.blip) and PlayerHasControl() and PedMePlaying(gPlayer,"DEFAULT_KEY",true) and not PedIsDead(gPlayer) then
		if not gWarping and IsButtonBeingPressed(9,0) then
			gWarping = true
			CreateThread("T_Warp",warp,area,dest)
		elseif warp.prompt ~= "" then
			ReplaceLocalizedText("WARPS_PROMPT","~GRAPPLE~ "..warp.prompt)
			TextPrint("WARPS_PROMPT",0.1,3)
		end
	end
	if gDebug then
		local sx,sy = GetScreenCoords(tx,ty,tz)
		if sx then
			SetTextFont("Cascadia Mono")
			SetTextBold()
			SetTextColor(255,255,255,255)
			SetTextShadow()
			SetTextAlign("C","B")
			SetTextPosition(sx,sy)
			if not warp.bi_directional then
				DrawText(warp.id)
			elseif warp.trigger == trigger then
				DrawText(warp.id.." (trigger)")
			else
				DrawText(warp.id.." (destination)")
			end
		end
	end
end
function T_Warp(warp,area,dest)
	local started
	local x,y,z,h = unpack(dest)
	AreaDisableCameraControlForTransition(true)
	PlayerSetControl(0)
	CameraFade(650,0)
	Wait(650)
	if warp.destination_dimension ~= "main" and warp.destination == dest then
		SendNetworkEvent("warps:UpdateDimension",warp.id)
		gWaiting = true
		while gWaiting do
			Wait(0)
		end
		Wait(500) -- should be ample time for a dimension update
		started = GetTimer() -- start stream timer from here
	else
		SendNetworkEvent("warps:UpdateDimension") -- not transitioning into a dimension
		if not AreaIsLoading() then -- local transition
			started = GetTimer()
			PlayerSetPosXYZArea(x,y,z,area)
			while AreaIsLoading() do
				Wait(0)
			end
			PedFaceHeading(gPlayer,h,0)
			CameraReturnToPlayer()
		end
	end
	while started and (IsStreamingBusy() or GetTimer() - started < 200) do
		Wait(0)
	end
	AreaDisableCameraControlForTransition(false)
	PlayerSetControl(1)
	CameraFade(650,1)
	Wait(800)
	gWarping = false
end
