LoadScript("offsets.lua")

gCurrentScript = GetCurrentScript()
gPreviewOffset = {}
gVehicles = {}

-- exports
function exports.Register(vehicle)
	if not VehicleIsValid(vehicle) then
		argerror(1,"invalid vehicle")
	elseif not gVehicles[vehicle] then
		CallFunctionFromScript(gCurrentScript,F_Register,vehicle)
	end
	gVehicles[vehicle].scripts[GetCurrentScript()] = true
end
function exports.Unregister(vehicle)
	local x = gVehicles[vehicle]
	if x then
		x.scripts[GetCurrentScript()] = nil
		if not next(x.scripts) or not VehicleIsValid(vehicle) then
			CallFunctionFromScript(gCurrentScript,F_Unregister,vehicle,x)
		end
	end
end
function exports.Update(vehicle)
	local x = gVehicles[vehicle]
	if x then
		if VehicleIsValid(vehicle) then
			return CallFunctionFromScript(gCurrentScript,F_Update,vehicle,x)
		end
		CallFunctionFromScript(gCurrentScript,F_Unregister,vehicle,x)
	end
	return false
end
function exports.GetFakeVehicle(vehicle)
	local x = gVehicles[vehicle]
	if x then
		return x.car
	end
	return -1
end
function exports.GetFakePed(ped)
	for _,x in pairs(gVehicles) do
		for i,v in pairs(x.real) do
			if v == ped and PedIsValid(x.fake[i]) then
				return x.fake[i]
			end
		end
	end
	return -1
end

-- vehicle registration
function F_Register(vehicle)
	if not next(gVehicles) then
		gThread = CreateThread("T_Tracker")
	end
	gVehicles[vehicle] = {
		car = -1, -- fake car
		real = {-1,-1,-1,-1}, -- real peds
		fake = {-1,-1,-1,-1}, -- fake peds
		spawn = true, -- should spawn a fake car
		peds = true, -- should spawn fake peds
		ncol = false, -- take away collisions
		offsets = F_GetOffsets(vehicle),
		rotations = F_GetRotations(vehicle),
		actions = F_GetActions(vehicle),
		-- matrix is set for use in "PedUpdateMatrix" when there is a valid car
		scripts = {},
	}
	if dsl.propcars then
		if dsl.propcars.IsInvisible(vehicle) then
			gVehicles[vehicle].spawn = false
		end
		if dsl.propcars.ArePedsInvisible(vehicle) then
			gVehicles[vehicle].peds = false
		end
	end
end
function F_Unregister(vehicle,x)
	for seat = 0,3 do
		F_Cleanup(x,seat)
	end
	if x.car ~= -1 then
		if VehicleIsValid(x.car) then
			if PlayerIsInVehicle(x.car) then
				if VehicleIsBike(x.car) then
					PlayerDetachFromVehicle()
				else
					PedWarpOutOfCar(x.car)
				end
			end
			VehicleDelete(x.car)
		end
		if VehicleIsValid(vehicle) then
			if x.ncol then
				VehicleSetEntityFlag(vehicle,1,true) -- collision
			end
			VehicleSetEntityFlag(vehicle,11,true) -- visible
		end
		x.car = -1
	end
	gVehicles[vehicle] = nil
	if not next(gVehicles) then
		TerminateThread(gThread)
		gThread = nil
	end
end
function T_Tracker()
	while true do
		for vehicle,x in pairs(gVehicles) do
			if not VehicleIsValid(vehicle) then
				F_Unregister(vehicle,x)
			end
		end
		Wait(0)
	end
end

-- vehicle update
function F_Update(vehicle,x)
	local vp = vec3(VehicleGetPosXYZ(vehicle))
	local vm = VehicleGetMatrix(vehicle)
	if x.spawn and not VehicleIsValid(x.car) then
		local cleanup = x.car ~= -1
		local model = VehicleGetModelId(vehicle)
		x.car = VehicleCreateXYZ(model,0,0,0)
		if not VehicleIsValid(x.car) then
			for seat = 0,3 do
				F_Cleanup(x,seat)
			end
			if cleanup then
				if x.ncol then
					VehicleSetEntityFlag(vehicle,1,true) -- collision
				end
				VehicleSetEntityFlag(vehicle,11,true) -- visible
			end
			x.car = -1
			return false
		end
		VehicleSetStatic(x.car,false)
		x.ncol = model == 276 or model == 289
	end
	if VehicleIsValid(x.car) then
		local a1,b1 = VehicleGetColor(vehicle)
		local a2,b2 = VehicleGetColor(x.car)
		if a1 ~= a2 or a1 ~= b2 then
			VehicleSetColor(x.car,a1,b1)
		end
		if x.ncol then
			VehicleSetEntityFlag(vehicle,1,false) -- no collision
		end
		VehicleSetEntityFlag(vehicle,11,false) -- invisible
		if VehicleGetStatus(x.car) ~= 2 then
			VehicleSetStatus(x.car,2)
		end
		VehicleSetEntityFlag(x.car,1,false) -- no collision
		VehicleSetPosSimple(x.car,vp:unpack())
		VehicleSetMatrix(x.car,vm)
	end
	for seat = 0,3 do
		local ped = VehicleGetPassenger(vehicle,seat) -- real passenger
		if PedIsValid(ped) and (gPreviewOffset[1] or ped ~= gPlayer or not (F_IsFirstPerson() or F_IsGettingOut())) then
			if x.real[seat] ~= ped or (x.peds and (not PedIsValid(x.fake[seat]) or PedGetModelId(x.fake[seat]) ~= PedGetModelId(ped))) then
				F_Cleanup(x,seat)
				x.real[seat] = ped
				if x.peds then
					x.fake[seat] = PedCreateXYZ(PedGetModelId(ped),0,0,0)
				else
					x.fake[seat] = -1
				end
			end
			if PedIsValid(ped) then
				if PedIsValid(x.fake[seat]) then
					local ped = x.fake[seat]
					if gPreviewOffset[1] then
						PedSetPosSimple(ped,(vp+vm*vec3(unpack(gPreviewOffset))):unpack())
					else
						PedSetPosSimple(ped,(vp+vm*x.offsets[seat]):unpack())
					end
					F_Passenger(ped,unpack(x.actions[seat]))
				end
				PedSetAlpha(ped,0,true)
				PedSetEntityFlag(ped,11,false)
			elseif x.real[seat] ~= -1 then -- CAN HAPPEN IF PedCreateXYZ DELETED OUR REAL PED
				F_Cleanup(x,seat)
			end
		elseif x.real[seat] ~= -1 then
			F_Cleanup(x,seat)
		end
	end
	x.matrix = vm
	return true
end
function F_IsFirstPerson()
	if dsl.first_person then
		return dsl.first_person.IsActive()
	end
	return false
end
function F_IsGettingOut()
	return PedIsPlaying(gPlayer,"/GLOBAL/VEHICLES",true) and PedMePlaying(gPlayer,"DISMOUNT",true)
end
function F_Passenger(ped,node,file)
	if not PedIsPlaying(ped,node,true) then
		PedSetActionNode(ped,node,file)
	end
	if SoundSpeechPlaying(ped) then
		SoundStopCurrentSpeechEvent(ped)
	end
	PedMakeTargetable(ped,false)
	PedSetUsesCollisionScripted(ped,true)
	PedSetEffectedByGravity(ped,false)
	PedIgnoreAttackCone(ped,true)
	PedIgnoreAttacks(ped,true)
	PedIgnoreStimuli(ped,true)
	PedClearObjectives(ped)
end
function F_Cleanup(x,seat)
	local real = x.real[seat]
	if real ~= -1 then
		local fake = x.fake[seat]
		if PedIsValid(fake) then
			PedDelete(fake)
		end
		if PedIsValid(real) then
			PedSetAlpha(real,255,false)
			PedSetEntityFlag(real,11,true)
		end
		x.real[seat] = -1
		x.fake[seat] = -1
	end
end

-- script cleanup
RegisterLocalEventHandler("ScriptDestroyed",function(s)
	for vehicle,x in pairs(gVehicles) do
		if x.scripts[s] then
			x.scripts[s] = nil
			if not next(x.scripts) or not VehicleIsValid(vehicle) then
				F_Unregister(vehicle,x)
			end
		end
	end
end)
function MissionCleanup()
	if gPreviewOffset[1] then
		PlayerSetControl(1)
	end
	for vehicle,x in pairs(gVehicles) do
		F_Unregister(vehicle,x)
	end
end

-- passenger events
RegisterLocalEventHandler("PedResetAlpha",function(ped)
	for _,x in pairs(gVehicles) do
		for _,v in pairs(x.real) do
			if v == ped then
				return true
			end
		end
	end
end)
RegisterLocalEventHandler("PedUpdateMatrix",function(ped)
	for _,x in pairs(gVehicles) do
		for seat,v in pairs(x.fake) do
			if v == ped then
				PedSetMatrix(ped,x.matrix*x.rotations[seat])
			end
		end
	end
end)
RegisterLocalEventHandler("sync:SuppressPed",function(ped)
	for _,x in pairs(gVehicles) do
		for _,v in pairs(x.fake) do
			if v == ped then
				return true
			end
		end
	end
end)
RegisterLocalEventHandler("sync:SuppressVehicle",function(vehicle)
	for _,x in pairs(gVehicles) do
		if x.car == vehicle then
			return true
		end
	end
end)

-- offset stuff
RegisterNetworkEventHandler("fakecars:AllowOffset",function()
	RegisterLocalEventHandler("f2menu:Open",CB_F2MenuOpen)
	RegisterLocalEventHandler("f2menu:Close",CB_F2MenuClose)
end)
RegisterNetworkEventHandler("fakecars:UpdateOffsets",function(offsets,rotations,actions)
	F_ConvertOffsets(offsets)
	gOffsets = offsets
	gRotations = rotations
	gActions = actions
	for vehicle,x in pairs(gVehicles) do
		if VehicleIsValid(vehicle) then
			x.offsets = F_GetOffsets(vehicle)
			x.rotations = F_GetRotations(vehicle)
			x.actions = F_GetActions(vehicle)
		end
	end
end)
function F_ConvertOffsets(offsets)
	for _,seats in pairs(offsets) do
		for i = 0,3 do
			seats[i] = vec3(unpack(seats[i])) -- convert tables to vectors
		end
	end
end
function F_ConvertRotations(rotations)
	local copy = {}
	for k,v in pairs(rotations) do
		copy[k] = RotationMatrix(unpack(v))
	end
	return copy
end
function F_GetOffsets(vehicle)
	if dsl.propcars then
		local offsets = gOffsets[dsl.propcars.GetName(vehicle)]
		if offsets then
			return offsets
		end
	end
	return gOffsets[VehicleGetModelId(vehicle)] or gOffsets[0]
end
function F_GetRotations(vehicle)
	if dsl.propcars then
		local rotations = gRotations[dsl.propcars.GetName(vehicle)]
		if rotations then
			return F_ConvertRotations(rotations)
		end
	end
	return F_ConvertRotations(gRotations[VehicleGetModelId(vehicle)] or gRotations[0])
end
function F_GetActions(vehicle)
	if dsl.propcars then
		local actions = gActions[dsl.propcars.GetName(vehicle)]
		if actions then
			return actions
		end
	end
	return gActions[VehicleGetModelId(vehicle)] or gActions[0]
end

-- f2menu stuff
function CB_F2MenuOpen(f_add)
	f_add({
		name = "Fake Car Offsets",
		description = "(admin only)\nConfigure positions of fake peds in fake cars.",
		thread = M_OffsetMenu,
	})
end
function CB_F2MenuClose()
	if gPreviewOffset[1] then
		PlayerSetControl(1)
		gPreviewOffset = {}
	end
end
function M_OffsetMenu(parent,selected)
	local menu = parent:submenu(selected.name,"Any car with a note starting with \"done\" is shown as [DONE]. Others still need configured.")
	local keys = {}
	local names = {
		"bmxrace","retro","crapbmx","bikecop","Scooter","bike","custombike","banbike","mtnbike","oladbike","racer","aquabike",
		"Mower","Arc_3","taxicab","Arc_2","Dozer","GoCart","Limo","Dlvtruck","Foreign","cargreen","70wagon","policecar","domestic","Truck","Arc_1"
	}
	for m = 272,298 do
		table.insert(keys,{"["..m.."] "..names[m-271],m})
	end
	if dsl.propcars then
		for _,name in ipairs(dsl.propcars.GetNames()) do
			table.insert(keys,{name,name})
		end
	end
	while menu:active() do
		local vehicle = VehicleFromDriver(gPlayer)
		if VehicleIsValid(vehicle) and menu:option("< current vehicle >") then
			local key
			if dsl.propcars then
				key = dsl.propcars.GetName(vehicle)
			end
			M_AdjustOffsets(menu,key or VehicleGetModelId(vehicle))
		end
		for _,v in ipairs(keys) do
			local offsets = gOffsets[v[2]]
			if offsets and offsets.note then
				if not v[3] then
					if string.find(offsets.note,"^done") then
						v[3] = "[DONE]"
					else
						v[3] = "[NOTE]"
					end
				end
			elseif v[3] then
				v[3] = nil
			end
		end
		for _,v in ipairs(keys) do
			if menu:option(v[1],v[3]) then
				M_AdjustOffsets(menu,v[2])
			end
		end
		menu:draw()
		Wait(0)
	end
end
function M_AdjustOffsets(parent,key)
	local seats = {[0] = "FL","FR","BR","BL"}
	local menu = parent:submenu("Adjust Offsets")
	local description = "."..key
	local note
	if type(key) == "number" then
		description = "["..key.."]"
	elseif string.find(key,"[^%w_]") or string.find(key,"^%d") then
		description = "[\""..key.."\"]"
	end
	if gOffsets[key] then
		note = gOffsets[key].note
	end
	description = "gOffsets"..description
	if note then
		menu:help(description.."\n"..note)
	else
		menu:help(description)
	end
	while menu:active() do
		for i = 0,3 do
			if menu:option("Adjust Seat ["..i.." ("..seats[i]..")]") then
				M_AdjustSeat(menu,key,i)
			end
		end
		if menu:option("Mirror L2R") then
			while menu:active() do
				menu:draw("[SURE?]")
				Wait(0)
				if menu:right() then
					SendNetworkEvent("fakecars:MirrorOffsets",key,seat)
					break
				elseif menu:left() then
					break
				end
			end
		elseif menu:option("Set Note") then
			note = O_NoteOffset(menu,key,note)
			if note then
				menu:help(description.."\n"..note)
			end
		end
		menu:draw()
		Wait(0)
	end
end
function M_AdjustSeat(parent,key,seat)
	local menu = parent:submenu("Adjust Seat ["..seat.."]")
	local rotation = {0,0,0}
	if gRotations[key] then
		rotation = gRotations[key][seat]
	end
	while menu:active() do
		if menu:option("Adjust Offset") then
			O_AdjustOffset(menu,key,seat)
		elseif menu:option("Adjust Pitch",string.format("[%.1f]",math.deg(rotation[1]))) then
			O_AdjustRotation(menu,key,seat,rotation,1)
		elseif menu:option("Adjust Roll",string.format("[%.1f]",math.deg(rotation[2]))) then
			O_AdjustRotation(menu,key,seat,rotation,2)
		elseif menu:option("Adjust Yaw",string.format("[%.1f]",math.deg(rotation[3]))) then
			O_AdjustRotation(menu,key,seat,rotation,3)
		elseif menu:option("Zero Rotation") then
			SendNetworkEvent("fakecars:AdjustRotation",key,seat,0,0,0)
			rotation = {0,0,0}
		elseif menu:option("Set Action Node") then
			O_AdjustAction(menu,key,seat)
		elseif menu:option("Reset Action Node") then
			if seat == 0 then
				SendNetworkEvent("fakecars:AdjustAction",key,seat,"/GLOBAL/VEHICLES/CARS/VEHICLES_CARRIDE/RIDE/SEDAN/DRIVER","")
			else
				SendNetworkEvent("fakecars:AdjustAction",key,seat,"/GLOBAL/VEHICLES/CARS/VEHICLES_CARRIDE/RIDE/SEDAN/PASSENGER/PASSENGERIDLE","")
			end
		end
		menu:draw()
		Wait(0)
	end
end
function O_NoteOffset(menu,key,note)
	local typing = StartTyping(note)
	if not typing then
		return note
	end
	while menu:active() do
		local text = GetTypingString(typing,true)
		SetTextFont("Arial")
		SetTextBlack()
		SetTextColor(230,230,230,255)
		SetTextShadow()
		SetTextAlign("C","C")
		SetTextPosition(0.5,0.2)
		SetTextWrapping(0.5/GetDisplayAspectRatio())
		DrawText(text)
		menu:draw("[TYPING]")
		Wait(0)
		if not IsTypingActive(typing) then
			if not WasTypingAborted(typing) then
				note = GetTypingString(typing)
				if note == "" then
					SendNetworkEvent("fakecars:NoteOffset",key)
				else
					SendNetworkEvent("fakecars:NoteOffset",key,note)
				end
			end
			break
		end
	end
	if IsTypingActive(typing) then
		StopTyping(typing)
	end
	return note
end
function O_AdjustOffset(menu,key,seat)
	if gOffsets[key] then
		gPreviewOffset = {(gOffsets[key][seat]):unpack()}
	else
		gPreviewOffset = {0,0,0}
	end
	while menu:active() and gPreviewOffset[1] do
		SetTextFont("Arial")
		SetTextBlack()
		SetTextColor(240,240,128,255)
		SetTextShadow()
		SetTextAlign("C","C")
		SetTextPosition(0.5,0.2)
		DrawText("{%.3f, %.3f, %.3f}",unpack(gPreviewOffset))
		SetTextFont("Arial")
		SetTextBlack()
		SetTextColor(230,230,230,255)
		SetTextShadow()
		SetTextAlign("C","C")
		SetTextPosition(0.5,0.9)
		DrawText("[Z] Zero Offset | [W/A/S/D] Move XY | [T/G] Move Z\n[SHIFT] Move Faster | [CTRL] Move Slower\n[LEFT] Cancel | [RIGHT] Confirm")
		menu:draw("[ACTIVE]")
		PlayerSetControl(0)
		Wait(0)
		if menu:right() then
			if gPreviewOffset[1] then
				SendNetworkEvent("fakecars:AdjustOffset",key,seat,unpack(gPreviewOffset))
			end
			break
		elseif menu:left() then
			break
		elseif gPreviewOffset[1] then
			F_AdjustOffset(gPreviewOffset)
		end
	end
	if gPreviewOffset[1] then
		PlayerSetControl(1)
		gPreviewOffset = {}
	end
end
function F_AdjustOffset(off)
	local speed = GetFrameTime() * 0.1
	if IsKeyBeingPressed("Z") then
		off[1],off[2],off[3] = 0,0,0
	end
	if IsKeyPressed("LSHIFT") then
		speed = speed * 4
	end
	if IsKeyPressed("LCONTROL") then
		speed = speed * 0.2
	end
	if IsKeyPressed("W") then
		off[2] = off[2] + speed
	end
	if IsKeyPressed("A") then
		off[1] = off[1] - speed
	end
	if IsKeyPressed("S") then
		off[2] = off[2] - speed
	end
	if IsKeyPressed("D") then
		off[1] = off[1] + speed
	end
	if IsKeyPressed("T") then
		off[3] = off[3] + speed
	end
	if IsKeyPressed("G") then
		off[3] = off[3] - speed
	end
end
function O_AdjustRotation(menu,key,seat,rotation,index)
	local typing = StartTyping()
	if not typing then
		return
	end
	while menu:active() do
		if not IsTypingActive(typing) then
			if not WasTypingAborted(typing) then
				local value = tonumber(GetTypingString(typing))
				if value and value > -360 and value < 360 then
					rotation[index] = math.rad(value)
					SendNetworkEvent("fakecars:AdjustRotation",key,seat,unpack(rotation))
				end
			end
			break
		end
		menu:draw(GetTypingString(typing,true))
		Wait(0)
	end
end
function O_AdjustAction(menu,key,seat)
	local typing = StartTyping()
	if not typing then
		return
	end
	while menu:active() do
		if not IsTypingActive(typing) then
			if not WasTypingAborted(typing) then
				local node = string.gsub(string.gsub(GetTypingString(typing),"\"",""),"'","")
				local comma,after = string.find(node,",%s*")
				if comma then
					SendNetworkEvent("fakecars:AdjustAction",key,seat,string.sub(node,1,comma-1),string.sub(node,after+1))
				else
					SendNetworkEvent("fakecars:AdjustAction",key,seat,node,"")
				end
			end
			break
		end
		menu:draw(GetTypingString(typing,true))
		Wait(0)
	end
end

-- convert offsets
F_ConvertOffsets(gOffsets)

-- request permissions
SendNetworkEvent("fakecars:RequestOffset")
