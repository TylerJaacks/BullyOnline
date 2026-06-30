LoadScript("objects.lua")

local MAX_PER_SCRIPT = 50

local gAllow = false -- allow object spawner menu
local gUpdate = false -- update object set menu
local gWaiting = false -- menu is waiting
local gEditing

local gFreecam = false
local gFocusObject
local gFocusScale
local gFocusPos
local gFocusOffset

local gSets = LoadTable("objects.bin")
local gActive = {} -- [id] = true
local gSpawned = {} -- [obj] = {...} -- see F_SpawnObject
local gInvisible = setmetatable({},{__mode = "k"}) -- force show invisible

local gPreviewModel
local gPreviewScript
local gPreviewObject
local gPreviewPersist
local gPreviewCollision = false
local gPreviewDistance

local gPreviewArray

local gCurrentCount = 0
local gObjectCreates = 0
local gPersistCreates = 0

local gScripts = {}

local gModels = {}
local gModelRequests = 0

-- events (local)
RegisterLocalEventHandler("f2menu:Open",function(f_add)
	if not gAllow then
		return
	end
	f_add({
		name = "Object Spawner",
		description = "(superadmin only)\nManage spawned objects.",
		thread = M_Main,
	})
end)
RegisterLocalEventHandler("f2menu:Close",function()
	F_PreviewObject()
	F_StopFreecam()
end)

-- events (admin)
RegisterNetworkEventHandler("object_spawner:AllowSpawner",function()
	gAllow = true
end)
RegisterNetworkEventHandler("object_spawner:SaveFailed",function()
	if dsl.chat then
		dsl.chat.Say("failed to save objects.bin")
	end
end)
RegisterNetworkEventHandler("object_spawner:CreateSet",function(id)
	gEditing = id
	gWaiting = false
end)
RegisterNetworkEventHandler("object_spawner:CreateObject",function(id)
	local set = gSets[id]
	if set then
		gEditing = set.objects[table.getn(set.objects)]
	end
	gWaiting = false
end)
RegisterNetworkEventHandler("object_spawner:FinishWaiting",function()
	gWaiting = false
end)

-- events (sets)
RegisterNetworkEventHandler("object_spawner:SetActive",function(ids)
	gActive = {}
	if ids then
		for _,id in ipairs(ids) do
			gActive[id] = true
		end
	end
end)
RegisterNetworkEventHandler("object_spawner:UpdateSet",function(id,set)
	gSets[id] = set
	gUpdate = true
end)
RegisterNetworkEventHandler("object_spawner:UpdateSets",function(sets)
	for id,set in pairs(sets) do
		gSets[id] = set
	end
	gUpdate = true
end)
RegisterNetworkEventHandler("object_spawner:ToggleSet",function(id,active)
	gActive[id] = active
end)
RegisterNetworkEventHandler("object_spawner:DefaultSet",function(id,active)
	gSets[id].active = active or nil
end)
RegisterNetworkEventHandler("object_spawner:DescribeSet",function(id,str)
	gSets[id].description = str
end)
RegisterNetworkEventHandler("object_spawner:OffsetSet",function(id,x,y,z,h)
	local set = gSets[id]
	set.x = x or 0
	set.y = y or 0
	set.z = z or 0
	set.h = h or 0
end)

-- events (objects)
RegisterNetworkEventHandler("object_spawner:AddObject",function(id,obj)
	table.insert(gSets[id].objects,obj)
end)
RegisterNetworkEventHandler("object_spawner:RemoveObject",function(id,index)
	table.remove(gSets[id].objects,index)
end)
RegisterNetworkEventHandler("object_spawner:RenameObject",function(id,index,name)
	gSets[id].objects[index].name = name
end)
RegisterNetworkEventHandler("object_spawner:OffsetObject",function(id,index,x,y,z,p,r,h,o)
	local obj = gSets[id].objects[index]
	obj.px,obj.py,obj.pz = x,y,z
	obj.rx,obj.ry,obj.rz = p,r,h
	obj.order = o
end)
RegisterNetworkEventHandler("object_spawner:RotateObject",function(id,index,p,r,h,o)
	local obj = gSets[id].objects[index]
	obj.rx,obj.ry,obj.rz,obj.order = p,r,h,o
end)
RegisterNetworkEventHandler("object_spawner:ScaleObject",function(id,index,x,y,z)
	local obj = gSets[id].objects[index]
	obj.sx,obj.sy,obj.sz = x,y,z
end)
RegisterNetworkEventHandler("object_spawner:DistanceObject",function(id,index,dist)
	gSets[id].objects[index].dist = dist
end)
RegisterNetworkEventHandler("object_spawner:PrioritizeObject",function(id,index,priority)
	gSets[id].objects[index].priority = priority
end)
RegisterNetworkEventHandler("object_spawner:VulnerableObject",function(id,index,vuln)
	gSets[id].objects[index].vulnerable = vuln
end)
RegisterNetworkEventHandler("object_spawner:FlagObject",function(id,index,flag,value)
	gSets[id].objects[index].flags[flag] = value or false
end)
RegisterNetworkEventHandler("object_spawner:TypeObject",function(id,index,type)
	gSets[id].objects[index].type = type
end)
RegisterNetworkEventHandler("object_spawner:AreaObject",function(id,index,area)
	gSets[id].objects[index].area = area
end)

-- cleanup
function MissionCleanup()
	for obj,data in pairs(gSpawned) do
		if data.type == "panm" and data.index ~= -1 then
			DeletePersistentEntity(data.index,data.pool)
		end
		gSpawned[obj] = nil
	end
	if gPreviewModel and gPreviewPersist and gPreviewObject[1] ~= -1 then
		DeletePersistentEntity(unpack(gPreviewModel))
	end
	if gPreviewArray and gPreviewArray.persist then
		for _,v in ipairs(gPreviewArray) do
			if v[1] ~= -1 then
				DeletePersistentEntity(unpack(v))
			end
		end
	end
	F_StopFreecam()
end

-- main / spawner
function main()
	local maximum = GetConfigNumber(GetScriptConfig(),"max_spawned",0)
	local buffer = GetConfigNumber(GetScriptConfig(),"despawn_buffer",0)
	SendNetworkEvent("object_spawner:InitScript")
	while true do
		local count = 0
		local needed = {}
		local nearest = {}
		local area = AreaGetVisible()
		local px,py,pz = PlayerGetPosXYZ()
		for id in pairs(gActive) do
			local set = gSets[id]
			if set then
				for _,obj in ipairs(set.objects) do
					if obj.area == area then
						local ox,oy,oz = F_GetPosition(set,obj)
						local dx,dy,dz = ox-px,oy-py,oz-pz
						local dist = dx*dx+dy*dy+dz*dz
						local view = obj.dist
						if gSpawned[obj] then
							view = math.sqrt(view) + buffer
							view = view * view
						end
						if dist < view then
							count = count + 1
							nearest[count] = {obj.priority,dist,set,obj}
						end
					end
				end
			end
		end
		if count > maximum then
			table.sort(nearest,F_SortNearest)
			count = maximum
		end
		for i = 1,count do
			needed[nearest[i][4]] = true
		end
		for obj,data in pairs(gSpawned) do
			if not needed[obj] then
				F_DeleteObject(obj,data)
				gSpawned[obj] = nil
			end
		end
		for i = 1,count do
			local v = nearest[i]
			local set,obj = v[3],v[4]
			local data = gSpawned[obj]
			if not data or not F_CheckObject(obj,data) or obj.type ~= data.type then
				if data then
					F_DeleteObject(obj,data)
				end
				data = F_SpawnObject(set,obj)
				gSpawned[obj] = data
			end
			F_UpdateObject(set,obj,data)
		end
		gCurrentCount = count
		Wait(0)
	end
end
function F_SortNearest(a,b)
	if a[1] ~= b[1] then
		return a[1] > b[1]
	end
	return a[2] < b[2]
end
function F_SpawnObject(set,obj)
	local data = {set = set,type = obj.type,vulnerable = false,script = F_UseScript()}
	local x,y,z = F_GetPosition(set,obj)
	F_AddModel(data.script,obj.model)
	if data.type == "panm" then
		local h = F_GetHeading(set,obj)
		data.index,data.pool = F_FromScript(data.script,CreatePersistentEntity,obj.model,x,y,z,math.deg(h),obj.area)
		data.x,data.y,data.z,data.h,data.a = x,y,z,h,obj.area
		gPersistCreates = gPersistCreates + 1
	else
		data.object = F_FromScript(data.script,ObjectCreateXYZ,obj.model,x,y,z)
		if ObjectIsValid(data.object) then
			ObjectToggleVulnerability(data.object,obj.vulnerable)
			data.vulnerable = obj.vulnerable
		end
		gObjectCreates = gObjectCreates + 1
	end
	return data
end
function F_UpdateObject(set,obj,data)
	local x,y,z = F_GetPosition(set,obj)
	if data.type == "panm" then
		local h = F_GetHeading(set,obj)
		if data.index ~= -1 and data.x ~= x or data.y ~= y or data.z ~= z or data.h ~= h or data.a ~= obj.area then
			F_FromScript(data.script,DeletePersistentEntity,data.index,data.pool)
			data.index,data.pool = F_FromScript(data.script,CreatePersistentEntity,obj.model,x,y,z,math.deg(h),obj.area)
			data.x,data.y,data.z,data.h,data.a = x,y,z,h,obj.area
			gPersistCreates = gPersistCreates + 1
		end
	elseif ObjectIsValid(data.object) then
		ObjectSetPosXYZ(data.object,x,y,z)
		ObjectSetMatrix(data.object,F_GetMatrix(set,obj)*F_GetScale(set,obj))
		if data.vulnerable ~= obj.vulnerable then
			ObjectToggleVulnerability(data.object,obj.vulnerable)
			data.vulnerable = obj.vulnerable
		end
		for f,v in pairs(obj.flags) do
			if ObjectGetEntityFlag(data.object,f) ~= v then
				ObjectSetEntityFlag(data.object,f,v)
			end
		end
		if gInvisible[set] and not ObjectGetEntityFlag(data.object,11) then
			ObjectSetEntityFlag(data.object,11,true)
		end
	end
end
function F_CheckObject(obj,data)
	if data.type == "panm" then
		return data.index ~= -1
	end
	return ObjectIsValid(data.object)
end
function F_DeleteObject(obj,data)
	if data.type == "panm" then
		if data.index ~= -1 then
			F_FromScript(data.script,DeletePersistentEntity,data.index,data.pool)
		end
	elseif ObjectIsValid(data.object) then
		F_FromScript(data.script,ObjectDelete,data.object)
	end
	F_RemoveModel(data.script,obj.model)
	F_ReleaseScript(data.script)
	data.script = nil
end

-- model loading
function F_AddModel(script,model)
	local models = gModels[script]
	if not models then
		F_FromScript(script,RequestModel,model)
		gModelRequests = gModelRequests + 1
		gModels[script] = {[model] = 1}
	elseif not models[model] then
		gModelRequests = gModelRequests + 1
		RequestModel(model)
		models[model] = 1
	else
		models[model] = models[model] + 1
	end
end
function F_RemoveModel(script,model)
	local models = gModels[script]
	if models and models[model] then
		models[model] = models[model] - 1
		if models[model] < 1 then
			F_FromScript(script,ModelNotNeeded,model)
			gModelRequests = gModelRequests - 1
			models[model] = nil
			if not next(models) then
				gModels[script] = nil
			end
		end
	end
end

-- script utility
function F_UseScript()
	for script,count in pairs(gScripts) do
		if count < MAX_PER_SCRIPT then
			gScripts[script] = count + 1
			return script
		end
	end
	local script = GetCurrentScript()
	if gScripts[script] then
		local count = 0
		for _ in pairs(gScripts) do
			count = count + 1
		end
		script = StartVirtualScript("objects_"..count,function()end)
	end
	gScripts[script] = 1
	return script
end
function F_ReleaseScript(script)
	gScripts[script] = gScripts[script] - 1
	if gScripts[script] <= 0 then
		if script ~= GetCurrentScript() then
			TerminateScript(script)
		end
		gScripts[script] = nil
	end
end
function F_FromScript(script,func,...)
	if not script then
		error("invalid script",2)
	end
	if script == GetCurrentScript() then
		return func(unpack(arg))
	end
	return CallFunctionFromScript(script,func,unpack(arg))
end

-- object positioning
function F_GetPosition(set,obj)
	local x,y,z
	if gFocusObject == set then
		xyz = vec3(gFocusPos.x,gFocusPos.y,gFocusPos.z) + Rz(gFocusPos.h) * vec3(obj.px,obj.py,obj.pz)
	elseif gFocusObject == obj then
		xyz = vec3(gFocusPos.x,gFocusPos.y,gFocusPos.z)
	else
		xyz = vec3(set.x,set.y,set.z) + Rz(set.h) * vec3(obj.px,obj.py,obj.pz)
	end
	return xyz[1],xyz[2],xyz[3]
end
function F_GetHeading(set,obj)
	if gFocusObject == set then
		return F_FixRadians(gFocusPos.h + obj.rz)
	elseif gFocusObject == obj then
		return gFocusPos.h
	end
	return F_FixRadians(set.h + obj.rz)
end
function F_GetMatrix(set,obj)
	if gFocusObject == set then
		return Rz(gFocusPos.h) * RotationMatrix(obj.rx,obj.ry,obj.rz,obj.order)
	elseif gFocusObject == obj then
		return RotationMatrix(gFocusPos.p,gFocusPos.r,gFocusPos.h,gFocusPos.o)
	end
	return Rz(set.h) * RotationMatrix(obj.rx,obj.ry,obj.rz,obj.order)
end
function F_GetScale(set,obj)
	local m = mat3()
	if gFocusScale and gFocusObject == obj then
		m[1][1] = gFocusScale[1]
		m[2][2] = gFocusScale[2]
		m[3][3] = gFocusScale[3]
	else
		m[1][1] = obj.sx
		m[2][2] = obj.sy
		m[3][3] = obj.sz
	end
	return m
end

-- spawner menu
function M_Main(parent,selected)
	local menu = parent:submenu(selected.name)
	local sets
	gUpdate = true
	while menu:active() do
		if gUpdate then
			sets = {}
			gUpdate = false
			for id,set in pairs(gSets) do
				table.insert(sets,{id,set})
			end
			table.sort(sets,function(a,b)
				return string.lower(a[1]) < string.lower(b[1])
			end)
		end
		if menu:option("< new set >") then
			local id = F_Type(menu,"id")
			if id then
				F_CreateSet(menu,id)
			end
		end
		for _,v in ipairs(sets) do
			if menu:option(v[1],gActive[v[1]] and "[X]" or "[ ]",v[2].description) then
				M_Set(menu,unpack(v))
			end
		end
		menu:help("objects active: "..F_GetActiveCount()..", spawned: "..gCurrentCount.."\nmodel requests: "..gModelRequests.."\nObjectCreateXYZ()s: "..gObjectCreates.."\nCreatePersistentEntity()s: "..gPersistCreates..F_GetScriptDebug())
		menu:draw()
		Wait(0)
	end
end
function M_Set(parent,id,set)
	local menu = parent:submenu(id,set.description)
	F_StartFreecam()
	while menu:active() and gSets[id] == set do
		if menu:option("Active",gActive[id] and "[X]" or "[ ]") then
			gWaiting = true
			if gActive[id] then
				SendNetworkEvent("object_spawner:ToggleSet",id)
			else
				SendNetworkEvent("object_spawner:ToggleSet",id,true)
			end
			while menu:active() and gWaiting do
				menu:draw("[...]")
				Wait(0)
			end
		elseif menu:option("Default Active",set.active and "[X]" or "[ ]") then
			gWaiting = true
			if set.active then
				SendNetworkEvent("object_spawner:DefaultSet",id)
			else
				SendNetworkEvent("object_spawner:DefaultSet",id,true)
			end
			while menu:active() and gWaiting do
				menu:draw("[...]")
				Wait(0)
			end
		elseif menu:option("Object List","["..table.getn(set.objects).."]") then
			M_Objects(menu,id,set)
		elseif menu:option("Invisible Objects",gInvisible[set] and "[SHOWN]" or "[DEFAULT]") then
			gInvisible[set] = not gInvisible[set] or nil
		elseif menu:option("Set Base Position",F_IsZeroBase(set) and "[ZERO]" or "[OFFSET]") then
			F_RepositionSet(menu,id,set)
		elseif menu:option("Zero Base Position") then
			SendNetworkEvent("object_spawner:OffsetSet",id)
		elseif menu:option("Update Object Areas") and F_Sure(menu) then
			F_UpdateObjectArea(menu,id,set)
		elseif menu:option("Import Script",nil,"copy and paste code that spawns objects / persistent entities") then
			F_ImportScript(menu,id,set)
		elseif menu:option("Set Description") then
			local typing = StartTyping()
			if typing then
				while menu:active() and gSets[id] == set do
					if not IsTypingActive(typing) then
						if not WasTypingAborted(typing) then
							local str = GetTypingString(typing)
							SendNetworkEvent("object_spawner:DescribeSet",id,str)
							menu:help(str)
						else
							menu:help(set.description)
						end
						break
					end
					menu:help("> "..GetTypingString(typing,true))
					menu:draw("[TYPING]")
					Wait(0)
				end
			end
		elseif menu:option("Duplicate Set") then
			local name = F_Type(menu)
			if name and gSets[id] == set then
				F_DuplicateSet(menu,id,name)
			end
		elseif menu:option("Delete Set") and F_Sure(menu) then
			gWaiting = true
			SendNetworkEvent("object_spawner:DeleteSet",id)
			while menu:active() and gWaiting do
				menu:draw("[DELETING...]")
				Wait(0)
			end
		end
		menu:draw()
		Wait(0)
	end
	F_StopFreecam()
end
function M_Objects(parent,id,set)
	local menu = parent:submenu("Object List")
	while menu:active() and gSets[id] == set do
		if menu:option("< new object >") then
			M_Create(menu,id,set)
		end
		for _,obj in ipairs(set.objects) do
			if menu:option(obj.name) then
				M_Object(menu,id,set,obj)
			elseif menu:hover() then
				local x2,y2,z2 = F_GetPosition(set,obj)
				local x,y = GetScreenCoords(x2,y2,z2)
				if x then
					local size = 0.025
					local ar = GetDisplayAspectRatio()
					local x1,y1,z1 = CameraGetXYZ()
					local dx,dy,dz = x2-x1,y2-y1,z2-z1
					size = size * (0.15 + 0.85 * math.max(0,1-math.sqrt(dx*dx+dy*dy+dz*dz)/20))
					DrawRectangle(x-(size*0.5)/ar,y-size*0.5,size/ar,size,255,0,255,255)
				end
			end
		end
		menu:draw()
		Wait(0)
	end
end
function M_Create(parent,id,set)
	local objects = F_SortObjects()
	local menu = parent:submenu("Spawn Object")
	gPreviewCollision = false
	gPreviewDistance = F_Get("distance")
	while menu:active() and gSets[id] == set do
		local any = false
		if menu:option("Object Sorting",F_Get("byindex") and "[ID]" or "[NAME]") then
			F_Set("byindex",not F_Get("byindex"))
			objects = F_SortObjects()
		elseif menu:option("Show OBJS",F_Get("objs") and "[ON]" or "[OFF]") then
			F_Set("objs",not F_Get("objs"))
			objects = F_SortObjects()
		elseif menu:option("Show TOBJ",F_Get("tobj") and "[ON]" or "[OFF]") then
			F_Set("tobj",not F_Get("tobj"))
			objects = F_SortObjects()
		elseif menu:option("Show PANM",F_Get("panm") and "[ON]" or "[OFF]") then
			F_Set("panm",not F_Get("panm"))
			objects = F_SortObjects()
		elseif menu:option("Collision Testing",gPreviewCollision and "[ON]" or "[OFF]","move the player on top of object previews to test collision") then
			gPreviewCollision = not gPreviewCollision
		elseif menu:option("Preview Distance","["..gPreviewDistance.."]") then
			gPreviewDistance = (math.mod(math.floor(gPreviewDistance/4),5)+1)*4
			F_Set("distance",gPreviewDistance)
		elseif menu:option("Search by Name") then
			F_PreviewObject()
			local search = F_Type(menu)
			if search and string.len(search) > 0 then
				M_Search(menu,id,set,search)
			end
		elseif menu:option("View by File") then
			F_PreviewObject()
			M_Files(menu,id,set)
		end
		for _,v in ipairs(objects) do
			if menu:option(v[4],"["..v[3].."]") then
				F_PreviewObject()
				F_CreateObject(menu,id,set,v)
			elseif menu:hover() then
				F_PreviewObject(v[3],v[2])
				any = true
			end
		end
		if not any then
			F_PreviewObject()
		end
		menu:draw()
		Wait(0)
	end
	F_PreviewObject()
end
function M_Search(parent,id,set,search)
	local objects = {}
	local menu = parent:submenu("\""..search.."\"")
	search = string.lower(search)
	for _,v in ipairs(F_SortObjects()) do
		if string.find(string.lower(v[4]),search,1,true) then
			table.insert(objects,v)
		end
	end
	if not objects[1] then
		parent:alert("No results found.")
		SoundPlay2D("WrongBtn")
		return
	end
	SoundPlay2D("RightBtn")
	while menu:active() and gSets[id] == set do
		for _,v in ipairs(objects) do
			if menu:option(v[4],"["..v[3].."]") then
				F_PreviewObject()
				F_CreateObject(menu,id,set,v)
			elseif menu:hover() then
				F_PreviewObject(v[3],v[2])
			end
		end
		menu:draw()
		Wait(0)
	end
	F_PreviewObject()
end
function M_Files(parent,id,set)
	local files = {}
	local menu = parent:submenu("Spawn by File")
	for _,v in ipairs(gObjects) do
		local f = v[1]
		if not files[f] then
			table.insert(files,f)
			files[f] = true
		end
	end
	table.sort(files,function(a,b)
		return string.lower(a) < string.lower(b)
	end)
	while menu:active() and gSets[id] == set do
		for _,f in ipairs(files) do
			if menu:option(f) then
				M_File(menu,id,set,f)
			end
		end
		menu:draw()
		Wait(0)
	end
end
function M_File(parent,id,set,f)
	local objects = {}
	local menu = parent:submenu(f)
	for _,v in ipairs(F_SortObjects()) do
		if v[1] == f then
			table.insert(objects,v)
		end
	end
	while menu:active() and gSets[id] == set do
		for _,v in ipairs(objects) do
			if menu:option(v[4],"["..v[3].."]") then
				F_PreviewObject()
				F_CreateObject(menu,id,set,v)
			elseif menu:hover() then
				F_PreviewObject(v[3],v[2])
			end
		end
		menu:draw()
		Wait(0)
	end
	F_PreviewObject()
end
function M_Object(parent,id,set,obj)
	local menu = parent:submenu(obj.name)
	local orders = {[0]="ZYX","YZX","ZXY","XZY","YXZ","XYZ"}
	while menu:active() and gSets[id] == set and F_GetArrayIndex(set.objects,obj) do
		if menu:option("Position",string.format("[%.1f, %.1f, %.1f]",obj.px,obj.py,obj.pz)) then
			F_RepositionObject(menu,id,set,obj)
		elseif menu:option("Rotation",string.format("[%.1f, %.1f, %.1f]",math.deg(obj.rx),math.deg(obj.ry),math.deg(obj.rz))) then
			F_RotateObject(menu,id,set,obj)
		elseif menu:option("Rotation Order","["..orders[obj.order].."]") then
			F_SetObject(menu,id,set,obj,"object_spawner:RotateObject",obj.rx,obj.ry,obj.rz,math.mod(obj.order+1,6))
		elseif menu:option("Reset Rotation") then
			F_SetObject(menu,id,set,obj,"object_spawner:RotateObject",0,0,set.h,obj.order)
		elseif menu:option("Scale",string.format("[%.1f, %.1f, %.1f]",obj.sx,obj.sy,obj.sz)) then
			F_ScaleObject(menu,id,set,obj)
		elseif menu:option("Reset Scale") then
			F_SetObject(menu,id,set,obj,"object_spawner:ScaleObject",1,1,1)
		elseif menu:option("View Distance","["..math.sqrt(obj.dist).."]","this is the distance the object can spawn. the despawn distance is slightly higher.") then
			local value = F_Adjust(menu,math.floor(math.sqrt(obj.dist)),0,300,5)
			if value then
				F_SetObject(menu,id,set,obj,"object_spawner:DistanceObject",value*value)
			end
		elseif menu:option("Spawn Priority","["..obj.priority.."]","objects with a higher priority spawn before objects with lower ones.") then
			F_SetObject(menu,id,set,obj,"object_spawner:PrioritizeObject",math.mod(obj.priority+1,3))
		elseif menu:option("Object Visibility",obj.flags[11] and "[ON]" or "[OFF]") then
			F_FlagObject(menu,id,set,obj,11,not obj.flags[11])
		elseif menu:option("Object Vulnerability",obj.vulnerable and "[ON]" or "[OFF]") then
			if obj.vulnerable then
				F_SetObject(menu,id,set,obj,"object_spawner:VulnerableObject")
			else
				F_SetObject(menu,id,set,obj,"object_spawner:VulnerableObject",true)
			end
		elseif menu:option("Object Type","["..string.upper(obj.type).."]","change how the object is viewed by the script. PANM objects are spawned as persistent entities.") then
			local v = F_GetObject(obj.model)
			if v then
				if obj.type ~= "panm" then
					F_SetObject(menu,id,set,obj,"object_spawner:TypeObject","panm")
				elseif v[2] == "panm" then
					F_SetObject(menu,id,set,obj,"object_spawner:TypeObject","objs")
				else
					F_SetObject(menu,id,set,obj,"object_spawner:TypeObject",v[2])
				end
			end
		elseif menu:option("Object Area","["..obj.area.."]") then
			F_SetObject(menu,id,set,obj,"object_spawner:AreaObject",AreaGetVisible())
		elseif menu:option("Duplicate Object Array") then
			M_DuplicateArray(menu,id,set,obj)
		elseif menu:option("Duplicate Object") then
			F_DuplicateObject(menu,id,set,obj)
		elseif menu:option("Rename Object") then
			F_RenameObject(menu,id,set,obj)
		elseif menu:option("Delete Object") and F_Sure(menu) then
			local index = F_GetArrayIndex(set.objects,obj)
			if index then
				gWaiting = true
				SendNetworkEvent("object_spawner:DeleteObject",id,index)
				while menu:active() and gWaiting do
					menu:draw("[DELETING...]")
					Wait(0)
				end
			end
		end
		menu:draw()
		Wait(0)
	end
end

-- debugging stuff
function F_GetActiveCount()
	local count = 0
	for id in pairs(gActive) do
		local set = gSets[id]
		if set then
			count = count + table.getn(set.objects)
		end
	end
	return count
end
function F_GetScriptDebug()
	local list = {}
	for script,count in pairs(gScripts) do
		table.insert(list,{GetScriptName(script),count})
	end
	table.sort(list,function(a,b)
		return string.lower(a[1]) < string.lower(b[1])
	end)
	for i,v in ipairs(list) do
		list[i] = v[1].." ("..v[2]..")"
	end
	if list[1] then
		return "\n"..table.concat(list,"\n")
	end
	return ""
end

-- script import
function F_ImportScript(menu,id,set)
	local typing = StartTyping()
	if typing then
		while menu:active() and gSets[id] == set do
			local ar = GetDisplayAspectRatio()
			local x,y,w,h = 0.5-0.5/ar,0,1/ar,1
			if not IsTypingActive(typing) then
				if not WasTypingAborted(typing) then
					F_ImportString(menu,id,set,GetTypingString(typing))
				end
				break
			end
			DrawRectangle(x,y,w,h,0,0,0,255)
			SetTextFont("Cascadia Mono")
			SetTextColor(255,255,255,255)
			SetTextClipping(w,h)
			SetTextAlign("L","T")
			SetTextPosition(x,y)
			SetTextHeight(0.02)
			DrawText(GetTypingString(typing,true))
			menu:draw("[TYPING]")
			Wait(0)
		end
	end
end
function F_ImportString(menu,id,set,str)
	local env = {}
	local objects = {}
	local chunk,result = loadstring(str,"@input")
	if chunk then
		env.CreatePersistentEntity = function(model,x,y,z,h,a)
			model = F_TranslateModel(model)
			if not F_GetObject(model) then
				error("invalid model",2)
			elseif type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
				error("invalid position",2)
			elseif type(h) ~= "number" then
				error("invalid heading",2)
			elseif type(a) ~= "number" or math.floor(a) ~= a then
				error("invalid area",2)
			end
			table.insert(objects,{m = model,x = x,y = y,z = z,h = math.rad(h),a = a})
			return table.getn(objects)
		end
		env.ObjectCreateXYZ = function(model,x,y,z)
			model = F_TranslateModel(model)
			if not F_GetObject(model) then
				error("invalid model",2)
			elseif type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
				error("invalid position",2)
			end
			table.insert(objects,{m = model,x = x,y = y,z = z,h = 0,a = AreaGetVisible()})
			return table.getn(objects)
		end
		setfenv(chunk,env)
		chunk,result = pcall(chunk)
	end
	if chunk then
		local n = table.getn(objects)
		for i,obj in ipairs(objects) do
			if gSets[id] == set then
				gEditing = nil
				gWaiting = true
				SendNetworkEvent("object_spawner:CreateObject",id,obj.m,obj.a,obj.h,obj.x,obj.y,obj.z)
				while menu:active() do
					if not gWaiting then
						local name
						for k,v in pairs(env) do
							if v == i then
								name = k
								break
							end
						end
						if name and gEditing and gSets[id] == set then
							local index = F_GetArrayIndex(set.objects,gEditing)
							if index then
								gWaiting = true
								SendNetworkEvent("object_spawner:RenameObject",id,index,name)
								while menu:active() and gWaiting do
									menu:draw("["..i.."/"..n.."]")
									Wait(0)
								end
							end
						end
						break
					end
					menu:draw("["..i.."/"..n.."]")
					Wait(0)
				end
			end
		end
	else
		menu:alert(result)
		SoundPlay2D("WrongBtn")
	end
end

-- object duplication
function M_DuplicateArray(parent,id,set,obj)
	local x = 0.5
	local y = 0.5
	local rows = 2
	local columns = 2
	local menu = parent:submenu("Duplicate Object Array")
	local saved = F_Get("_"..obj.model,true)
	if type(saved) == "table" then
		x,y,rows,columns = unpack(saved)
	end
	F_PreviewArray(set,obj,x,y,rows,columns)
	while menu:active() and gSets[id] == set and F_GetArrayIndex(set.objects,obj) do
		if menu:option("Row Count","["..rows.."]") then
			rows = F_Adjust(menu,rows,1,100,1)
			F_PreviewArray(set,obj,x,y,rows,columns)
		elseif menu:option("Row Offset",string.format("[%.3f]",x)) then
			local v = F_Type(menu)
			if v then
				v = tonumber(v)
				if v then
					x = v
				else
					menu:alert("Invalid input.")
					SoundPlay2D("WrongBtn")
				end
			end
			F_PreviewArray(set,obj,x,y,rows,columns)
		elseif menu:option("Column Count","["..columns.."]") then
			columns = F_Adjust(menu,columns,1,100,1)
			F_PreviewArray(set,obj,x,y,rows,columns)
		elseif menu:option("Column Offset",string.format("[%.3f]",y)) then
			local v = F_Type(menu)
			if v then
				v = tonumber(v)
				if v then
					y = v
				else
					menu:alert("Invalid input.")
					SoundPlay2D("WrongBtn")
				end
			end
			F_PreviewArray(set,obj,x,y,rows,columns)
		elseif menu:option("Save Defaults") then
			F_Set("_"..obj.model,{x,y,rows,columns})
		elseif menu:option("Confirm") and F_DupliateArray(menu,id,set,obj,x,y,rows,columns) then
			break
		end
		menu:draw()
		Wait(0)
	end
	F_PreviewArray()
end
function F_DupliateArray(menu,id,set,obj,x,y,w,h)
	local objects = {}
	local pos = vec3(F_GetPosition(set,obj))
	local mat = F_GetMatrix(set,obj)
	for c = 1,h do
		for r = 1,w do
			if r ~= 1 or c ~= 1 then
				objects[(r-1)+(c-1)*w] = {(pos+mat*vec3(x*(r-1),y*(c-1),0)):unpack()}
			end
		end
	end
	objects.n = table.getn(objects)
	for i,v in ipairs(objects) do
		local index = F_GetArrayIndex(set.objects,obj)
		if index and gSets[id] == set then
			gEditing = nil
			gWaiting = true
			SendNetworkEvent("object_spawner:DuplicateObject",id,index,unpack(v))
			while menu:active() do
				if not gWaiting then
					if gEditing then
						break
					end
					menu:alert("Failed to duplicate object.")
					SoundPlay2D("WrongBtn")
					return false
				end
				menu:draw("["..i.."/"..objects.n.."]")
				Wait(0)
			end
		end
	end
	SoundPlay2D("RightBtn")
	return true
end
function F_PreviewArray(set,obj,x,y,w,h)
	if not gPreviewArray or gPreviewArray.x ~= x or gPreviewArray.y ~= y or gPreviewArray.w ~= w or gPreviewArray.h ~= h then
		if gPreviewArray then
			for _,v in ipairs(gPreviewArray) do
				if gPreviewArray.persist then
					F_FromScript(v.script,DeletePersistentEntity,v.index,v.pool)
				else
					F_FromScript(v.script,ObjectDelete,v.object)
				end
				F_RemoveModel(v.script,gPreviewArray.model)
			end
			gPreviewArray = nil
		end
		if set then
			local pos = vec3(F_GetPosition(set,obj))
			local mat = F_GetMatrix(set,obj)
			gPreviewArray = {persist = obj.type == "panm",model = obj.model,x = x,y = y,w = w,h = h}
			for c = 1,h do
				for r = 1,w do
					if r ~= 1 or c ~= 1 then
						local v = {script = F_UseScript()}
						local x,y,z = (pos+mat*vec3(x*(r-1),y*(c-1),0)):unpack()
						F_AddModel(v.script,obj.model)
						if gPreviewArray.persist then
							v.index,v.pool = F_FromScript(v.script,CreatePersistentEntity,obj.model,x,y,z,F_GetHeading(set,obj),AreaGetVisible())
						else
							v.object = F_FromScript(v.script,ObjectCreateXYZ,obj.model,x,y,z)
							if ObjectIsValid(v.object) then
								ObjectSetPosXYZ(v.object,x,y,z)
								ObjectSetMatrix(v.object,mat)
							end
						end
						gPreviewArray[(r-1)+(c-1)*w] = v
					end
				end
			end
		end
	end
end

-- menu creates
function F_DuplicateSet(menu,id,name)
	gEditing = nil
	gWaiting = true
	SendNetworkEvent("object_spawner:DuplicateSet",id,name)
	while menu:active() do
		if not gWaiting then
			if gSets[gEditing] then
				menu:alert("Duplicated set.")
				SoundPlay2D("RightBtn")
			else
				menu:alert("Failed to duplicate set.")
				SoundPlay2D("WrongBtn")
			end
			break
		end
		menu:draw("[DUPLICATING...]")
		Wait(0)
	end
end
function F_DuplicateObject(menu,id,set,obj,...)
	local index = F_GetArrayIndex(set.objects,obj)
	if index then
		gEditing = nil
		gWaiting = true
		SendNetworkEvent("object_spawner:DuplicateObject",id,index,unpack(arg))
		while menu:active() do
			if not gWaiting then
				if gEditing then
					menu:alert("Duplicated object.")
					SoundPlay2D("RightBtn")
				else
					menu:alert("Failed to duplicate object.")
					SoundPlay2D("WrongBtn")
				end
				break
			end
			menu:draw("[DUPLICATING...]")
			Wait(0)
		end
	end
end
function F_CreateSet(menu,id)
	gEditing = nil
	gWaiting = true
	SendNetworkEvent("object_spawner:CreateSet",id)
	while menu:active() do
		if not gWaiting then
			if gSets[gEditing] then
				M_Set(menu,gEditing,gSets[gEditing])
			else
				menu:alert("Failed to create set.")
				SoundPlay2D("WrongBtn")
			end
			break
		end
		menu:draw("[CREATING...]")
		Wait(0)
	end
end
function F_CreateObject(menu,id,set,v)
	gEditing = nil
	gWaiting = true
	if dsl.freecam then
		local p,r,h = dsl.freecam.GetRotation()
		SendNetworkEvent("object_spawner:CreateObject",id,v[3],AreaGetVisible(),h,dsl.freecam.GetPosition(0,3,0))
	else
		SendNetworkEvent("object_spawner:CreateObject",id,v[3],AreaGetVisible(),PedGetHeading(gPlayer),PlayerGetPosXYZ())
	end
	while menu:active() and gSets[id] == set do
		if not gWaiting then
			for _,obj in ipairs(set.objects) do
				if obj == gEditing then
					M_Object(menu,id,set,obj)
					break
				end
			end
			break
		end
		menu:draw("[CREATING...]")
		Wait(0)
	end
end

-- menu objects
function F_UpdateObjectArea(menu,id,set)
	local index = 1
	local area = AreaGetVisible()
	while menu:active() and set.objects[index] and gSets[id] == set do
		F_SetObject(menu,id,set,set.objects[index],"object_spawner:AreaObject",area)
		index = index + 1
	end
end
function F_RepositionSet(menu,id,set)
	F_FocusFreecam(set)
	if F_IsZeroBase(set) and not set.objects[1] then
		local x,y,z = PlayerGetPosXYZ()
		gFocusPos = {x = x,y = y,z = z,h = PedGetHeading(gPlayer)}
	else
		gFocusPos = {x = set.x,y = set.y,z = set.z,h = set.h}
	end
	gFocusOffset = vec3(dsl.freecam.GetPosition()) - vec3(gFocusPos.x,gFocusPos.y,gFocusPos.z)
	while menu:active() and gSets[id] == set and gFocusObject do
		if dsl.freecam then
			local x,y,z = dsl.freecam.GetFocusMove()
			gFocusPos.h = F_FixRadians(gFocusPos.h + F_GetRotation() * GetFrameTime() * F_GetSpeed() * math.pi * 0.5)
			gFocusPos.x = gFocusPos.x + x
			gFocusPos.y = gFocusPos.y + y
			gFocusPos.z = gFocusPos.z + z
		end
		menu:draw("[MOVING]")
		F_DrawText(string.format("%.2f, %.2f, %.2f (%.1f)",gFocusPos.x,gFocusPos.y,gFocusPos.z,math.deg(gFocusPos.h)))
		Wait(0)
		if menu:left() then
			break
		elseif menu:right() then
			gWaiting = true
			SendNetworkEvent("object_spawner:OffsetSet",id,gFocusPos.x,gFocusPos.y,gFocusPos.z,gFocusPos.h)
			while menu:active() and gWaiting do
				menu:draw("[MOVING...]")
				Wait(0)
			end
			break
		end
	end
	F_FocusFreecam(nil)
end
function F_RepositionObject(menu,id,set,obj)
	local helped = false
	F_FocusFreecam(obj)
	F_FocusObject(set,obj)
	if not IsUsingJoystick(0) then
		menu:help("use F to duplicate in-place\nuse V to snap heading")
		helped = true
	end
	while menu:active() and gSets[id] == set and F_GetArrayIndex(set.objects,obj) and gFocusObject do
		if dsl.freecam then
			local x,y,z = dsl.freecam.GetFocusMove()
			gFocusPos.h = F_FixRadians(gFocusPos.h + F_GetRotation() * GetFrameTime() * F_GetSpeed() * math.pi * 0.5)
			gFocusPos.x = gFocusPos.x + x
			gFocusPos.y = gFocusPos.y + y
			gFocusPos.z = gFocusPos.z + z
		end
		menu:draw("[MOVING]")
		F_DrawText(string.format("%.2f, %.2f, %.2f (%.1f)",gFocusPos.x,gFocusPos.y,gFocusPos.z,math.deg(gFocusPos.h)))
		Wait(0)
		if menu:left() then
			break
		elseif menu:right() then
			local index = F_GetArrayIndex(set.objects,obj)
			if index then
				gWaiting = true
				SendNetworkEvent("object_spawner:OffsetObject",id,index,gFocusPos.x,gFocusPos.y,gFocusPos.z,gFocusPos.p,gFocusPos.r,gFocusPos.h,gFocusPos.o)
				while menu:active() and gWaiting do
					menu:draw("[MOVING...]")
					Wait(0)
				end
				break
			end
		elseif IsKeyBeingPressed("F",0) and F_GetArrayIndex(set.objects,obj) then
			F_DuplicateObject(menu,id,set,obj,gFocusPos.x,gFocusPos.y,gFocusPos.z,gFocusPos.p,gFocusPos.r,gFocusPos.h,gFocusPos.o)
		elseif IsKeyBeingPressed("V",0) then
			local h = math.rad(F_RoundValue(math.abs(math.deg(gFocusPos.h)) / 5) * 5)
			if gFocusPos.h < 0 then
				gFocusPos.h = -h
			else
				gFocusPos.h = h
			end
		end
	end
	if helped then
		menu:help(nil)
	end
	F_FocusFreecam(nil)
end
function F_RotateObject(menu,id,set,obj)
	F_FocusFreecam(obj)
	F_FocusObject(set,obj)
	while menu:active() and gSets[id] == set and F_GetArrayIndex(set.objects,obj) and gFocusObject do
		if dsl.freecam then
			local x,y = F_GetAdjustment()
			local speed = GetFrameTime() * F_GetSpeed() * math.pi * 0.5
			gFocusPos.p = F_FixRadians(gFocusPos.p + y * speed)
			gFocusPos.r = F_FixRadians(gFocusPos.r + x * speed)
			gFocusPos.h = F_FixRadians(gFocusPos.h + F_GetRotation() * speed)
		end
		menu:draw("[ROTATING]")
		F_DrawText(string.format("%.2f, %.2f, %.2f (%d)",math.deg(gFocusPos.p),math.deg(gFocusPos.r),math.deg(gFocusPos.h),gFocusPos.o))
		Wait(0)
		if menu:left() then
			break
		elseif menu:right() then
			local index = F_GetArrayIndex(set.objects,obj)
			if index then
				gWaiting = true
				SendNetworkEvent("object_spawner:RotateObject",id,index,gFocusPos.p,gFocusPos.r,gFocusPos.h,gFocusPos.o)
				while menu:active() and gWaiting do
					menu:draw("[ROTATING...]")
					Wait(0)
				end
				break
			end
		end
	end
	F_FocusFreecam(nil)
end
function F_ScaleObject(menu,id,set,obj)
	F_FocusFreecam(obj)
	F_FocusObject(set,obj)
	gFocusScale = {obj.sx,obj.sy,obj.sz}
	while menu:active() and gSets[id] == set and F_GetArrayIndex(set.objects,obj) and gFocusObject do
		if dsl.freecam then
			local x,y = F_GetAdjustment()
			local speed = GetFrameTime() * F_GetSpeed() * 0.5
			gFocusScale[1] = gFocusScale[1] + x * speed
			gFocusScale[2] = gFocusScale[2] + y * speed
			gFocusScale[3] = gFocusScale[3] + F_GetRotation() * speed
		end
		menu:draw("[SCALING]")
		F_DrawText(string.format("%.2f, %.2f, %.2f",unpack(gFocusScale)))
		Wait(0)
		if menu:left() then
			break
		elseif menu:right() then
			local index = F_GetArrayIndex(set.objects,obj)
			if index then
				gWaiting = true
				SendNetworkEvent("object_spawner:ScaleObject",id,index,unpack(gFocusScale))
				while menu:active() and gWaiting do
					menu:draw("[SCALING...]")
					Wait(0)
				end
				break
			end
		end
	end
	F_FocusFreecam(nil)
end
function F_FlagObject(menu,id,set,obj,flag,value)
	local index = F_GetArrayIndex(set.objects,obj)
	if index then
		gWaiting = true
		if value then
			SendNetworkEvent("object_spawner:FlagObject",id,index,flag,true)
		else
			SendNetworkEvent("object_spawner:FlagObject",id,index,flag)
		end
		while menu:active() and gWaiting do
			menu:draw("[...]")
			Wait(0)
		end
	end
end
function F_RenameObject(menu,id,set,obj)
	local name = F_Type(menu)
	if name then
		local index = F_GetArrayIndex(set.objects,obj)
		if index then
			gWaiting = true
			SendNetworkEvent("object_spawner:RenameObject",id,index,name)
			while menu:active() do
				if not gWaiting then
					if obj.name == name then
						menu.title_text = name
					else
						menu:alert("Failed to set name.")
						SoundPlay2D("WrongBtn")
					end
					break
				end
				menu:draw("[RENAMING...]")
				Wait(0)
			end
		end
	end
end
function F_SetObject(menu,id,set,obj,event,...)
	local index = F_GetArrayIndex(set.objects,obj)
	if index then
		gWaiting = true
		SendNetworkEvent(event,id,index,unpack(arg))
		while menu:active() and gWaiting do
			menu:draw("[...]")
			Wait(0)
		end
	end
end

-- menu sorting
function F_SortObjects()
	local objects
	local exclude = {}
	for _,v in ipairs({"objs","tobj","panm"}) do
		if not F_Get(v) then
			exclude[v] = true
		end
	end
	if next(exclude) then
		objects = {}
		for _,v in ipairs(gObjects) do
			if not exclude[v[2]] then
				table.insert(objects,v)
			end
		end
	else
		objects = gObjects
	end
	if F_Get("byindex") then
		table.sort(objects,F_SortIndex)
	else
		table.sort(objects,F_SortName)
	end
	return objects
end
function F_SortIndex(a,b)
	return a[3] < b[3]
end
function F_SortName(a,b)
	return string.lower(a[4]) < string.lower(b[4])
end

-- menu utility
function F_Sure(menu)
	while menu:active() do
		menu:draw("[SURE?]")
		Wait(0)
		if menu:left() then
			break
		elseif menu:right() then
			return true
		end
	end
	return false
end
function F_Type(menu,prefix)
	local typing = StartTyping()
	if typing then
		while menu:active() do
			if not IsTypingActive(typing) then
				if WasTypingAborted(typing) then
					break
				end
				return GetTypingString(typing)
			end
			menu:draw(GetTypingString(typing,true))
			Wait(0)
		end
	end
end
function F_Adjust(menu,value,minimum,maximum,step)
	while menu:active() do
		menu:draw("> "..value.." <")
		Wait(0)
		if menu:up() then
			value = value + step
			if value > maximum then
				value = maximum
			end
		elseif menu:down() then
			value = value - step
			if value < minimum then
				value = minimum
			end
		elseif menu:left() then
			break
		elseif menu:right() then
			return value
		end
	end
end

-- free cam / object preview utility
function F_PreviewObject(model,type)
	if model then
		if dsl.freecam and gPreviewModel ~= model then
			local x,y,z = dsl.freecam.GetPosition(0,gPreviewDistance,0)
			if gPreviewModel then
				F_PreviewObject()
			end
			gPreviewModel = model
			gPreviewScript = F_UseScript()
			F_AddModel(gPreviewScript,model)
			if type == "panm" then
				gPreviewObject = {F_FromScript(gPreviewScript,CreatePersistentEntity,model,x,y,z,0,AreaGetVisible())}
				gPreviewPersist = true
			else
				gPreviewObject = F_FromScript(gPreviewScript,ObjectCreateXYZ,model,x,y,z)
				gPreviewPersist = false
			end
			if gPreviewCollision then
				local hp = PedGetMaxHealth(gPlayer)
				if PlayerGetHealth() < hp then
					PlayerSetHealth(hp)
				end
				PlayerSetPosXYZ(x,y,z+5)
			end
		end
	elseif gPreviewModel then
		if gPreviewPersist then
			if gPreviewObject[1] ~= -1 then
				F_FromScript(gPreviewScript,DeletePersistentEntity,unpack(gPreviewObject))
			end
		elseif ObjectIsValid(gPreviewObject) then
			F_FromScript(gPreviewScript,ObjectDelete,gPreviewObject)
		end
		F_RemoveModel(gPreviewScript,gPreviewModel)
		F_ReleaseScript(gPreviewScript)
		gPreviewModel = nil
		gPreviewScript = nil
		gPreviewObject = nil
		gPreviewPersist = nil
	end
end
function F_StartFreecam()
	if dsl.freecam then
		if not gFreecam then
			dsl.freecam.Activate()
			gFreecam = true
		end
		dsl.freecam.SetFocus(nil)
	end
end
function F_StopFreecam()
	if gFreecam then
		if dsl.freecam then
			dsl.freecam.Deactivate()
		end
		gFreecam = false
	end
	gFocusObject = nil
end
function F_FocusFreecam(focus)
	if dsl.freecam then
		if focus then
			dsl.freecam.SetFocus(CB_FreecamFocus)
			gFocusObject = focus
			gFocusScale = nil
			gFocusPos = nil
		else
			dsl.freecam.SetFocus(nil)
			gFocusObject = nil
			gFocusScale = nil
			gFocusPos = nil
		end
	end
end
function F_FocusObject(set,obj)
	local xyz = vec3(set.x,set.y,set.z) + Rz(set.h) * vec3(obj.px,obj.py,obj.pz)
	local p,r,h = GetMatrixRotation(Rz(set.h) * RotationMatrix(obj.rx,obj.ry,obj.rz,obj.order),obj.order)
	gFocusPos = {x = xyz[1],y = xyz[2],z = xyz[3],p = p,r = r,h = h,o = obj.order}
	gFocusOffset = nil
end
function CB_FreecamFocus()
	if gFocusPos then
		if gFocusOffset then
			return (gFocusOffset+vec3(gFocusPos.x,gFocusPos.y,gFocusPos.z)):unpack()
		end
		return gFocusPos.x,gFocusPos.y,gFocusPos.z
	end
	return PlayerGetPosXYZ() -- in emergency, just use player position
end

-- persistent data utility
function F_Defaults()
	return {
		byindex = false,
		distance = 4,
		objs = true,
		tobj = true,
		panm = true,
	}
end
function F_Get(key,optional)
	local persist = GetPersistentDataTable("Xx_Yubari_xX")
	local data = persist.object_spawner
	if data then
		local value = data[key]
		if not optional and value == nil then
			value = F_Defaults()[key]
			data[key] = value
			SavePersistentDataTables()
		end
		return value
	end
	data = F_Defaults()
	persist.object_spawner = data
	SavePersistentDataTables()
	return data[key]
end
function F_Set(key,value)
	local persist = GetPersistentDataTable("Xx_Yubari_xX")
	local data = persist.object_spawner
	if not data then
		data = F_Defaults()
		persist.object_spawner = data
	end
	data[key] = value
	SavePersistentDataTables()
end

-- controls utility
function F_GetSpeed()
	if IsUsingJoystick(0) then
		if IsButtonPressed(7,0) then
			return 5
		elseif IsButtonPressed(8,0) then
			return 0.05
		end
	elseif IsKeyPressed("LSHIFT",0) then
		return 5
	elseif IsKeyPressed("LCONTROL",0) then
		return 0.05
	end
	return 1
end
function F_GetAdjustment()
	if not IsUsingJoystick(0) then
		local x,y = 0,0
		if IsKeyPressed("W",0) then
			y = y + 1
		end
		if IsKeyPressed("A",0) then
			x = x - 1
		end
		if IsKeyPressed("S",0) then
			y = y - 1
		end
		if IsKeyPressed("D",0) then
			x = x + 1
		end
		return x,y
	end
	return GetStickValue(16,0),GetStickValue(17,0)
end
function F_GetRotation()
	local frame = GetFrameTime()
	if not IsUsingJoystick(0) then
		if IsButtonPressed(10,0) then
			return -1
		elseif IsButtonPressed(12,0) then
			return 1
		end
	elseif IsMousePressed(1) then
		return -1
	elseif IsMousePressed(0) then
		return 1
	end
	return 0
end

-- miscellaneous utility
function F_RoundValue(v)
	local f = math.floor(v)
	if v < 0 then
		if f - v < -0.5 then
			return math.ceil(v)
		end
	elseif v - f >= 0.5 then
		return math.ceil(v)
	end
	return f
end
function F_TranslateModel(model)
	if type(model) == "string" then
		for _,v in ipairs(gObjects) do
			if v[4] == model then
				return v[3]
			end
		end
	end
	return model
end
function F_GetObject(model)
	for _,v in ipairs(gObjects) do
		if v[3] == model then
			return v
		end
	end
end
function F_DrawText(text)
	SetTextFont("Arial")
	SetTextBlack()
	SetTextColor(255,255,255,255)
	SetTextShadow()
	SetTextAlign("C","B")
	SetTextPosition(0.5,0.98)
	DrawText(text)
end
function F_FixRadians(h)
	while h > math.pi do
		h = h - math.pi * 2
	end
	while h <= -math.pi do
		h = h + math.pi * 2
	end
	return h
end
function F_IsZeroBase(set)
	return set.x == 0 and set.y == 0 and set.z == 0 and set.h == 0
end
function F_GetArrayIndex(array,value)
	for i,v in ipairs(array) do
		if v == value then
			return i
		end
	end
end
