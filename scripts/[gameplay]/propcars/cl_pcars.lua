LoadScript("objects.lua")

local gEvent -- for f2menu
local gCreating = 0 -- waiting on new config to be created

local gConfigs = {}
local gCars = {}

local gMenuActive = false
local gPreviewProp = -1
local gAdjustPosition
local gAdjustRotation
local gAdjustScaling

local gCulled = {} -- culled peds (local peds)
local gShowing = {} -- propcars (by server vehicle) that are actually showing, and their prop count
local gShouldShow = {} -- propcars that *should* show next update

TAGS = {"OFFICIAL","UNOFFICIAL","EXPERIMENT",OFFICIAL = 1,UNOFFICIAL = 2,EXPERIMENT = 3}

RegisterNetworkEventHandler("propcars:GiveMenu",function()
	if gEvent then
		RemoveEventHandler(gEvent)
	end
	gEvent = RegisterLocalEventHandler("f2menu:Open",function(f_add)
		f_add({
			name = "Prop Cars",
			description = "(admin only)\nSet cars as prop cars and setup prop car configs.",
			thread = M_Main,
		})
	end)
end)
RegisterNetworkEventHandler("propcars:InitConfig",function(cfg)
	gConfigs = cfg
end)
RegisterNetworkEventHandler("propcars:UpdateConfig",function(value)
	for car,x in pairs(gCars) do
		if x.config.name == value.name then
			x.count = table.getn(value.props)
			x.props = {} -- signal the old thread to die, and make a new thread
			x.config = value
			CreateThread("T_PropCar",car,x.props,value,x)
		end
	end
	for i,v in ipairs(gConfigs) do
		if v.name == value.name then
			gConfigs[i] = value
			F_ResortConfigs()
			return
		end
	end
	table.insert(gConfigs,value)
	F_ResortConfigs()
end)
RegisterNetworkEventHandler("propcars:RemoveConfig",function(name)
	local i = 1
	for car,x in pairs(gCars) do
		if x.config.name == name then
			gCars[car] = nil
			gShouldShow[car] = nil
			x.props = nil -- signal thread to die
		end
	end
	while gConfigs[i] do
		if gConfigs[i].name == name then
			table.remove(gConfigs,i)
		else
			i = i + 1
		end
	end
end)
RegisterNetworkEventHandler("propcars:CreatedConfig",function()
	gCreating = gCreating - 1
end)

RegisterNetworkEventHandler("propcars:SetCar",function(car,name)
	local v = F_FindConfig(name)
	gCars[car] = {fake = -1,count = table.getn(v.props),props = {},config = v}
	CreateThread("T_PropCar",car,gCars[car].props,v,gCars[car])
end)
RegisterLocalEventHandler("sync:DeleteVehicle",function(car)
	gCars[car] = nil
	gShouldShow[car] = nil
end)

RegisterLocalEventHandler("PedResetAlpha",function(ped)
	if gCulled[ped] then
		return true
	end
end)

-- sorting
function F_ResortConfigs()
	table.sort(gConfigs,function(a,b)
		local x,y = TAGS[a.tag],TAGS[b.tag]
		if x ~= y then
			return x < y
		end
		return string.lower(a.name) < string.lower(b.name)
	end)
end

-- exports
function exports.GetNames() -- table
	local list = {}
	for i,v in ipairs(gConfigs) do
		list[i] = v.name
	end
	return list
end
function exports.GetTag(name)
	local v = F_FindConfig(name)
	if v then
		return v.tag
	end
end
function exports.GetName(vehicle) -- nil | string
	local v = F_GetConfigFromVehicle(vehicle)
	if v then
		return v.name
	end
end
function exports.IsInvisible(vehicle) -- boolean
	local v = F_GetConfigFromVehicle(vehicle)
	if v then
		return v.invisible
	end
	return false
end
function exports.ArePedsInvisible(vehicle) -- boolean
	local v = F_GetConfigFromVehicle(vehicle)
	if v then
		return v.hidepeds
	end
	return false
end
function exports.ShouldUseWarp(vehicle,seat) -- nil | boolean
	local v = F_GetConfigFromVehicle(vehicle)
	if v then
		if seat == 0 then
			return v.warp == 2
		end
		return v.warp ~= 0
	end
end
function exports.GetMaxSeats(vehicle) -- nil | number [0, 3]
	local v = F_GetConfigFromVehicle(vehicle)
	return v and v.seats
end
function exports.IsLockable(vehicle) -- nil | boolean
	local v = F_GetConfigFromVehicle(vehicle)
	return v and v.lockable
end
function exports.HasEngine(vehicle) -- nil | boolean
	local v = F_GetConfigFromVehicle(vehicle)
	return v and v.engine
end
function exports.HasCustomHorn(vehicle) -- boolean
	local v = F_GetConfigFromVehicle(vehicle)
	if v and v.honk then
		return true
	end
	return false
end
function exports.PlayHorn(vehicle) -- boolean
	local v = F_GetConfigFromVehicle(vehicle)
	if v and v.honk then
		if v.honk[1] ~= "none" then
			local x,y,z = VehicleGetPosXYZ(vehicle)
			if dsl.sounds then
				dsl.sounds.Play3D(x,y,z,unpack(v.honk))
			else
				SoundPlay3D(x,y,z,v.honk[1])
			end
		end
		return true
	end
	return false
end

-- utility
function F_GetConfigFromVehicle(vehicle)
	if VehicleIsValid(vehicle) then
		local x = gCars[VehicleGetSyncVehicle(vehicle)]
		if x then
			return x.config
		end
	end
end
function F_FindConfig(name)
	for _,v in ipairs(gConfigs) do
		if v.name == name then
			return v
		end
	end
end
function F_FixRotation(h)
	while h > math.pi do
		h = h - math.pi * 2
	end
	while h <= -math.pi do
		h = h + math.pi * 2
	end
	return h
end

-- culling main
function main()
	local maximum = GetConfigNumber(GetScriptConfig(),"max_prop_count",50)
	local spawn = GetConfigNumber(GetScriptConfig(),"spawn_dist",40)
	local despawn = GetConfigNumber(GetScriptConfig(),"despawn_dist",50)
	spawn = spawn * spawn
	despawn = despawn * despawn
	while true do
		local budget = maximum
		local unique = {} -- unique ids taken
		local count,sorted = 0,{}
		local x1,y1,z1 = PlayerGetPosXYZ()--CameraGetXYZ()
		for car,x in pairs(gCars) do
			if IsSyncEntityActive(car) then
				local x2,y2,z2 = GetSyncEntityPos(car)
				local dx,dy,dz = x2-x1,y2-y1,z2-z1
				local dist = dx*dx+dy*dy+dz*dz
				if dist < (gShouldShow[car] and despawn or spawn) then
					count = count + 1
					sorted[count] = {dist,car,x}
				else
					gShouldShow[car] = nil -- not within range
				end
			else
				gShouldShow[car] = nil -- not active (in another dimension)
			end
		end
		table.sort(sorted,function(a,b)
			return a[1] < b[1]
		end)
		for _,v in ipairs(sorted) do -- first pass: set based on prop budget and unique
			local car,x = v[2],v[3]
			if budget >= x.count and not unique[x.config.unique] then
				if x.config.unique then
					unique[x.config.unique] = true -- don't allow any others with this "unique" tag
				end
				budget = budget - x.count
				gShouldShow[car] = true
			else
				gShouldShow[car] = nil
			end
		end
		budget = maximum
		for _,count in pairs(gShowing) do
			budget = budget - count
		end
		for _,v in ipairs(sorted) do -- second pass: don't show based on budget - all gShowing
			local car,x = v[2],v[3]
			if gShouldShow[car] and not gShowing[car] then
				if budget >= x.count then
					budget = budget - x.count
				else
					gShouldShow[car] = nil -- not within budget
				end
			end
		end
		Wait(0)
	end
end

-- propcar main
function T_PropCar(car,props,v,x)
	local culled = {}
	local hidden = true -- props are invisible
	while IsSyncVehicleValid(car) and x.props == props do
		local vehicle = VehicleFromSyncVehicle(car)
		if VehicleIsValid(vehicle) then -- UPDATE VEHICLE
			VehicleSetEntityFlag(vehicle,11,not v.invisible)
		end
		if gShouldShow[car] and VehicleIsValid(vehicle) then -- UPDATE PROPS?
			local v_pos = vec3(VehicleGetPosXYZ(vehicle))
			local v_rot = VehicleGetMatrix(vehicle)
			if hidden then -- RESTORE PED VISIBILITY AND SPAWN PROPS
				for ped in pairs(culled) do
					if PedIsValid(ped) then
						PedSetAlpha(ped,255,false)
						PedSetEntityFlag(ped,11,true)
					end
					gCulled[ped] = nil
					culled[ped] = nil
				end
				for i,p in ipairs(v.props) do
					local obj = ObjectCreateXYZ(p.model,v_pos:unpack())
					if ObjectIsValid(obj) then
						ObjectToggleVulnerability(obj,false)
						ObjectSetEntityFlag(obj,0,false) -- no physics
						props[i] = obj
					end
				end
				gShowing[car] = x.count
				hidden = false
			end
			for i,p in ipairs(v.props) do -- UPDATE PROPS
				local obj = props[i]
				if ObjectIsValid(obj) then
					local o_pos = vec3(F_GetPropPosition(v,i,p))
					local o_scale = CreateMatrix(3,3)
					o_pos = v_pos + v_rot * o_pos
					o_scale[1][1],o_scale[2][2],o_scale[3][3] = F_GetPropScaling(v,i,p)
					ObjectSetPosXYZ(obj,o_pos[1],o_pos[2],o_pos[3])
					ObjectSetMatrix(obj,v_rot*RotationMatrix(F_GetPropRotation(v,i,p))*o_scale)
				end
			end
			if x.fake ~= vehicle then -- REGISTER FAKE CAR
				if dsl.fakecars then
					dsl.fakecars.Register(vehicle)
				end
				x.fake = vehicle
			end
			if dsl.fakecars then -- UPDATE FAKE CAR
				dsl.fakecars.Update(vehicle)
			end
		else
			if VehicleIsValid(vehicle) then
				for seat = 0,3 do
					local ped = VehicleGetPassenger(vehicle,seat)
					if PedIsValid(ped) then
						PedSetAlpha(ped,0,true)
						PedSetEntityFlag(ped,11,false)
						gCulled[ped] = true
						culled[ped] = true
					end
				end
				VehicleSetEntityFlag(vehicle,11,false)
			end
			for ped in pairs(culled) do
				if not PedIsValid(ped) or not VehicleIsValid(vehicle) or not PedIsInVehicle(ped,vehicle) then
					if PedIsValid(ped) then
						PedSetAlpha(ped,255,false)
						PedSetEntityFlag(ped,11,true)
					end
					gCulled[ped] = nil
					culled[ped] = nil
				end
			end
			if not hidden then -- DESPAWN PROPS
				for i,obj in ipairs(props) do
					if ObjectIsValid(obj) then
						ObjectDelete(obj)
					end
					props[i] = nil
				end
				gShowing[car] = nil
				hidden = true
			end
			if x.fake ~= -1 then -- UNREGISTER FAKE CAR
				if dsl.fakecars then
					dsl.fakecars.Unregister(vehicle)
				end
				x.fake = -1
			end
		end
		Wait(0)
	end
	for ped in pairs(culled) do
		if PedIsValid(ped) then
			PedSetAlpha(ped,255,false)
			PedSetEntityFlag(ped,11,true)
		end
		gCulled[ped] = nil
	end
	for i,obj in ipairs(props) do -- DESPAWN PROPS
		if ObjectIsValid(obj) then
			ObjectDelete(obj)
		end
		props[i] = nil
	end
	gShowing[car] = nil
	if IsSyncVehicleValid(car) then -- CLEANUP VEHICLE
		local vehicle = VehicleFromSyncVehicle(car)
		if VehicleIsValid(vehicle) then
			VehicleSetEntityFlag(vehicle,11,true) -- visible
		end
	end
	if x.fake ~= -1 then -- UNREGISTER FAKE CAR
		if dsl.fakecars then
			dsl.fakecars.Unregister(x.fake)
		end
		x.fake = -1
	end
end
function F_GetPropPosition(v,i,p)
	if gAdjustPosition and gAdjustPosition.name == v.name and gAdjustPosition.prop == i then
		return unpack(gAdjustPosition.off)
	end
	return unpack(p.pos)
end
function F_GetPropRotation(v,i,p)
	if gAdjustRotation and gAdjustRotation.name == v.name and gAdjustRotation.prop == i then
		return unpack(gAdjustRotation.off)
	end
	return unpack(p.rot)
end
function F_GetPropScaling(v,i,p)
	if gAdjustScaling and gAdjustScaling.name == v.name and gAdjustScaling.prop == i then
		return unpack(gAdjustScaling.off)
	end
	return unpack(p.scale)
end

-- script cleanup
function MissionCleanup()
	for car,x in pairs(gCars) do
		local vehicle = VehicleFromSyncVehicle(car)
		if VehicleIsValid(vehicle) then
			VehicleSetEntityFlag(vehicle,11,true)
		end
		if x.fake ~= -1 and dsl.fakecars then
			dsl.fakecars.Unregister(x.fake)
		end
		for _,obj in ipairs(x.props) do
			if ObjectIsValid(obj) then
				ObjectDelete(obj)
			end
		end
		gShowing[car] = nil
	end
	for ped in pairs(gCulled) do
		if PedIsValid(ped) then
			PedSetAlpha(ped,255,false)
			PedSetEntityFlag(ped,11,true)
		end
	end
	if ObjectIsValid(gPreviewProp) then
		ObjectDelete(gPreviewProp)
	end
end

-- menu stuff
function M_Main(parent,selected)
	local menu = parent:submenu(selected.name,"Get in a car to setup a new prop car.")
	gMenuActive = true
	while menu:active() do
		local current
		local vehicle = VehicleFromDriver(gPlayer)
		if VehicleIsValid(vehicle) then
			local x = gCars[VehicleGetSyncVehicle(vehicle)]
			if x then
				current = x.config
			end
		end
		if menu:option("< new prop car >",nil,"Setup a new prop car.") then
			local name = F_TypeName(menu)
			if name then
				local model
				if VehicleIsValid(vehicle) then
					model = VehicleGetModelId(vehicle)
				else
					model = F_SetModel(menu)
				end
				if model then
					gCreating = gCreating + 1
					SendNetworkEvent("propcars:NewConfig",name,model)
					while gCreating > 0 do
						menu:draw("[CREATING]")
						Wait(0)
					end
					--M_NewConfig(menu,name)
				end
			end
		elseif current and menu:option("< edit "..current.name.." >",nil,"Tweak your current vehicle.") then
			M_EditConfig(menu,current)
		end
		for _,v in ipairs(gConfigs) do
			if menu:option(v.name,"["..v.tag.."]","Spawn / configure prop car.") then
				M_EditConfig(menu,v)
			end
		end
		menu:draw()
		Wait(0)
	end
	gMenuActive = false
end
function F_TypeName(menu)
	local typing = StartTyping()
	if typing then
		while IsTypingActive(typing) and menu:active() do
			menu:draw(GetTypingString(typing,true))
			Wait(0)
		end
		if not IsTypingActive(typing) and not WasTypingAborted(typing) then
			return GetTypingString(typing)
		end
	end
end
function M_NewConfig(menu,name)
	local v = F_FindConfig(name)
	if v then
		return M_EditConfig(menu,v)
	end
end
function M_EditConfig(parent,v)
	local menu = parent:submenu(v.name)
	if dsl.freecam then
		dsl.freecam.Activate()
	end
	while menu:active() do
		if menu:option("Tag","["..v.tag.."]") then
			v.tag = TAGS[TAGS[v.tag]+1] or TAGS[1]
			F_UpdatePropCar(v)
		elseif menu:option("Vehicle Visibility",v.invisible and "[OFF]" or "[ON]") then
			v.invisible = not v.invisible
			F_UpdatePropCar(v)
		elseif menu:option("Passenger Visibility",v.hidepeds and "[OFF]" or "[ON]") then
			v.hidepeds = not v.hidepeds
			F_UpdatePropCar(v)
		elseif menu:option("Vehicle Model","["..v.model.."]") then
			local model = F_SetModel(menu)
			if model then
				v.model = model
				F_UpdatePropCar(v)
			end
		elseif menu:option("Unique Culling",v.unique and "[\""..v.unique.."\"]" or "[OFF]") then
			if v.unique then
				v.unique = nil
			else
				v.unique = F_TypeName(menu)
				if v.unique then
					if string.find(v.unique,"[^%w_]") then
						menu:alert("Forbidden characters.")
						v.unique = nil
					else
						v.unique = string.upper(v.unique)
					end
				end
			end
			F_UpdatePropCar(v)
		elseif menu:option("Vehicle Warping",({[0]="[NOBODY]","[PASSENGERS]","[EVERYONE]"})[v.warp]) then
			v.warp = math.mod(v.warp+1,3)
			F_UpdatePropCar(v)
		elseif menu:option("Maximum Seats","["..v.seats.."]") then
			v.seats = math.mod(v.seats,4) + 1
			F_UpdatePropCar(v)
		elseif menu:option("Lockable Doors",v.lockable and "[ON]" or "[OFF]") then
			v.lockable = not v.lockable
			F_UpdatePropCar(v)
		elseif menu:option("Engine Behavior",v.engine and "[DEFAULT]" or "[VANILLA]") then
			v.engine = not v.engine
			F_UpdatePropCar(v)
		elseif menu:option("Horn Sound",v.honk and string.format("[\"%s\", \"%s\"]",unpack(v.honk)) or "[DEFAULT]") then
			if not v.honk then
				local str = F_TypeName(menu)
				if str then
					if string.lower(str) ~= "none" then
						local found,_,sound,bank = string.find(str,"([%w%._]+)%s*,%s*([%w%._]+)")
						if found then
							v.honk = {sound,bank}
						else
							menu:alert("Invalid input, expected format: sound, bank.")
						end
					else
						v.honk = {"none",""}
					end
				end
			else
				v.honk = nil
			end
			F_UpdatePropCar(v)
		elseif menu:option("Duplicate Config") then
			local name = F_TypeName(menu)
			if name then
				SendNetworkEvent("propcars:DuplicateConfig",v.name,name)
			end
		elseif menu:option("Delete Config") then
			while menu:active() do
				menu:draw("[SURE?]")
				Wait(0)
				if menu:right() then
					SendNetworkEvent("propcars:RemoveConfig",v.name)
					if dsl.freecam then
						dsl.freecam.Deactivate()
					end
					return
				elseif menu:left() then
					break
				end
			end
		end
		for i,p in ipairs(v.props) do
			if menu:option(p.name) then
				M_EditProp(menu,v,i,p)
			elseif menu:hover() and F_UsingConfig(v.name) then
				local size = 0.01
				local ar = GetDisplayAspectRatio()
				local vehicle = VehicleFromDriver(gPlayer) -- we know it's valid because F_UsingConfig
				local pos = vec3(VehicleGetPosXYZ(vehicle)) + VehicleGetMatrix(vehicle) * vec3(unpack(p.pos))
				local x,y = GetScreenCoords(pos[1],pos[2],pos[3])
				if x then
					DrawRectangle(x-(size/ar)*0.5,y-size*0.5,size/ar,size,50,128,255,255)
				end
			end
		end
		if menu:option("< new prop >") then
			local model,name = M_SelectProp(menu)
			if model then
				table.insert(v.props,{
					model = model,
					name = name,
					pos = {0,0,0},
					rot = {0,0,0},
					scale = {1,1,1},
				})
				F_UpdatePropCar(v)
			end
		end
		menu:draw()
		Wait(0)
	end
	if dsl.freecam then
		dsl.freecam.Deactivate()
	end
end
function F_UsingConfig(name)
	local vehicle = VehicleFromDriver(gPlayer)
	if VehicleIsValid(vehicle) then
		local x = gCars[VehicleGetSyncVehicle(vehicle)]
		if x then
			return x.config.name == name
		end
	end
end
function F_UpdatePropCar(v)
	SendNetworkEvent("propcars:UpdateConfig",v)
end
function F_SetModel(parent)
	local menu = parent:submenu("Set Model","Set the model for the actual vehicle. This will only affect newly spawned prop cars.")
	local names = {
		"bmxrace","retro","crapbmx","bikecop","Scooter","bike","custombike","banbike","mtnbike","oladbike","racer","aquabike",
		"Mower","Arc_3","taxicab","Arc_2","Dozer","GoCart","Limo","Dlvtruck","Foreign","cargreen","70wagon","policecar","domestic","Truck","Arc_1"
	}
	while menu:active() do
		for m = 272,298 do
			if menu:option("["..m.."] "..names[m-271]) then
				return m
			end
		end
		menu:draw()
		Wait(0)
	end
end
function M_EditProp(parent,v,i,p)
	local menu = parent:submenu(p.name)
	while menu:active() do
		if menu:option("Adjust Offset",string.format("[%.1f, %.1f, %.1f]",unpack(p.pos))) and F_CheckVehicle(menu,v.name) then
			F_AdjustOffset(menu,v,i,p)
			F_UpdatePropCar(v)
		elseif menu:option("Adjust Rotation",string.format("[%.1f, %.1f, %.1f]",math.deg(p.rot[1]),math.deg(p.rot[2]),math.deg(p.rot[3]))) and F_CheckVehicle(menu,v.name) then
			F_AdjustRotation(menu,v,i,p)
			F_UpdatePropCar(v)
		elseif menu:option("Reset Rotation") and F_CheckVehicle(menu,v.name) then
			p.rot = {0,0,0}
			F_UpdatePropCar(v)
		elseif menu:option("Adjust Scale",string.format("[%.2f, %.2f, %.2f]",unpack(p.scale))) and F_CheckVehicle(menu,v.name) then
			F_AdjustScale(menu,v,i,p)
			F_UpdatePropCar(v)
		elseif menu:option("Reset Scale") and F_CheckVehicle(menu,v.name) then
			p.scale = {1,1,1}
			F_UpdatePropCar(v)
		elseif menu:option("Rename") then
			local name = F_TypeName(menu)
			if name then
				menu.title_text = name
				p.name = name
			end
		elseif menu:option("Delete") then
			table.remove(v.props,i)
			F_UpdatePropCar(v)
			break
		end
		menu:draw()
		Wait(0)
	end
end
function F_CheckVehicle(menu,name)
	if F_UsingConfig(name) then
		return true
	end
	menu:alert("Can only adjust props while in prop car.")
	SoundPlay2D("WrongBtn")
	return false
end
function F_AdjustOffset(menu,v,i,p)
	local pos = {unpack(p.pos)}
	F_StartFocus(v,i,p)
	gAdjustPosition = {name = v.name,prop = i,off = pos}
	while gAdjustPosition and menu:active() do
		menu:draw(string.format("< %.2f, %.2f, %.2f >",unpack(pos)))
		Wait(0)
		if menu:left() then
			break
		elseif menu:right() then
			p.pos = pos
			break
		elseif dsl.freecam then
			local vehicle = VehicleFromDriver(gPlayer)
			if VehicleIsValid(vehicle) then
				local move = TransposeMatrix(VehicleGetMatrix(vehicle)) * vec3(dsl.freecam.GetFocusMove())
				pos[1] = pos[1] + move[1]
				pos[2] = pos[2] + move[2]
				pos[3] = pos[3] + move[3]
			end
		end
	end
	gAdjustPosition = nil
	F_StopFocus()
end
function F_AdjustRotation(menu,v,i,p)
	local rot = {unpack(p.rot)}
	F_StartFocus(v,i,p)
	gAdjustRotation = {name = v.name,prop = i,off = rot}
	while gAdjustRotation and menu:active() do
		menu:draw(string.format("< %.1f, %.1f, %.1f >",math.deg(rot[1]),math.deg(rot[2]),math.deg(rot[3])))
		Wait(0)
		if menu:left() then
			break
		elseif menu:right() then
			p.rot = rot
			break
		elseif IsUsingJoystick(0) then
			local x,y = GetStickValue(16,0),GetStickValue(17,0)
			local speed = GetFrameTime()
			if IsButtonPressed(8,0) then
				speed = speed * 0.1
			end
			if IsButtonPressed(10,0) then
				rot[3] = F_FixRotation(rot[3] - speed)
			end
			if IsButtonPressed(12,0) then
				rot[3] = F_FixRotation(rot[3] + speed)
			end
			if x ~= 0 then
				rot[2] = F_FixRotation(rot[2] + x * speed)
			end
			if y ~= 0 then
				rot[1] = F_FixRotation(rot[1] - y * speed)
			end
		else
			local x,y = 0,0
			local speed = GetFrameTime()
			if IsKeyPressed("LCONTROL",0) then
				speed = speed * 0.1
			end
			if IsKeyPressed("W",0) then
				y = 1
			end
			if IsKeyPressed("S",0) then
				y = y - 1
			end
			if IsKeyPressed("D",0) then
				x = 1
			end
			if IsKeyPressed("A",0) then
				x = x - 1
			end
			if IsMousePressed(1) then
				rot[3] = F_FixRotation(rot[3] - speed)
			end
			if IsMousePressed(0) then
				rot[3] = F_FixRotation(rot[3] + speed)
			end
			if x ~= 0 then
				rot[2] = F_FixRotation(rot[2] + x * speed)
			end
			if y ~= 0 then
				rot[1] = F_FixRotation(rot[1] - y * speed)
			end
		end
	end
	gAdjustRotation = nil
	F_StopFocus()
end
function F_AdjustScale(menu,v,i,p)
	local scale = {unpack(p.scale)}
	F_StartFocus(v,i,p)
	gAdjustScaling = {name = v.name,prop = i,off = scale}
	while gAdjustScaling and menu:active() do
		menu:draw(string.format("< %.2f, %.2f, %.2f >",unpack(scale)))
		Wait(0)
		if menu:left() then
			break
		elseif menu:right() then
			p.scale = scale
			break
		elseif IsUsingJoystick(0) then
			local x,y = GetStickValue(16,0),GetStickValue(17,0)
			local speed = GetFrameTime()
			if IsButtonPressed(8,0) then
				speed = speed * 0.1
			end
			if IsButtonPressed(12,0) then
				scale[3] = scale[3] + speed
			end
			if IsButtonPressed(10,0) then
				scale[3] = scale[3] - speed
			end
			if y ~= 0 then
				scale[2] = scale[2] + y * speed
			end
			if x ~= 0 then
				scale[1] = scale[1] + x * speed
			end
		else
			local x,y = 0,0
			local speed = GetFrameTime()
			if IsKeyPressed("LCONTROL",0) then
				speed = speed * 0.1
			end
			if IsKeyPressed("W",0) then
				y = 1
			end
			if IsKeyPressed("S",0) then
				y = y - 1
			end
			if IsKeyPressed("D",0) then
				x = 1
			end
			if IsKeyPressed("A",0) then
				x = x - 1
			end
			if IsMousePressed(1) then
				scale[3] = scale[3] + speed
			end
			if IsMousePressed(0) then
				scale[3] = scale[3] - speed
			end
			if y ~= 0 then
				scale[2] = scale[2] + y * speed
			end
			if x ~= 0 then
				scale[1] = scale[1] + x * speed
			end
		end
	end
	gAdjustScaling = nil
	F_StopFocus()
end
function F_StartFocus(v,i,p)
	if dsl.freecam then
		dsl.freecam.SetFocus(function()
			local vehicle = VehicleFromDriver(gPlayer)
			if VehicleIsValid(vehicle) then
				local pos = vec3(VehicleGetPosXYZ(vehicle)) + VehicleGetMatrix(vehicle) * vec3(F_GetPropPosition(v,i,p))
				return pos[1],pos[2],pos[3]
			end
			return PlayerGetPosXYZ()
		end)
	end
end
function F_StopFocus()
	if dsl.freecam then
		dsl.freecam.SetFocus(nil)
	end
end
function M_SelectProp(parent)
	local files = {}
	local menu = parent:submenu("New Prop")
	for _,v in ipairs(gObjects) do
		local f = v[1]
		if not files[f] and v[2] ~= "panm" then
			table.insert(files,f)
			files[f] = true
		end
	end
	table.sort(files,function(a,b)
		return string.lower(a) < string.lower(b)
	end)
	while menu:active() do
		for _,v in ipairs(files) do
			if menu:option(v) then
				local model,name = M_SelectPropObject(parent,v)
				if model then
					return model,name
				end
			end
		end
		menu:draw()
		Wait(0)
	end
end
function M_SelectPropObject(parent,name)
	local preview
	local objects = {}
	local menu = parent:submenu(name)
	for _,v in ipairs(gObjects) do
		if v[1] == name and v[2] ~= "panm" then
			table.insert(objects,{v[3],v[4]})
		end
	end
	while menu:active() do
		for _,v in ipairs(objects) do
			if menu:option(v[2]) then
				if ObjectIsValid(gPreviewProp) then
					ObjectDelete(gPreviewProp)
				end
				gPreviewProp = -1
				return unpack(v)
			elseif menu:hover() and preview ~= v[1] then
				preview = v[1]
				if ObjectIsValid(gPreviewProp) then
					ObjectDelete(gPreviewProp)
				end
				gPreviewProp = ObjectCreateXYZ(preview,0,0,0)
			end
		end
		if ObjectIsValid(gPreviewProp) then
			if dsl.freecam and dsl.freecam.IsActive() then
				ObjectSetPosXYZ(gPreviewProp,dsl.freecam.GetPosition(0,10,0))
			else
				ObjectSetPosXYZ(gPreviewProp,PlayerGetPosXYZ())
			end
		end
		menu:draw()
		Wait(0)
	end
	if ObjectIsValid(gPreviewProp) then
		ObjectDelete(gPreviewProp)
	end
	gPreviewProp = -1
end

-- menu cleanup
RegisterLocalEventHandler("f2menu:Close",function()
	if gMenuActive then
		if dsl.freecam then
			dsl.freecam.Deactivate()
		end
		if ObjectIsValid(gPreviewProp) then
			ObjectDelete(gPreviewProp)
			gPreviewProp = -1
		end
		gAdjustPosition = nil
		gAdjustRotation = nil
		gAdjustScaling = nil
		gMenuActive = false
	end
end)

-- init script
SendNetworkEvent("propcars:StartScript")
