-- f2menu registry
RegisterNetworkEventHandler("set_chapter:GivePermission",function()
	RegisterLocalEventHandler("f2menu:Open",function(f_add)
		f_add({
			name = "Set Chapter",
			description = "(admin only)\nSet the current chapter.",
			thread = O_SetChapter,
		})
	end)
end)

-- chapter option
function O_SetChapter(menu)
	local c = ChapterGet()
	while menu:active() do
		menu:draw("> "..c.." <")
		Wait(0)
		if menu:up() then
			c = math.mod(c+1,7)
		elseif menu:down() then
			c = c - 1
			if c < 0 then
				c = 6
			end
		elseif menu:left() then
			break
		elseif menu:right() then
			SendNetworkEvent("set_chapter:SetChapter",c)
			break
		end
	end
end

-- request permission
SendNetworkEvent("set_chapter:RequestPermission")
