local MAX_LENGTH = GetConfigNumber(GetScriptConfig(),"max_length",100)

local MAX_DISTANCE = 15

local FADE_IN_MS = 150
local FADE_OUT_MS = 350

local BASE_SHOW_MS = 8000
local EXTRA_SHOW_MS = 7000

local LIVE_SHOW_MS = 5000
local LIVE_RATE_MS = 100

local gActive = true
local gHighVisibility = false
local gKeepProxMode = false
local gTextScale = 1.4

local gProximityMode = false
local gPedMessages = {}
local gAlerting
local gTyping

local gSentLiveUpdate
local gSentLiveText

RegisterLocalEventHandler("chat:StartTyping",function()
	return gProximityMode
end)
RegisterLocalEventHandler("f2menu:Open",function(f_add)
	f_add({
		name = "Proximity Chat Preferences",
		description = "Preferences relating to the proximity chat feature, which can be activated using the /say command.",
		thread = M_Proximity,
	})
end)

RegisterLocalEventHandler("sync:DeletePed",function(sped)
	gPedMessages[sped] = nil
end)
RegisterNetworkEventHandler("proximity:ShowMessage",function(sped,message,live)
	if message then
		local length = utf8.len(message)
		if length and gActive then
			local list = gPedMessages[sped]
			if list then
				local data = list[1]
				local passed = GetSyncTimer() - data.started
				if data.live then
					data.duration = passed + LIVE_SHOW_MS
					data.str = message
					data.live = live
					gPedMessages[sped] = {data}
					return -- updated live, done
				elseif passed < data.duration - FADE_OUT_MS then
					data.duration = passed + FADE_OUT_MS
				end
				list = {data}
			else
				list = {}
			end
			gPedMessages[sped] = list
			table.insert(list,{
				started = GetSyncTimer(),
				duration = live and LIVE_SHOW_MS or (BASE_SHOW_MS + EXTRA_SHOW_MS * (length / MAX_LENGTH)),
				str = message,
				live = live,
			})
		end
	else
		local list = gPedMessages[sped]
		if list then
			local data = list[1]
			local passed = GetSyncTimer() - data.started
			if passed < data.duration - FADE_OUT_MS then
				data.duration = passed + FADE_OUT_MS
			end
		end
	end
end)

-- main
function main()
	F_LoadConfig()
	SendNetworkEvent("proximity:InitScript")
	SetCommand("s",CB_Say,true,"Usage: s [message...]\nShortcut for /say.")
	SetCommand("say",CB_Say,true,"Usage: say [message...]\nSend a proximity chat or enter proximity chat mode.")
	while true do
		if gSentLiveUpdate and GetAccurateTimer() - gSentLiveUpdate >= LIVE_RATE_MS then
			gSentLiveUpdate = nil
		end
		if gActive then
			F_DrawChats()
			F_UpdateTyping()
		end
		Wait(0)
	end
end
function CB_Say(message)
	if not gActive then
		PrintError("proximity chats are disabled")
	elseif message then
		local length = utf8.len(message)
		if length then
			if length > MAX_LENGTH then
				message = string.sub(message,1,utf8.offset(message,MAX_LENGTH-2)-1).."..."
			end
			if string.find(message,"%S") then
				SendNetworkEvent("proximity:SendMessage",message)
			end
		end
	elseif not gProximityMode then
		gTyping = StartTyping()
		if gTyping then
			gProximityMode = true
			gSentLiveText = nil
		else
			PrintError("failed to enter proximity mode")
		end
	end
end

-- f2menu stuff
function M_Proximity(parent)
	local menu = parent:submenu("Proximity Chat")
	while menu:active() do
		if menu:option("Proximity Chats",gActive and "[SHOWN]" or "[HIDDEN]","If proximity chats should be shown.") then
			if gActive then
				if gTyping then
					SendNetworkEvent("proximity:TypeMessage")
					StopTyping(gTyping)
					gTyping = nil
				end
				gProximityMode = false
				gPedMessages = {}
			end
			gActive = not gActive
		elseif menu:option("Keep Proximity Mode",gKeepProxMode and "[ON]" or "[OFF]","If proximity mode (started by /say) should stay on for the next time enter is pressed.") then
			gKeepProxMode = not gKeepProxMode
			F_SaveConfig()
		elseif menu:option("Text Scale",string.format("[x%.1f]",gTextScale),"Make proximity chat text bigger or smaller.") then
			gTextScale = F_AdjustScale(gTextScale)
			F_SaveConfig()
		elseif menu:option("High Visibility",gHighVisibility and "[ON]" or "[OFF]","If slightly less stylized text should be used in favor of readability.") then
			gHighVisibility = not gHighVisibility
			F_SaveConfig()
		end
		menu:draw()
		Wait(0)
	end
end
function F_AdjustScale(scale)
	scale = math.floor(scale * 10 + 2) / 10
	if scale > 2 then
		return 1
	end
	return scale
end

-- config stuff
function F_LoadConfig()
	local data = GetPersistentDataTable("Xx_Yubari_xX").proximity
	if type(data) == "table" then
		if data.high_visibility ~= nil then gHighVisibility = data.high_visibility end
		if data.keep_prox_mode ~= nil then gKeepProxMode = data.keep_prox_mode end
		if data.text_scale ~= nil then gTextScale = data.text_scale end
	end
end
function F_SaveConfig()
	local persist = GetPersistentDataTable("Xx_Yubari_xX")
	local data = persist.proximity
	if type(data) ~= "table" then
		data = {}
		persist.proximity = data
	end
	data.high_visibility = gHighVisibility
	data.keep_prox_mode = gKeepProxMode
	data.text_scale = gTextScale
	SavePersistentDataTables()
end

-- proximity mode
function F_UpdateTyping()
	if gAlerting and GetAccurateTimer() - gAlerting[1] >= 5000 then
		gAlerting = nil
	end
	if not gTyping and gProximityMode then
		local slash = IsKeyBeingPressed("SLASH")
		if (slash or IsKeyBeingPressed("RETURN")) and F_CanStart() then
			if slash then
				gTyping = StartTyping("/")
			else
				gTyping = StartTyping()
			end
			if not gTyping then
				gProximityMode = false
			end
			gSentLiveText = nil
			gAlerting = nil
		end
	end
	if gAlerting or gTyping then
		if gAlerting or IsTypingActive(gTyping) then
			local text,length
			if gAlerting then
				text = gAlerting[2]
				length = 0
			else
				text = GetTypingString(gTyping)
				length = utf8.len(text)
			end
			if length then
				local ar = GetDisplayAspectRatio()
				local x,y = 0.5,0.9
				local width = 0.7
				local height = 0.02
				local padding = 0.01
				if length > MAX_LENGTH then
					text = string.sub(text,1,utf8.offset(text,MAX_LENGTH-2)-1).."..."
				end
				if not gAlerting and not gSentLiveUpdate and text ~= gSentLiveText then
					if not string.find(text,"^/") then
						if string.find(text,"%S") then
							SendNetworkEvent("proximity:TypeMessage",text)
						else
							SendNetworkEvent("proximity:TypeMessage")
						end
						gSentLiveUpdated = GetAccurateTimer()
					end
					gSentLiveText = text
				end
				DrawRectangle(x-((width+padding)*0.5)/ar,y-padding*0.5,(width+padding)/ar,height*4+padding,0,0,0,150)
				SetTextFont("Georgia")
				SetTextBold()
				SetTextOutline()
				SetTextItalic()
				SetTextColor(230,230,230,255)
				SetTextAlign("L","B")
				SetTextPosition(x-(width*0.5)/ar,y-padding*0.5)
				SetTextHeight(height*1.5)
				DrawText("Proximity Chat (/say)")
				SetTextFont("Georgia")
				SetTextBold()
				SetTextColor(230,230,230,255)
				SetTextAlign("L","T")
				SetTextPosition(x-(width*0.5)/ar,y)
				SetTextHeight(height)
				SetTextWrapping(width/ar)
				DrawText(text)
			end
		elseif not WasTypingAborted(gTyping) then
			local text = GetTypingString(gTyping)
			local length = utf8.len(text)
			local sent = false
			if length then
				if length > MAX_LENGTH then
					text = string.sub(text,1,utf8.offset(text,MAX_LENGTH-2)-1).."..."
				end
				if string.find(text,"%S") then
					local found,_,command = string.find(text,"^/(%S+)")
					if found then
						command = string.lower(command)
					end
					if not found then
						SendNetworkEvent("proximity:SendMessage",text)
						sent = true
					elseif command == "help" then
						if gKeepProxMode then
							gAlerting = {GetAccurateTimer(),"Use /exit or hit escape to leave proximity chat mode."}
						else
							gAlerting = {GetAccurateTimer(),"This is proximity chat mode, use /say to bring it up again."}
						end
					elseif command == "exit" or command == "say" then
						gProximityMode = false
					else
						gAlerting = {GetAccurateTimer(),"Normal commands are not supported in proximity chat mode."}
					end
				end
			end
			if not sent then
				SendNetworkEvent("proximity:TypeMessage")
			end
			if not gKeepProxMode then
				gProximityMode = false
			end
			gTyping = nil
		else
			SendNetworkEvent("proximity:TypeMessage")
			if not gKeepProxMode then
				gProximityMode = false
			end
			gTyping = nil
		end
	end
end
function F_CanStart()
	if dsl.radar and dsl.radar.IsActive() then
		return false
	end
	return not IsPauseMenuActive() and not IsMapMenuActive()
end

-- draw messages
function F_DrawChats()
	local timer = GetSyncTimer()
	local area = AreaGetVisible()
	local x1,y1,z1 = PlayerGetPosXYZ()
	for sped,list in pairs(gPedMessages) do
		local data = list[1]
		local ped = PedFromSyncPed(sped)
		local passed = timer - data.started
		if passed >= data.duration then
			table.remove(list,1)
			data = list[1]
			if not data then
				gPedMessages[sped] = nil
				break
			end
			data.started = GetSyncTimer()
			passed = 0
		end
		if PedIsValid(ped) then
			local x2,y2,z2 = PedGetPosXYZ(ped)
			local dx,dy,dz = x2-x1,y2-y1,z2-z1
			if dx*dx+dy*dy+dz*dz < MAX_DISTANCE*MAX_DISTANCE then
				local alpha = 1
				if passed < FADE_IN_MS then
					alpha = passed / FADE_IN_MS
				elseif passed >= data.duration - FADE_OUT_MS then
					alpha = (data.duration - passed) / FADE_OUT_MS
				end
				F_DrawChat(ped,data.str,alpha*255)
			end
		end
	end
end
function F_DrawChat(ped,str,alpha)
	local px,py,pz = F_GetPosition(ped)
	local sx1,sy1 = GetScreenCoords(px,py,pz)
	local sx2,sy2 = GetScreenCoords(px,py,pz-0.1*gTextScale)
	if ped == gPlayer and dsl.first_person and dsl.first_person.IsActive() then
		local offset = 0.15 / GetDisplayAspectRatio()
		sx1,sy1 = 0.5-offset,0.72
		sx2,sy2 = 0.5-offset,0.75
	end
	if sx1 and sx2 then
		local height = math.abs(sy2 - sy1)
		if height > 0.005 * gTextScale then
			if gHighVisibility then
				SetTextFont("Arial")
				SetTextColor(255,255,255,alpha)
				SetTextOutline()
			else
				SetTextFont("Georgia")
				SetTextBold()
				SetTextColor(230,230,230,alpha)
				SetTextShadow()
			end
			SetTextAlign("L","T")
			SetTextPosition(sx1,sy1)
			SetTextWrapping(height*10)
			SetTextHeight(height)
			DrawText(str)
		end
	end
end
function F_GetPosition(ped)
	local ratio = 1.015
	local offset = 0.09
	local h = PedGetHeading(ped)
	local x1,y1,z1 = PedGetPosXYZ(ped)
	local x2,y2,z2 = PedGetHeadPos(ped)
	local dx,dy,dz = x2-x1,y2-y2,z2-z1
	return x1+dx*ratio+math.cos(h)*offset,y1+dy*ratio+math.sin(h)*offset,z1+dz*ratio
end
