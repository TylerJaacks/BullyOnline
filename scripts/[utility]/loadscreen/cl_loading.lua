BACKGROUNDS = {
	{4 / 3, "4x3.png"},
	{16 / 9, "16x9.png"},
	{21 / 9, "21x9.png"},
}

CreateDrawingThread(function()
	local background,aspect = F_LoadBackground()
	while IsNetworkLoading() do
		F_DrawBackground(background,aspect)
		F_DrawProgress(GetDownloadProgress())
		Wait(0)
	end
end)
function F_LoadBackground()
	local best,dif
	local ar = GetDisplayAspectRatio()
	for _,v in ipairs(BACKGROUNDS) do
		local d = math.abs(v[1] - ar)
		if not best or d < dif then
			best,dif = v,d
		end
	end
	return CreateTexture(best[2]),best[1]
end
function F_DrawBackground(background,aspect)
	local w,h = GetDisplayResolution()
	if w / h < aspect then
		w = ((h - w / aspect) * aspect) / w
		DrawTexture(background,-w*0.5,0,w+1,1,255,255,255,255)
	elseif w / h > aspect then
		h = ((w - h * aspect) / aspect) / h
		DrawTexture(background,0,-h*0.5,1,h+1,255,255,255,255)
	else
		DrawTexture(background,0,0,1,1,255,255,255,255)
	end
end
function F_DrawProgress(progress)
	local ar = GetDisplayAspectRatio()
	local x = 0.5 + 0.3 / ar
	local y = 0.2
	local w = 0.4 / ar
	local h = 0.04
	if ar < 16 / 9 then
		x = x - 0.2 / ar
	end
	DrawRectangle(x,y,w,h,0,0,0,255)
	DrawRectangle(x,y,w*progress,h,200,0,200,255)
	SetTextFont("Arial")
	SetTextBlack()
	SetTextColor(255,255,255,255)
	SetTextOutline()
	SetTextAlign("R","C")
	SetTextPosition(x+w-0.004/ar,y+h*0.5)
	SetTextHeight(h*0.9)
	DrawText(math.floor(progress*100).."%")
end
