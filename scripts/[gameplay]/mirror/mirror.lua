gActive = false

function main()
	while true do
		if IsKeyBeingPressed("F5") then
			F_SetActive(not gActive)
		end
		Wait(0)
	end
end
function MissionCleanup()
	SetMirrorMode(false)
end

function F_SetActive(active)
	if gActive ~= active then
		if gActive then
			TerminateThread(gThread)
			gThread = nil
		else
			gThread = CreateAdvancedThread("POST_WORLD","T_Mirror")
		end
		SetMirrorMode(active)
		gActive = active
	end
end
function T_Mirror()
	local screen,cw,ch
	while true do
		local nw,nh = GetDisplayResolution()
		if nw ~= cw or nh ~= ch then
			screen = nil
			screen = CreateRenderTarget(nw,nh)
			cw,ch = nw,nh
		end
		DrawBackBufferOntoTarget(screen)
		SetRendererAlphaBlending(false)
		ClearDisplay()
		DrawTexture(screen,1,0,-1,1,255,255,255,255)
		SetRendererAlphaBlending(true)
		Wait(0)
	end
end
