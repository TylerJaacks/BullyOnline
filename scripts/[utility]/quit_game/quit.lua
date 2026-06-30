function main()
	while true do
		if (IsKeyPressed("LALT") or IsKeyPressed("RALT")) and IsKeyBeingPressed("F4") then
			QuitGame()
		end
		Wait(0)
	end
end
RegisterLocalEventHandler("f2menu:Open",function(f_add)
	f_add({
		name = "Quit Game",
		description = "Instantly shut down the game.",
		func = function()
			QuitGame()
		end,
	})
end)
