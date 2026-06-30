gHudless = false
gScale = {}

gAreas = {
	[0] = "MainMap","Everywhere","School_Hallways","X_Caf_Kitchen","Chem_Lab","Principal","Bio_Lab","X_Infirmary",
	"Janitors_Room","Library","X_Bathroom_1st_Floor","X_Bathroom_2nd_Floor","X_Wrestling_Gym","Pool","Boys_Dorm","classroom",
	"Trailer","Art_Room","Auto_Shop","Auditorium","Chem_Plant","X_Nerd_Fortress","Island_3","Staff_Room",
	"X_Attic","X_Funhouse","GroceryStore","BoxingRing","Fire_Works","Bike_Shop_Rich","Comic_Shop_Rich","Test_Area",
	"Prep_House","Rich_Cloth","Poor_Cloth","Girls_Dorm","Tenement","HouseOfMirrors","Asylum","Barber",
	"Observatory","X_IGOKart","TGOKart","JunkYard","iLPstore","Midway","Hair_Salon","X_Underwater",
	"X_GoKart2","X_Gift_Shop","Souvenir","iMGRaceA","iMGRaceB","iMGRaceC","WareHouse","Freak_Show",
	"Poor_Hair","iDropS","X_iNerdS","iJockS","iPrepS","iGrsrS","BMXTrack","X_Library2",
}
gAreas.n = table.getn(gAreas)
gAreaScripts = {
	[0] = true,
	[2] = true,
	[4] = true,
	[5] = true,
	[6] = true,
	[8] = true,
	[9] = true,
	[13] = true,
	[14] = true,
	[15] = true,
	[16] = true,
	[17] = true,
	[18] = true,
	[19] = true,
	[20] = true,
	[23] = true,
	[26] = true,
	[27] = true,
	[29] = true,
	[30] = true,
	[32] = true,
	[33] = true,
	[34] = true,
	[35] = true,
	[36] = true,
	[37] = true,
	[38] = true,
	[39] = true,
	[40] = true,
	[42] = true,
	[43] = true,
	[45] = true,
	[46] = true,
	[50] = true,
	[51] = true,
	[52] = true,
	[53] = true,
	[54] = true,
	[55] = true,
	[56] = true,
	[57] = true,
	[59] = true,
	[60] = true,
	[61] = true,
	[62] = true,
}
gAreaTransition = false
gWeapons = {
	{299,"yardstick"},
	{300,"bat"},
	{301,"cherryb"},
	{302,"baseball"},
	{303,"slingshot"},
	{304,"marble"},
	{305,"spudg"},
	{306,"supersling"},
	{307,"brocketlauncher"},
	{308,"brocket"},
	{309,"stinkbomb"},
	{310,"apple"},
	{311,"brick"},
	{312,"eggproj"},
	{313,"snowball"},
	{314,"yardstick_DMG"},
	{315,"lid"},
	{316,"potato"},
	{317,"bat_DMG"},
	{318,"dodgeball"},
	{320,"newsroll"},
	{321,"spraycan"},
	{322,"supermarble"},
	{323,"twobyfour"},
	{324,"sledgehammer"},
	{325,"RBandBall"},
	{326,"fireexting"},
	{327,"bbagbottle"},
	{328,"WCamera"},
	{329,"SocBall"},
	{330,"SnwBallB"},
	{331,"Wftball"},
	{332,"Wmallet"},
	{335,"Wfrisbee"},
	{336,"cricket_DMG"},
	{337,"chemical"},
	{338,"Wdish"},
	{339,"Cigarette"},
	{341,"pompom"},
	{342,"wtrpipe"},
	{343,"garbpick"},
	{345,"WHatSVase"},
	{346,"W_DeadRat"},
	{348,"Wtray"},
	{349,"BagMrbls"},
	{350,"flask"},
	{351,"chem_stir"},
	{352,"Eyedrop"},
	{353,"PlantPot"},
	{354,"pVase_proj"},
	{355,"dec_plate"},
	{356,"pPlant_proj"},
	{357,"cricket"},
	{358,"Banana"},
	{359,"Flowerbund"},
	{360,"Psheild"},
	{363,"teddybear"},
	{372,"kickme"},
	{377,"JBroom"},
	{378,"AniFooty"},
	{381,"ANIBBALL"},
	{383,"WBalloon"},
	{384,"wtrpipeD"},
	{385,"trophy"},
	{387,"CHShieldA"},
	{388,"CHShieldB"},
	{389,"CHShieldC"},
	{390,"WHatVase"},
	{391,"bbgun"},
	{394,"W_Itch"},
	{395,"W_PGun"},
	{396,"SuperSpudG"},
	{397,"W_Fountain"},
	{399,"PooBag"},
	{400,"WFtBomb"},
	{401,"wtrpipeC"},
	{402,"wtrpipeB"},
	{403,"W_TPRoll"},
	{404,"Umbrella"},
	{405,"NerdBooks"},
	{409,"DevilFork"},
	{410,"PinkyWand"},
	{411,"SSWhip"},
	{412,"BoltCutters"},
	{413,"NerdBooksB"},
	{414,"NerdBooksC"},
	{415,"NerdBooksD"},
	{416,"NerdBooksE"},
	{417,"Detonator"},
	{418,"leadpipe"},
	{420,"W_Flashlight"},
	{422,"JBroom_DMG"},
	{425,"Wgascan"},
	{426,"WDigCam"},
	{432,"W_diary"},
	{433,"Stwins_bad"},
	{435,"twobyfour_DMG"},
	{437,"SK8Board"},
}

-- f2menu registry
RegisterNetworkEventHandler("admin_miscellaneous:Allow",function()
	local thread,event
	SetCommand("tp",CB_TeleportCommand,true,"Usage: tp <x> <y> <z> [h]\nTeleport to specific coordinates.")
	RegisterLocalEventHandler("f2menu:Open",function(f_add)
		f_add({
			name = "Give Weapon",
			description = "(admin only)\nGive yourself a weapon.",
			thread = M_GiveWeapon,
		})
		f_add({
			name = "Swap Area",
			description = "(admin only)\nGo to a different area.",
			thread = M_SwapArea,
		})
		f_add({
			name = "Swap Area (advanced)",
			description = "(admin only)\nSwitch to any area without changing your coordinates.",
			thread = M_SwapAreaAdvanced,
		})
		f_add({
			name = "Reset Health",
			description = "(admin only)\nReset your health to full.",
			func = F_ResetHealth,
		})
		f_add({
			name = "Show Coordinates",
			right = thread and "[ON]" or "[OFF]",
			description = "(admin only)\nShow your coordinates. You can hit Ctrl+C while open to copy.",
			func = function(menu,option)
				if thread then
					option.right = "[OFF]"
					RemoveEventHandler(event)
					TerminateThread(thread)
					thread = nil
				else
					option.right = "[ON]"
					event = RegisterLocalEventHandler("ControllerUpdating",CB_ControllerCoords)
					thread = CreateThread("T_ShowCoords")
				end
			end,
		})
		f_add({
			name = "Show HUD",
			right = gHudless and "[OFF]" or "[ON]",
			description = "(admin only)\nTurn off hud by setting the game to \"widescreen\" mode.",
			func = function(menu,option)
				gHudless = not gHudless
				option.right = gHudless and "[OFF]" or "[ON]"
				CameraSetWidescreen(gHudless)
			end,
		})
		f_add({
			name = "Force View Distance",
			description = "(admin only)\nForce the highest view distance.",
			func = function()
				for h = 0,23 do
					for s = 0,3 do
						for w = 0,5 do
							local tc = GetTimecycle(h,s,w)
							tc.farclip = 32767
							tc.nearfarratio = 65534
						end
					end
				end
				for a = 0,23 do
					for i = 0,2 do
						local tc = GetExtraTimecycle(a,i)
						tc.farclip = 32767
						tc.nearfarratio = 65534
					end
				end
			end,
		})
		f_add({
			name = "Set Scale",
			description = "(admin only)\nSet your scale. Totally not a waste of development time. <3",
			thread = function(menu)
				local typing = StartTyping()
				if typing then
					while menu:active() do
						if not IsTypingActive(typing) then
							if not WasTypingAborted(typing) then
								local scale = tonumber(GetTypingString(typing))
								if scale then
									SendNetworkEvent("admin_miscellaneous:Scale",scale)
								end
							end
							break
						end
						menu:draw(GetTypingString(typing,true))
						Wait(0)
					end
				end
			end,
		})
		f_add({
			name = "Step Forward",
			description = "(admin only)\nMove slightly forward.",
			func = function()
				local h,x,y,z = PedGetHeading(gPlayer),PlayerGetPosXYZ()
				PedSetPosSimple(gPlayer,x-math.sin(h),y+math.cos(h),z)
			end,
		})
		f_add({
			name = "Set Time",
			description = "(admin only)\nSet the current time.",
			thread = O_SetTime,
		})
	end)
	CreateThread(function()
		while true do
			if IsKeyBeingPressed("F4") then
				gHudless = not gHudless
				CameraSetWidescreen(gHudless)
			end
			Wait(0)
		end
	end)
end)
RegisterNetworkEventHandler("admin_miscellaneous:Super",function()
	RegisterLocalEventHandler("f2menu:Open",function(f_add)
		f_add({
			name = "Call For Announcement",
			description = "(superadmin only)\nTeleport everyone to the auditorium.",
			func = function()
				SendNetworkEvent("admin_miscellaneous:Auditorium")
			end,
		})
	end)
end)

-- cleanup
function MissionCleanup()
	if gAreaTransition then
		AreaDisableCameraControlForTransition(false)
	end
end

-- ped scale
RegisterLocalEventHandler("sync:DeletePed",function(ped)
	gScale[ped] = nil
end)
RegisterLocalEventHandler("PedUpdateMatrix",function(ped)
	local scale = gScale[PedGetSyncPed(ped)]
	if scale then
		local m = mat3()
		if scale < 0 then
			m[1][1] = -scale
			m[2][2] = -scale
			m[3][3] = 1
		else
			m[1][1] = scale
			m[2][2] = scale
			m[3][3] = scale
		end
		PedSetMatrix(ped,PedGetMatrix(ped)*m)
	end
end)
RegisterNetworkEventHandler("admin_miscellaneous:Scale",function(scale)
	gScale = scale
end)

-- teleport
function CB_TeleportCommand(str)
	local x,y,z,h
	local pos = {}
	for v in string.gfind(str,"([%-%d%.]+)[%s,]*") do
		table.insert(pos,v)
	end
	x = tonumber(pos[1])
	y = tonumber(pos[2])
	z = tonumber(pos[3])
	h = tonumber(pos[4])
	if x and y and z then
		local area = GetAreaFromPosition(x,y,z) or AreaGetVisible()
		if AreaIsLoading() then
			PrintError("busy, try again")
		else
			CreateThread(function()
				while AreaIsLoading() do
					Wait(0)
				end
				PlayerSetPosXYZArea(x,y,z,area)
				AreaDisableCameraControlForTransition(true)
				gAreaTransition = true
				while AreaIsLoading() do
					Wait(0)
				end
				AreaDisableCameraControlForTransition(false)
				gAreaTransition = false
				if h then
					PedFaceHeading(gPlayer,h,0)
				end
				PlayerSetPosXYZ(x,y,z)
				CameraReturnToPlayer()
			end)
		end
	else
		PrintError("invalid position")
	end
end

-- give weapon
function M_GiveWeapon(parent,selected)
	local menu = parent:submenu(selected.name,selected.description)
	while menu:active() do
		for _,v in ipairs(gWeapons) do
			if menu:option("["..v[1].."] "..v[2]) then
				PedSetWeapon(gPlayer,v[1],100)
			end
		end
		menu:draw()
		Wait(0)
	end
end

-- area swaps
function M_SwapArea(parent,selected)
	local areas = {}
	local menu = parent:submenu(selected.name,selected.description)
	for i = 0,shared.areaTable.size-1 do
		table.insert(areas,shared.areaTable[i])
	end
	table.sort(areas,function(a,b)
		if a.zone ~= b.zone then
			return a.zone < b.zone
		end
		return string.lower(a.name) < string.lower(b.name)
	end)
	while menu:active() do
		for _,area in ipairs(areas) do
			if menu:option("["..area.zone.."] "..area.name) and not AreaIsLoading() then
				CameraFade(200,0)
				PlayerSetPosXYZArea(area.x,area.y,area.z,area.zone)
				AreaDisableCameraControlForTransition(true)
				gAreaTransition = true
				while AreaIsLoading() do
					menu:draw(true)
					Wait(0)
				end
				AreaDisableCameraControlForTransition(false)
				gAreaTransition = false
				PlayerFaceHeading(area.h)
				CameraFade(200,1)
			end
		end
		menu:draw()
		Wait(0)
	end
end
function M_SwapAreaAdvanced(parent,selection)
	local menu = parent:submenu(selection.name,selection.description)
	while menu:active() do
		for area = 0,gAreas.n do
			if menu:option("["..area.."] "..gAreas[area]) and not AreaIsLoading() then
				local x,y,z = PlayerGetPosXYZ()
				local event = RegisterLocalEventHandler("ScriptImporting",F_SetupAreaScriptHack(area))
				if not gAreaScripts[area] then
					AreaRegisterAreaScript(area,"AreaScripts/hack.lua")
				end
				PlayerSetPosXYZArea(x,y,z,area)
				AreaDisableCameraControlForTransition(true)
				gAreaTransition = true
				while AreaIsLoading() do
					Wait(0)
				end
				AreaDisableCameraControlForTransition(false)
				gAreaTransition = false
				RemoveEventHandler(event)
			end
		end
		menu:draw()
		Wait(0)
	end
end
function F_SetupAreaScriptHack(area)
	return function(script)
		if script.name ~= "AreaScripts/hack.lua" then
			return
		end
		script.chunk = function()
			main = function()
				AreaSignalAreaTransitionReadyToLoad()
				shared.gAreaDATFileLoaded[area] = true
				shared.gAreaDataLoaded = true
				while AreaGetVisible() == area and not SystemShouldEndScript() do
					Wait(0)
				end
				shared.gAreaDataLoaded = false
				shared.gAreaDATFileLoaded[area] = false
				collectgarbage()
			end
		end
	end
end

-- menu options
function F_ResetHealth()
	SendNetworkEvent("admin_miscellaneous:Heal")
end

-- show coords
function CB_ControllerCoords(c)
	if c == 0 and IsKeyPressed("LCONTROL",0) then
		SetKeyPressed("C",0,false)
	end
end
function T_ShowCoords()
	while true do
		local w,h
		local copy = IsKeyPressed("LCONTROL") and IsKeyBeingPressed("C")
		SetDrawLayer("PRE_FADE2")
		SetTextFont("Cascadia Code")
		SetTextBold()
		SetTextColor(255,255,255,255)
		SetTextAlign("C","T")
		SetTextPosition(0.5,0.0)
		if dsl.freecam and dsl.freecam.IsActive() then
			local x1,y1,z1 = dsl.freecam.GetPosition()
			local x2,y2,z2 = dsl.freecam.GetPosition(0,10,0)
			if copy then
				SetClipboard(string.format("%.2f, %.2f, %.2f, %.2f, %.2f, %.2f",x1,y1,z1,x2,y2,z2))
			end
			w,h = DrawText("Freecam Position: %.2f, %.2f, %.2f\nFreecam Target: %.2f, %.2f, %.2f",x1,y1,z1,x2,y2,z2)
		else
			local prefix,x,y,z = F_GetCoords()
			local heading = math.deg(PedGetHeading(gPlayer))
			local area = AreaGetVisible()
			local area2 = GetAreaFromPosition(x,y,z)
			if copy then
				SetClipboard(string.format("%.2f, %.2f, %.2f, %.1f",x,y,z,heading))
			end
			if area == area2 then
				w,h = DrawText(prefix.." XYZ(H): %.2f, %.2f, %.2f (%.1f)\nArea: %d (%s)",x,y,z,heading,area,GetAreaName(area))
			elseif area2 then
				w,h = DrawText(prefix.." XYZ(H): %.2f, %.2f, %.2f (%.1f)\nArea By Position: %d (%s)\nArea By Bounding Box: %d (%s)",x,y,z,heading,area,GetAreaName(area),area2,GetAreaName(area2))
			else
				w,h = DrawText(prefix.." XYZ(H): %.2f, %.2f, %.2f (%.1f)\nArea By Position: %d (%s)\nArea By Bounding Box: none",x,y,z,heading,area,GetAreaName(area))
			end
		end
		SetDrawLayer("PRE_FADE")
		DrawRectangle(0.5-w/2,0,w,h,0,0,0,200)
		Wait(0)
	end
end
function F_GetCoords()
	local vehicle = VehicleFromDriver(gPlayer)
	if VehicleIsValid(vehicle) then
		return "Vehicle",VehicleGetPosXYZ(vehicle)
	end
	return "Player",PlayerGetPosXYZ()
end

-- time
function O_SetTime(menu)
	local h,m = ClockGet()
	m = m + h * 60
	while menu:active() do
		menu:draw(string.format("> %d:%.2d %s <",math.floor(m/60),math.mod(m,60),m < 720 and "A.M." or "P.M."))
		Wait(0)
		if menu:up() then
			m = (m - math.mod(m,15)) + 15
			if m > 1425 then
				m = 0
			end
		elseif menu:down() then
			local r = math.mod(m,15)
			if r ~= 0 then
				m = m + (15 - r)
			end
			m = m - 15
			if m < 0 then
				m = 1425
			end
		elseif menu:left() then
			break
		elseif menu:right() then
			SendNetworkEvent("admin_miscellaneous:Clock",m)
			break
		end
	end
end

-- request vehicles
SendNetworkEvent("admin_miscellaneous:Request")
