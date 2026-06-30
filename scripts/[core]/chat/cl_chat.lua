local gTyping
local gMessages = {n = 0}
local gScrolling = 0
local gDisplayActive = false
local gDisplayAlpha = 0 -- goes up/down if active or not
local gDisplayTimer
local gPlaySound -- sounds from net events are only played when the main thread runs
local gAllowOutput = true
local gBlocks = {} -- [user] = true

-- chat settings
local gFontRgb = 200
local gUseOneLine = not GetConfigBoolean(GetScriptConfig(),"always_show_under_name",false)
local gFontFamily = GetConfigString(GetScriptConfig(),"font_family","Arial")
local gFontStyle = GetConfigString(GetScriptConfig(),"font_style","black")
local gFontScale = GetConfigNumber(GetScriptConfig(),"font_scale",0.7)
local gWantHigher = {}
local gChatStyle = "DEFAULT"

-- chat preferences
local gSilentMode = false
local gGlobalMessages = true
local gDirectMessages = true
local gStatusMessages = true
local gPreferStyle = "DEFAULT"
local gDrawBackground = true
local gSoundJoinLeaves = false
local gSoundMessages = true
local gArrowDirect = true
local gTextScale = 1
local gBoxScale = 1

-- Main.
function main()
	local draw
	F_LoadConfig()
	SendNetworkEvent("chat:InitPreferences")
	draw = CreateDrawingThread("T_Draw")
	while IsThreadRunning(draw) do
		if F_StartTyping() then -- start or continue typing
			local submit = F_UpdateTyping()
			if submit then
				F_SubmitMessage(submit)
			elseif gTyping then
				F_Display() -- keep displaying as long as we didnt during the update
			end
		end
		if gDisplayActive then
			F_UpdateScrolling()
		end
		if gPlaySound then
			SoundPlay2D(gPlaySound) -- sounds from network events will only play once the main thread is reached (so it doesn't play when paused)
			gPlaySound = nil
		end
		Wait(0)
	end
	TextPrintString("chat script failed",10,1)
end
function F_StartTyping()
	if not gTyping then
		local slash = IsKeyBeingPressed("SLASH")
		if not gSilentMode and (slash or IsKeyBeingPressed("RETURN")) and RunLocalEvent("chat:StartTyping") then
			if slash then
				gTyping = StartTyping("/")
			else
				gTyping = StartTyping()
			end
			if gTyping then
				gScrolling = 0 -- reset scroll
				SoundPlay2D("ButtonUp")
				return true -- started typing
			end
		end
		return false -- not typing
	end
	return true -- already typing
end
function F_UpdateTyping()
	if not IsTypingActive(gTyping) then
		if not WasTypingAborted(gTyping) then
			local result = GetTypingString(gTyping) -- we want to submit this message
			gTyping = nil
			return result
		end
		gTyping = nil
		SoundPlay2D("NavInvalid")
	elseif IsConsoleActive() then -- if the console opens while typing then stop typing
		StopTyping(gTyping)
		gTyping = nil
		SoundPlay2D("NavInvalid")
	end
end
function F_UpdateScrolling()
	if IsKeyBeingPressed("PRIOR") and gScrolling < gMessages.n - 1 and F_Display(true) then
		SoundPlay2D("NavUp")
		gScrolling = gScrolling + 1
	elseif IsKeyBeingPressed("NEXT") and gScrolling > 0 and F_Display(true) then
		SoundPlay2D("NavDwn")
		gScrolling = gScrolling - 1
	end
end
function F_SubmitMessage(text)
	if string.sub(text,1,1) ~= '/' then
		local starts = string.find(text,"%S") -- check for non white space characters
		if starts then
			SendNetworkEvent("chat:SendMessage",string.sub(text,starts,GetConfigNumber(GetScriptConfig(),"max_message_length",100)+starts-1)) -- send message to server
		end
	else
		local starts,stops,cmd = string.find(text,"[/]*%s*(%S+)") -- get the command name just like the normal command parser would
		if starts then
			F_RunCommand(cmd,string.sub(text,stops+1))
		end
	end
end
function F_RunCommand(cmd,args)
	local help = GetConfigString(GetScriptConfig(),"help_text")
	local event = RegisterLocalEventHandler("ConsolePrinted",CB_ConsolePrinted)
	if help and string.lower(cmd) == "help" and not string.find(args,"%S") then
		CB_ConsolePrinted(string.gsub(help,"\\n","\n"),"output")
	elseif string.lower(cmd) == "clear" then
		gMessages = {n = 0}
	elseif not RunCommand(cmd..args) then
		F_AddMessage({r = 200,g = 50,b = 50,text = "unknown command: /"..cmd})
	end
	RemoveEventHandler(event)
end

-- Draw chat.
function T_Draw()
	local box = CreateTexture("chatbox.png")
	local banner = CreateTexture("chatbanner.png") -- same dimensions
	while true do
		if not IsPauseMenuActive() and not IsMapMenuActive() then
			F_UpdateAlpha()
			if gChatStyle == "DEFAULT" then
				F_Draw(box,banner,0.01)
			elseif gChatStyle == "HIGHER" then
				F_Draw(box,banner,0.33)
			end
		end
		Wait(0)
	end
end
function F_Draw(box,banner,offset)
	local typepadw = 0.005
	local boxh = 0.35 * F_GetBoxScale()
	local boxy = 1 - boxh - offset
	local typeh = 0.075 * boxh
	local typey = boxy + 0.97 * boxh - typeh
	local msgtopy = boxy + 0.2 * boxh
	local boxw = boxh * GetTextureDisplayAspectRatio(box)
	local boxx = 1 - boxw - 0.01 / GetDisplayAspectRatio()
	local typex = boxx + ((1 - 0.95) / 2) * boxw
	local typew = 0.95 * boxw
	local typing = gTyping and IsTypingActive(gTyping)
	if F_ShouldUseBackground() then
		DrawTexture(box,boxx,boxy,boxw,boxh,255,255,255,255*gDisplayAlpha)
	end
	if typing then
		local text = GetTypingString(gTyping)
		local typeclip = typew * (1 - typepadw)
		DrawRectangle(typex,typey,typew,typeh,0,0,0,150*gDisplayAlpha)
		F_SetupTextFont(false)
		SetTextColor(220,220,220,255*gDisplayAlpha)
		SetTextClipping(typeclip)
		SetTextHeight(typeh*0.67)
		SetTextShadow()
		if MeasureText(text) >= typeclip then
			SetTextPosition(typex+typeclip,typey+typeh/2)
			SetTextAlign("R","C")
		else
			SetTextPosition(typex+typew*typepadw,typey+typeh/2)
			SetTextAlign("L","C")
		end
		DrawText(text)
	end
	if gMessages.n ~= 0 then
		local namespace = 0.005 / GetDisplayAspectRatio()
		local y,w1,h1,w2,h2 = typey
		if not typing then
			y = y + typeh
		end
		for index = gMessages.n-gScrolling,1,-1 do
			local msg = gMessages[index]
			local oneline = gUseOneLine
			local height
			if y <= msgtopy then
				break
			end
			F_SetupTextFont(true)
			SetTextAlign("L","B")
			if msg.name then
				w1,h1 = MeasureText(msg.name) -- measure name
				w1 = w1 + namespace
			else
				w1,h1 = 0,0
			end
			height = h1
			w2,h2 = MeasureText(msg.text) -- measure text
			if oneline and typew - (w1 + w2) < 0.002 then
				oneline = false
			end
			SetTextWrapping(typew)
			w2,h2 = MeasureText(msg.text) -- re-measure with wrapping
			if oneline then
				height = math.max(h1,h2)
			else
				height = h1 + h2
			end
			if (F_ShouldUseBackground() or y - height > msgtopy) and gDisplayAlpha > 0 then
				if msg.name then
					SetTextColor(msg.r,msg.g,msg.b,255*gDisplayAlpha)
					SetTextClipping(typew,y-msgtopy)
					if oneline then
						SetTextPosition(typex,y)
						DrawText(msg.name) -- draw name
					elseif y - h2 > msgtopy then
						SetTextPosition(typex,y-h2)
						DrawText(msg.name) -- draw name
					else
						DiscardText()
					end
					F_SetupTextFont(true)
					SetTextAlign("L","B")
					SetTextColor(230,230,230,255*gDisplayAlpha)
				else
					SetTextColor(msg.r,msg.g,msg.b,255*gDisplayAlpha)
				end
				SetTextClipping(nil,y-msgtopy)
				if oneline then
					SetTextPosition(typex+w1,y)
				else
					SetTextPosition(typex,y)
					SetTextWrapping(typew)
				end
				DrawText(msg.text) -- draw text
				y = y - height
			else
				DiscardText()
			end
		end
	end
	if F_ShouldUseBackground() then
		DrawTexture(banner,boxx,boxy,boxw,boxh,255,255,255,255*gDisplayAlpha)
	end
end

-- Draw utility.
function F_Display(scroll)
	if not scroll and gScrolling > 0 then
		if gDisplayActive or gDisplayAlpha > 0 then
			return false
		end
		gScrolling = 0
	end
	if RunLocalEvent("chat:UpdateDisplay") then
		gDisplayActive = true
		gDisplayTimer = GetTimer()
		return true
	end
	return false
end
function F_UpdateAlpha()
	if gDisplayActive and GetTimer() - gDisplayTimer >= 8000 then
		gDisplayActive = false
	end
	if gDisplayActive then
		if gDisplayAlpha ~= 1 then
			gDisplayAlpha = math.min(1,gDisplayAlpha+GetFrameTime()/0.2)
		end
	elseif gDisplayAlpha ~= 0 then
		gDisplayAlpha = math.max(0,gDisplayAlpha-GetFrameTime()/0.5)
	end
end
function F_SetupTextFont(scale)
	SetTextFont(gFontFamily)
	if gFontStyle == "black" then
		SetTextBlack()
	elseif gFontStyle == "bold" then
		SetTextBold()
	end
	if not F_ShouldUseBackground() then
		SetTextShadow()
	end
	if scale then
		SetTextHeight(0.025 * gFontScale * gTextScale * gBoxScale)
	end
end
function F_GetBoxScale()
	if gChatStyle ~= "DEFAULT" then
		return math.min(gBoxScale,0.7)
	end
	return gBoxScale
end

-- Chat style.
function F_UpdateChatStyle()
	if next(gWantHigher) then
		gChatStyle = "HIGHER"
	else
		gChatStyle = gPreferStyle
	end
end
function F_ShouldUseBackground()
	if gChatStyle ~= "DEFAULT" then
		return false
	end
	return gDrawBackground
end

-- Config options.
function F_LoadConfig()
	local data = GetPersistentDataTable("Xx_Yubari_xX").chat
	if type(data) == "table" then
		if data.style ~= nil then gPreferStyle = data.style end
		if data.drawbg ~= nil then gDrawBackground = data.drawbg end
		if data.joinleaves ~= nil then gSoundJoinLeaves = data.joinleaves end
		if data.messages ~= nil then gSoundMessages = data.messages end
		if data.arrow ~= nil then gArrowDirect = data.arrow end
		if data.text ~= nil then gTextScale = data.text end
		if data.box ~= nil then gBoxScale = data.box end
	end
	F_UpdateChatStyle()
end
function F_SaveConfig()
	local persist = GetPersistentDataTable("Xx_Yubari_xX")
	local data = persist.chat
	if type(data) ~= "table" then
		data = {}
		persist.chat = data
	end
	data.style = gPreferStyle
	data.drawbg = gDrawBackground
	data.joinleaves = gSoundJoinLeaves
	data.messages = gSoundMessages
	data.arrow = gArrowDirect
	data.text = gTextScale
	data.box = gBoxScale
	SavePersistentDataTables()
end

-- Console output.
function CB_ConsolePrinted(message,type)
	if gAllowOutput then
		if type == "output" then
			F_AddMessage({text = message,r = gFontRgb,g = gFontRgb,b = gFontRgb})
		elseif type == "error" then
			F_AddMessage({text = message,r = 200,g = 50,b = 50})
		elseif type == "warning" then
			F_AddMessage({text = message,r = 200,g = 150,b = 50})
		elseif type == "special" then
			F_AddMessage({text = message,r = 50,g = 150,b = 200})
		end
	end
end

-- Server settings.
RegisterNetworkEventHandler("chat:SetSilent",function(on)
	gSilentMode = on ~= nil
end)
RegisterNetworkEventHandler("chat:SetGlobal",function(on)
	gGlobalMessages = on ~= nil
end)
RegisterNetworkEventHandler("chat:SetDirect",function(on)
	gDirectMessages = on ~= nil
end)
RegisterNetworkEventHandler("chat:SetStatus",function(on)
	gStatusMessages = on ~= nil
end)

-- F2 Menu.
RegisterLocalEventHandler("f2menu:Open",function(f_add)
	f_add({
		name = "Chat Preferences",
		description = "Customize chat appearance, toggle certain messages, or enter silent mode.",
		thread = M_Preferences,
	})
end)
function M_Preferences(parent,selected)
	local menu = parent:submenu(selected.name)
	while menu:active() do
		if menu:option("Silent Mode",gSilentMode and "[ON]" or "[OFF]","Don't show the chat at all, for any reason.\n(temporary setting)") then
			if gSilentMode then
				SendNetworkEvent("chat:SetSilent")
			else
				SendNetworkEvent("chat:SetSilent",true)
			end
		elseif menu:option("Customize Appearance",nil,"Open the chat appearance menu.") then
			M_Appearance(menu)
		elseif menu:option("Notification Sounds",nil,"Decide which chat events make sounds.") then
			M_Sounds(menu)
		elseif menu:option("Show Global Messages",gGlobalMessages and "[ON]" or "[OFF]","Receive global chat messages.") then
			if gGlobalMessages then
				SendNetworkEvent("chat:SetGlobal")
			else
				SendNetworkEvent("chat:SetGlobal",true)
			end
		elseif menu:option("Show Direct Messages",gDirectMessages and "[ON]" or "[OFF]","Receive direct chat messages.") then
			if gDirectMessages then
				SendNetworkEvent("chat:SetDirect")
			else
				SendNetworkEvent("chat:SetDirect",true)
			end
		elseif menu:option("Show Joins / Leaves",gStatusMessages and "[ON]" or "[OFF]","Receive player join / leave statuses.") then
			if gStatusMessages then
				SendNetworkEvent("chat:SetStatus")
			else
				SendNetworkEvent("chat:SetStatus",true)
			end
		end
		menu:draw()
		Wait(0)
	end
end
function M_Appearance(parent)
	local menu = parent:submenu("Customize Appearance")
	while menu:active() do
		if menu:option("Direct Message Indication",gArrowDirect and "[-->]" or "[DM]","Text shown in front of direct messages. Only applies to future direct messages.") then
			gArrowDirect = not gArrowDirect
			F_SaveConfig()
			F_Display()
		elseif menu:option("Preferred Style","["..gPreferStyle.."]","Visual style you prefer when not overridden.") then
			if gPreferStyle == "DEFAULT" then
				gPreferStyle = "HIGHER"
			else
				gPreferStyle = "DEFAULT"
			end
			F_UpdateChatStyle()
			F_SaveConfig()
			F_Display()
		elseif gPreferStyle == "DEFAULT" and menu:option("Hide Background",gDrawBackground and "[OFF]" or "[ON]","If the background of the chat box itself should be hidden.") then
			gDrawBackground = not gDrawBackground
			F_SaveConfig()
			F_Display()
		elseif menu:option("Text Size",string.format("[x%.1f]",gTextScale),"The font size within the chat box.") then
			gTextScale = F_AdjustScale(gTextScale)
			F_SaveConfig()
			F_Display()
		elseif menu:option("Box Size",string.format("[x%.1f]",gBoxScale),"The size of the chat box itself.") then
			gBoxScale = F_AdjustScale(gBoxScale)
			F_SaveConfig()
			F_Display()
		end
		menu:draw()
		Wait(0)
	end
end
function M_Sounds(parent)
	local menu = parent:submenu("Notification Sounds")
	while menu:active() do
		if menu:option("Join / Leave Sounds",gSoundJoinLeaves and "[ON]" or "[OFF]","Play a sound when a player joins or leaves.") then
			gSoundJoinLeaves = not gSoundJoinLeaves
			F_SaveConfig()
			F_Display()
		elseif menu:option("Player Message Sounds",gSoundMessages and "[ON]" or "[OFF]","Play a sound when a player joins or leaves.") then
			gSoundMessages = not gSoundMessages
			F_SaveConfig()
			F_Display()
		end
		menu:draw()
		Wait(0)
	end
end
function F_AdjustScale(scale)
	scale = math.floor(scale * 10 + 1) / 10
	if scale > 1.2 then
		return 0.5
	end
	return scale
end

-- Add messages.
RegisterNetworkEventHandler("chat:PlayerJoined",function(name)
	if F_AddMessage({text = name.." has joined the game.",r = gFontRgb,g = gFontRgb,b = gFontRgb}) and gSoundJoinLeaves then
		gPlaySound = "RightBtn"
	end
end)
RegisterNetworkEventHandler("chat:PlayerLeft",function(name)
	if F_AddMessage({text = name.." has left the game.",r = gFontRgb,g = gFontRgb,b = gFontRgb}) and gSoundJoinLeaves then
		gPlaySound = "WrongBtn"
	end
end)
RegisterNetworkEventHandler("chat:PlayerMessage",function(name,message,r,g,b)
	if F_AddMessage({name = name..":",text = message,r = r,g = g,b = b}) and gSoundMessages then
		gPlaySound = "ButtonDown"
	end
end)
RegisterNetworkEventHandler("chat:ServerMessage",function(message,r,g,b)
	if F_AddMessage({text = message,r = r or gFontRgb,g = g or gFontRgb,b = b or gFontRgb}) and gSoundMessages then
		gPlaySound = "ButtonDown"
	end
end)
RegisterNetworkEventHandler("chat:DirectMessage",function(name,message,r,g,b,self)
	if not gArrowDirect then
		name = "[DM] "..name..":"
	elseif self then
		name = "[You --> "..self.."]"
	else
		name = "[You <-- "..name.."]"
	end
	if F_AddMessage({name = name,text = message,r = r,g = g,b = b}) and gSoundMessages then
		gPlaySound = "ButtonDown"
	end
end)
RegisterNetworkEventHandler("chat:DenyMessage",function(direct)
	if direct then
		F_AddMessage({text = "You have direct messages disabled.",r = 200,g = 50,b = 50})
	else
		F_AddMessage({text = "You have global messages disabled.",r = 200,g = 50,b = 50})
	end
end)
RegisterNetworkEventHandler("chat:DenyDirect",function(found)
	if found then
		F_AddMessage({text = "This user is not receiving direct messages.",r = 200,g = 50,b = 50})
	else
		F_AddMessage({text = "Unknown username, or user is not online.",r = 200,g = 50,b = 50})
	end
end)
RegisterNetworkEventHandler("chat:DenyReply",function()
	F_AddMessage({text = "No player to reply to, or they went offline.",r = 200,g = 50,b = 50})
end)
function F_AddMessage(msg)
	if gMessages.n >= 100 then
		table.remove(gMessages,1)
	end
	if gScrolling > 0 and gScrolling < 99 then
		gScrolling = gScrolling + 1
	end
	table.insert(gMessages,msg)
	return F_Display()
end

-- Script cleanup.
RegisterLocalEventHandler("ScriptDestroyed",function(script)
	gWantHigher[script] = nil
	F_UpdateChatStyle()
end)

-- Block utility.
RegisterNetworkEventHandler("chat:SetBlocks",function(users)
	gBlocks = {}
	for _,user in ipairs(users) do
		gBlocks[user] = true
	end
end)
RegisterNetworkEventHandler("chat:SetBlock",function(user,blocked)
	if blocked then
		if not gBlocks[user] then
			F_Output(true,"blocked "..user)
		end
	elseif gBlocks[user] then
		F_Output(true,"unblocked "..user)
	else
		F_Output(false,"failed to block user")
	end
	gBlocks[user] = blocked
end)
function F_GetBlocks()
	local blocks = {}
	for user in pairs(gBlocks) do
		table.insert(blocks,user)
	end
	table.sort(blocks)
	return table.concat(blocks,", ")
end

-- Command functions.
function F_Output(output,str)
	if output then
		CB_ConsolePrinted(str,"output")
		gAllowOutput = false
		PrintOutput(str)
	else
		CB_ConsolePrinted(str,"error")
		gAllowOutput = false
		PrintError(str)
	end
	gAllowOutput = true
end
function F_SplitUser(str)
	if str then
		local found,finish,user = string.find(str,"(%S+)%s*")
		if found then
			if string.len(str) > finish then
				return user,string.sub(str,finish+1)
			end
			F_Output(false,"expected message after username")
			return
		end
	end
	F_Output(false,"expected username and message")
end
function CB_Whisper(arg)
	local user,message = F_SplitUser(arg)
	if user then
		SendNetworkEvent("chat:SendWhisper",user,message)
	end
end
function CB_Reply(message)
	if message then
		SendNetworkEvent("chat:SendReply",message)
	else
		F_Output(false,"expected message")
	end
end
function CB_Block(user)
	if user then
		SendNetworkEvent("chat:BlockUser",user)
	elseif next(gBlocks) then
		F_Output(true,"blocked users: "..F_GetBlocks())
	else
		F_Output(true,"no blocked users")
	end
end
function CB_Unblock(user)
	if user then
		SendNetworkEvent("chat:UnblockUser",user)
	else
		F_Output(false,"expected username")
	end
end

-- Register commands.
SetCommand("w",CB_Whisper,true,"Usage: w <user> <message...>\nShortcut for /whisper.")
SetCommand("whisper",CB_Whisper,true,"Usage: whisper <user> <message...>\nSend a direct message to a user.")
SetCommand("r",CB_Reply,true,"Usage: r <message...>\nShortcut for /reply.")
SetCommand("reply",CB_Reply,true,"Usage: reply <message...>\nReply to the last person to send you a direct message.")
SetCommand("block",CB_Block,false,"Usage: block [user]\nBlock all messages from a user, or list all blocks if no username is given.")
SetCommand("unblock",CB_Unblock,false,"Usage: unblock <user>\nUnblocks a user, so you can see their messages again.")

-- Exported functions.
function exports.Raise(force)
	if type(force) ~= "boolean" then
		typerror(1,"boolean")
	end
	gWantHigher[GetCurrentScript()] = force or nil
	F_UpdateChatStyle()
end
function exports.Say(message)
	if F_AddMessage({text = message,r = gFontRgb,g = gFontRgb,b = gFontRgb}) and gSoundMessages then
		gPlaySound = "ButtonDown"
	end
end
function exports.Hide()
	if gDisplayActive then
		gDisplayActive = false
		gDisplayAlpha = 0
	end
	if gTyping then
		if IsTypingActive(gTyping) then
			StopTyping(gTyping)
		end
		gTyping = nil
	end
end
