RegisterLocalizedText("SWITCH_CHAR_BLIP","~GRAPPLE~ Switch character")

local gTransitionASAP = false
local gTransition
local gUsingBlip
local gWaiting = false
local gScript

RegisterNetworkEventHandler("models:AllowCommands",function()
	SetCommand("models_reset_delay",CB_ResetDelay,false,"Usage: models_reset_delay [player_id]\nReset the character switch delay for yourself or another player.")
end)
RegisterNetworkEventHandler("models:SetupTransition",function(a,x,y,z,h)
	gTransition = {a,x,y,z,h}
end)
RegisterNetworkEventHandler("models:SetPicker",function(active,info)
	if active then
		if not gScript then
			gScript = StartScript("cl_picker.lua")
			if gScript then
				local env = GetScriptEnvironment(gScript)
				env.gInitialId = info.initial
				env.gFirstPick = info.first
				env.gOwnedChars = info.owned
				env.gUnlockedChars = info.unlocked
				env.gDelaySwitch = info.hours ~= nil
				env.gDelayHours = info.hours
				env.gDelayMinutes = info.minutes
				env.F_DrawRules = F_DrawRules
			end
		end
	elseif gScript then
		if gTransition then
			gTransitionASAP = true
		end
		TerminateScript(gScript)
		gScript = nil
	end
end)
RegisterNetworkEventHandler("models:StopWaiting",function()
	gWaiting = false
end)

function main()
	local thread
	local x,y,z = 528.27,-59.54,5.34
	SendNetworkEvent("models:StartScript")
	while true do
		if gTransitionASAP and not AreaIsLoading() then
			local started
			local a,x,y,z,h = unpack(gTransition)
			CameraFade(0,0)
			PlayerSetPosXYZArea(x,y,z,a)
			AreaDisableCameraControlForTransition(true)
			started = GetAccurateTimer()
			while AreaIsLoading() or IsStreamingBusy() or GetAccurateTimer() - started < 1000 do
				Wait(0)
			end
			PlayerSetHealth(PedGetMaxHealth(gPlayer))
			PedFaceHeading(gPlayer,h,0)
			CameraReturnToPlayer()
			AreaDisableCameraControlForTransition(false)
			CameraFade(1000,1)
			gTransitionASAP = false
			gTransition = nil
		end
		if DistanceBetweenCoords3d(x,y,z,PlayerGetPosXYZ()) < 20 and PlayerIsInAreaXYZ(x,y,z,1,9) and F_NoActivity() and PedMePlaying(gPlayer,"DEFAULT_KEY",true) then
			if not gUsingBlip and IsButtonBeingPressed(9,0) then
				gUsingBlip = GetAccurateTimer()
				PedSetActionNode(gPlayer,"/GLOBAL","")
				PlayerSetControl(0)
				CameraFade(650,0)
			end
			TextPrint("SWITCH_CHAR_BLIP",0.1,3)
		end
		if gUsingBlip and GetAccurateTimer() - gUsingBlip >= 800 then
			gWaiting = true
			PlayerSetControl(1)
			SendNetworkEvent("models:RequestPicker")
			while gWaiting do
				Wait(0)
			end
			if not gScript then
				CameraFade(0,1)
			end
			gUsingBlip = nil
		end
		if gScript then
			if thread then
				TerminateThread(thread)
			end
		elseif IsKeyBeingPressed("F1") and not (thread and IsThreadRunning(thread)) then
			thread = CreateThread("T_Rules")
		end
		Wait(0)
	end
end
function MissionCleanup()
	if gTransitionASAP or gUsingBlip then
		AreaDisableCameraControlForTransition(false)
		PlayerSetControl(1)
		CameraFade(0,1)
	end
end

function T_Rules()
	local rules = CreateTexture("rules.png")
	local exit = false
	local alpha = 0
	while true do
		if exit then
			alpha = alpha - GetFrameTime() / 0.4
			if alpha <= 0 then
				break
			end
		elseif alpha < 1 then
			alpha = alpha + GetFrameTime() / 0.25
			if alpha > 1 then
				alpha = 1
			end
		end
		F_DrawRules(rules,alpha)
		Wait(0)
		if IsKeyBeingPressed("F1") then
			exit = true
		end
	end
end
function F_DrawRules(rules,alpha)
	local pad = 0.032
	local size = 0.6
	local tar = GetTextureDisplayAspectRatio(rules)
	local x,y = 0.5+(size*tar)*0.5-pad/GetDisplayAspectRatio(),0.5+size*0.5-pad
	DrawRectangle(0,0,1,1,0,0,0,200*alpha)
	DrawTexture(rules,0.5-(size*tar)*0.5,0.5-size*0.5,size*tar,size,255,255,255,255*alpha)
	return x,y
end

function F_NoActivity()
	if dsl.activity and dsl.activity.IsPlaying() then
		return false
	end
	return true
end
function CB_ResetDelay(id)
	if id then
		id = tonumber(id)
		if id and math.floor(id) == id and id >= 0 then
			SendNetworkEvent("models:ResetDelay",id)
		else
			PrintError("invalid player id")
		end
	else
		SendNetworkEvent("models:ResetDelay")
	end
end
