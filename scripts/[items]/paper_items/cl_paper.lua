local gWriting
local gReading
local gTexture = "paper.png"
local gSound = false

TEXT_LIMIT = GetConfigNumber(GetScriptConfig(),"max_length",560)
DESCRIPTION_LIMIT = GetConfigNumber(GetScriptConfig(),"max_description",30)

RegisterLocalEventHandler("inventory:Use",function(slot,id)
	if id == "blank_paper" then
		if not (gReading or gWriting) then
			local typing = StartTyping()
			if typing then
				gTexture = "paper.png"
				gWriting = {typing,slot,id}
			end
			gSound = true
		end
		return true
	elseif id == "written_paper" then
		gSound = true
	end
end)
RegisterLocalEventHandler("inventory:Text",function(id,str,result)
	if id == "written_paper" then
		local length = utf8.len(str)
		local extra = false
		if not length then
			str,extra = "",true
		elseif length > DESCRIPTION_LIMIT then
			local i = utf8.offset(str,DESCRIPTION_LIMIT)
			while i >= 1 and string.sub(str,i,i) ~= ' ' and string.sub(str,i,i) ~= '\n' do
				i = i - 1
			end
			while string.sub(str,i,i) == ' ' do
				i = i - 1
			end
			if i >= 1 then
				str = string.sub(str,1,i)
			else
				str = ""
			end
			extra = true
		end
		length = string.find(str,"\n",1,true)
		if length then
			str,extra = string.sub(str,1,length-1),true
		end
		if extra then
			result.text = "\""..str.."...\""
		else
			result.text = "\""..str.."\""
		end
	end
end)
RegisterNetworkEventHandler("paper_items:ReadPaper",function(text)
	if not (gReading or gWriting) then
		gTexture = "paper.png"
		gReading = {tostring(text),true}
	end
end)
RegisterNetworkEventHandler("paper_items:ReadRelease",function()
	if not (gReading or gWriting) then
		gTexture = "paper_v1release.png"
		gReading = {"",true}
	end
end)

function main()
	local paper
	local texture
	local event
	local alpha = 0
	while true do
		if gReading or gWriting then
			if not paper then
				texture = gTexture
				paper = CreateTexture(texture)
				event = RegisterLocalEventHandler("ControllerUpdating",CB_ControllerUpdating)
			end
			if texture ~= gTexture then
				texture = gTexture
				paper = CreateTexture(texture)
			end
			if (gReading and not gReading[2]) or (gWriting and not IsTypingActive(gWriting[1]) and not IsButtonBeingPressed(8,0)) then
				if gWriting and gWriting[3] then
					if IsTypingActive(gWriting[1]) then
						gWriting[3] = nil -- must have hit cancel (button 8)
					elseif not WasTypingAborted(gWriting[1]) then
						local text = F_LimitString(GetTypingString(gWriting[1]))
						if string.find(text,"%S") then
							SendNetworkEvent("paper_items:WritePaper",gWriting[3],gWriting[2],F_FormatText(text))
						end
						gWriting[3] = nil
					end
				end
				alpha = alpha - GetFrameTime() / 0.1
				if alpha <= 0 then
					alpha = 0
					gReading = nil
					gWriting = nil
				end
			elseif alpha < 1 then
				alpha = alpha + GetFrameTime() / 0.2
				if alpha > 1 then
					alpha = 1
				end
			end
			if gReading then
				F_DrawPaper(paper,gReading[1],255*alpha)
			elseif gWriting then
				F_DrawPaper(paper,F_FormatText(F_LimitString(GetTypingString(gWriting[1],true))),255*alpha)
			end
		elseif paper then
			RemoveEventHandler(event)
			paper = nil
			event = nil
		end
		if gSound then
			SoundPlay2D("KickMeDrop")
			gSound = false
		end
		Wait(0)
	end
end
function CB_ControllerUpdating(c)
	if gReading and c == 0 then
		if IsButtonPressed(8,0) then
			gReading[2] = false
		end
		for b = 0,15 do
			SetButtonPressed(b,0,false)
		end
	end
end
function F_DrawPaper(paper,text,alpha)
	local padding = 0.05
	local ar = GetDisplayAspectRatio()
	local height = 0.8
	local width = height * GetTextureDisplayAspectRatio(paper)
	local x = 0.5 - width * 0.5
	local y = 0.5 - height * 0.5
	SetDrawLayer("PRE_FADE2")
	DrawTexture(paper,0.5-width*0.5,0.5-height*0.5,width,height,255,255,255,alpha)
	x = x + padding / ar
	y = y + padding
	width = width - (padding * 2) / ar
	height = height - padding * 2
	SetTextFont("Segoe Print")
	SetTextColor(0,0,0,alpha)
	SetTextAlign("L","T")
	SetTextPosition(x,y)
	SetTextWrapping(width)
	SetTextClipping(nil,height)
	DrawText(text)
end
function F_LimitString(str)
	local length = utf8.len(str)
	if length then
		if length > TEXT_LIMIT then
			return string.sub(str,1,utf8.offset(str,TEXT_LIMIT))
		end
		return str
	end
	return ""
end
function F_FormatText(str)
	return string.gsub(string.gsub(str,"\t",""),"\\n","\n")
end
