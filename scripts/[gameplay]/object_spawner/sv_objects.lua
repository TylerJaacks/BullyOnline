LoadScript("objects.lua")

local gSets = LoadTable("objects.bin")
local gRemoved = {} -- [id] = true
local gDimensions = setmetatable({},{__mode = "k"})
local gPlayers = {}

function exports.Activate(id)
	F_Activate(id,GetSyncActiveDimension())
end
function exports.Deactivate(id)
	F_Deactivate(id,GetSyncActiveDimension())
end
function F_Activate(id,di)
	if gSets[id] then
		local sets = gDimensions[di]
		if sets then
			if sets[id] then
				return
			end
			sets[id] = true
		else
			gDimensions[di] = {[id] = true}
		end
		for player in pairs(gPlayers) do
			if IsPlayerValid(player,false) and GetSyncEntityDimension(GetSyncPlayerPed(player)) == di then
				SendNetworkEvent(player,"object_spawner:ToggleSet",id,true)
			end
		end
	end
end
function F_Deactivate(id,di)
	local sets = gDimensions[di]
	if sets and sets[id] then
		sets[id] = nil
		if not next(sets) then
			gDimensions[di] = nil
		end
		for player in pairs(gPlayers) do
			if IsPlayerValid(player,false) and GetSyncEntityDimension(GetSyncPlayerPed(player)) == di then
				SendNetworkEvent(player,"object_spawner:ToggleSet",id)
			end
		end
	end
end

RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterLocalEventHandler("sync:SwapPlayer",function(player,ped)
	if gPlayers[player] then
		F_UpdatePlayerSets(player,GetSyncEntityDimension(ped))
	end
end)
RegisterLocalEventHandler("sync:SwapDimension",function(ped,di)
	local player = GetSyncPlayerFromPed(ped)
	if gPlayers[player] then
		F_UpdatePlayerSets(player,di)
	end
end)
RegisterNetworkEventHandler("object_spawner:InitScript",function(player)
	local sets = {}
	local data = {allow = F_CheckPermissions(player)}
	if data.allow then
		SendNetworkEvent(player,"object_spawner:AllowSpawner")
	end
	for id,set in pairs(gSets) do
		if set.update then
			local copy = {}
			for k,v in pairs(set) do
				if k ~= "update" then
					copy[k] = v
				end
			end
			sets[id] = copy
		end
	end
	if next(sets) then
		SendNetworkEvent(player,"object_spawner:UpdateSets",sets) -- updated sets
	end
	for id in pairs(gRemoved) do
		SendNetworkEvent(player,"object_spawner:UpdateSet",id) -- removed sets
	end
	F_UpdatePlayerSets(player,GetSyncEntityDimension(GetSyncPlayerPed(player)))
	gPlayers[player] = data
end)

RegisterNetworkEventHandler("object_spawner:CreateSet",function(player,id)
	local data = gPlayers[player]
	if not data or not data.allow then
		return
	end
	id = string.lower(id)
	if gSets[id] or not F_IsOkaySetId(id) then
		SendNetworkEvent(player,"object_spawner:CreateSet")
		return
	end
	gRemoved[id] = nil
	gSets[id] = F_CreateSet(player)
	for player in pairs(gPlayers) do
		SendNetworkEvent(player,"object_spawner:UpdateSet",id,gSets[id])
	end
	SendNetworkEvent(player,"object_spawner:CreateSet",id)
	F_SaveSets()
end)
RegisterNetworkEventHandler("object_spawner:DuplicateSet",function(player,id,name)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		id = string.lower(name)
		if set and not gSets[id] and F_IsOkaySetId(id) then
			local copy = F_CopyValue(set)
			copy.update = true
			gRemoved[id] = nil
			gSets[id] = copy
			for player in pairs(gPlayers) do
				SendNetworkEvent(player,"object_spawner:UpdateSet",id,copy)
			end
			SendNetworkEvent(player,"object_spawner:CreateSet",id)
			F_SaveSets()
		else
			SendNetworkEvent(player,"object_spawner:CreateSet")
		end
	end
end)
RegisterNetworkEventHandler("object_spawner:DeleteSet",function(player,id)
	local data = gPlayers[player]
	if data and data.allow then
		if gSets[id] then
			for di in pairs(gDimensions) do
				F_Deactivate(id,di)
			end
			for player in pairs(gPlayers) do
				SendNetworkEvent(player,"object_spawner:UpdateSet",id)
			end
			gRemoved[id] = true
			gSets[id] = nil
			F_SaveSets()
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:ToggleSet",function(player,id,active)
	local data = gPlayers[player]
	if data and data.allow then
		local di = GetSyncEntityDimension(GetSyncPlayerPed(player))
		if active then
			F_Activate(id,di)
		else
			F_Deactivate(id,di)
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:DefaultSet",function(player,id,active)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			for player in pairs(gPlayers) do
				if active then
					SendNetworkEvent(player,"object_spawner:DefaultSet",id,true)
				else
					SendNetworkEvent(player,"object_spawner:DefaultSet",id)
				end
			end
			if active then
				set.active = true
			else
				set.active = false
			end
			set.update = true
			F_SaveSets()
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:DescribeSet",function(player,id,str)
	local set = gSets[id]
	local data = gPlayers[player]
	if set and data and data.allow then
		for player in pairs(gPlayers) do
			SendNetworkEvent(player,"object_spawner:DescribeSet",id,str)
		end
		set.description = tostring(str)
		set.update = true
		F_SaveSets()
	end
end)
RegisterNetworkEventHandler("object_spawner:OffsetSet",function(player,id,x,y,z,h)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			for player in pairs(gPlayers) do
				if x then
					SendNetworkEvent(player,"object_spawner:OffsetSet",id,x,y,z,h)
				else
					SendNetworkEvent(player,"object_spawner:OffsetSet",id)
				end
			end
			set.x = x or 0
			set.y = y or 0
			set.z = z or 0
			set.h = h or 0
			set.update = true
			F_SaveSets()
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)

RegisterNetworkEventHandler("object_spawner:CreateObject",function(player,id,model,area,h,x,y,z)
	local data = gPlayers[player]
	if data and data.allow then
		local v = F_GetObject(model)
		local set = gSets[id]
		if v and set then
			local x,y,z = F_GetOffset(set,x,y,z)
			local p,r,h = F_GetRotation(set,0,0,h,0)
			local obj = F_CreateObject(v,x,y,z,h,area)
			for player in pairs(gPlayers) do
				SendNetworkEvent(player,"object_spawner:AddObject",id,obj)
			end
			table.insert(set.objects,obj)
			set.update = true
			SendNetworkEvent(player,"object_spawner:CreateObject",id)
			F_SaveSets()
		else
			SendNetworkEvent(player,"object_spawner:CreateObject")
		end
	end
end)
RegisterNetworkEventHandler("object_spawner:DuplicateObject",function(player,id,index,x,y,z,p,r,h,o)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			local source = set.objects[index]
			if source then
				local obj = F_CopyValue(source)
				if x then
					obj.px,obj.py,obj.pz = F_GetOffset(set,x,y,z)
					if p then
						obj.rx,obj.ry,obj.rz = F_GetRotation(set,p,r,h,o)
						obj.order = o
					end
				end
				for player in pairs(gPlayers) do
					SendNetworkEvent(player,"object_spawner:AddObject",id,obj)
				end
				table.insert(set.objects,obj)
				set.update = true
				SendNetworkEvent(player,"object_spawner:CreateObject",id)
				F_SaveSets()
				return
			end
		end
		SendNetworkEvent(player,"object_spawner:CreateObject")
	end
end)
RegisterNetworkEventHandler("object_spawner:DeleteObject",function(player,id,index)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set and set.objects[index] then
			for player in pairs(gPlayers) do
				SendNetworkEvent(player,"object_spawner:RemoveObject",id,index)
			end
			table.remove(set.objects,index)
			set.update = true
			F_SaveSets()
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:RenameObject",function(player,id,index,name)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			local obj = set.objects[index]
			if obj and not string.find(name,"[^%w_]") then
				for player in pairs(gPlayers) do
					SendNetworkEvent(player,"object_spawner:RenameObject",id,index,name)
				end
				obj.name = name
				set.update = true
				F_SaveSets()
			end
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:OffsetObject",function(player,id,index,x,y,z,p,r,h,o)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			local obj = set.objects[index]
			if obj then
				local x,y,z = F_GetOffset(set,x,y,z)
				local p,r,h = F_GetRotation(set,p,r,h,o)
				for player in pairs(gPlayers) do
					SendNetworkEvent(player,"object_spawner:OffsetObject",id,index,x,y,z,p,r,h,o)
				end
				obj.px,obj.py,obj.pz = x,y,z
				obj.rx,obj.ry,obj.rz,obj.order = p,r,h,o
				set.update = true
				F_SaveSets()
			end
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:RotateObject",function(player,id,index,p,r,h,o)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			local obj = set.objects[index]
			if obj then
				local p,r,h = F_GetRotation(set,p,r,h,o)
				for player in pairs(gPlayers) do
					SendNetworkEvent(player,"object_spawner:RotateObject",id,index,p,r,h,o)
				end
				obj.rx,obj.ry,obj.rz,obj.order = p,r,h,o
				set.update = true
				F_SaveSets()
			end
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:ScaleObject",function(player,id,index,x,y,z)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			local obj = set.objects[index]
			if obj then
				for player in pairs(gPlayers) do
					SendNetworkEvent(player,"object_spawner:ScaleObject",id,index,x,y,z)
				end
				obj.sx,obj.sy,obj.sz = x,y,z
				set.update = true
				F_SaveSets()
			end
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:DistanceObject",function(player,id,index,dist)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			local obj = set.objects[index]
			if obj then
				for player in pairs(gPlayers) do
					SendNetworkEvent(player,"object_spawner:DistanceObject",id,index,dist)
				end
				obj.dist = dist
				set.update = true
				F_SaveSets()
			end
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:PrioritizeObject",function(player,id,index,priority)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			local obj = set.objects[index]
			if obj then
				for player in pairs(gPlayers) do
					SendNetworkEvent(player,"object_spawner:PrioritizeObject",id,index,priority)
				end
				obj.priority = priority
				set.update = true
				F_SaveSets()
			end
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:VulnerableObject",function(player,id,index,vuln)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			local obj = set.objects[index]
			if obj then
				for player in pairs(gPlayers) do
					if vuln then
						SendNetworkEvent(player,"object_spawner:VulnerableObject",id,index,true)
					else
						SendNetworkEvent(player,"object_spawner:VulnerableObject",id,index)
					end
				end
				obj.vulnerable = vuln
				set.update = true
				F_SaveSets()
			end
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:FlagObject",function(player,id,index,flag,value)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			local obj = set.objects[index]
			if obj then
				for player in pairs(gPlayers) do
					if value then
						SendNetworkEvent(player,"object_spawner:FlagObject",id,index,flag,true)
					else
						SendNetworkEvent(player,"object_spawner:FlagObject",id,index,flag)
					end
				end
				obj.flags[flag] = value or false
				set.update = true
				F_SaveSets()
			end
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:TypeObject",function(player,id,index,type)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			local obj = set.objects[index]
			if obj then
				for player in pairs(gPlayers) do
					SendNetworkEvent(player,"object_spawner:TypeObject",id,index,type)
				end
				obj.type = type
				set.update = true
				F_SaveSets()
			end
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)
RegisterNetworkEventHandler("object_spawner:AreaObject",function(player,id,index,area)
	local data = gPlayers[player]
	if data and data.allow then
		local set = gSets[id]
		if set then
			local obj = set.objects[index]
			if obj then
				for player in pairs(gPlayers) do
					SendNetworkEvent(player,"object_spawner:AreaObject",id,index,area)
				end
				obj.area = area
				set.update = true
				F_SaveSets()
			end
		end
		SendNetworkEvent(player,"object_spawner:FinishWaiting")
	end
end)

function F_UpdatePlayerSets(player,di)
	local array = {}
	local sets = gDimensions[di]
	if sets then
		for id in pairs(sets) do
			table.insert(array,id)
		end
	end
	if array[1] then
		SendNetworkEvent(player,"object_spawner:SetActive",array)
	else
		SendNetworkEvent(player,"object_spawner:SetActive")
	end
end

function F_CreateSet(player)
	return {
		update = true, -- stripped when saved
		active = false,
		description = "by "..GetPlayerName(player),
		objects = {},
		x = 0,
		y = 0,
		z = 0,
		h = 0,
	}
end
function F_CreateObject(v,x,y,z,h,area)
	return {
		name = v[4],
		type = v[2],
		model = v[3],
		dist = 55*55, -- squared distance
		priority = 0,
		vulnerable = true,
		flags = {[11] = true},
		area = area,
		px = x, -- position
		py = y,
		pz = z,
		rx = 0, -- rotation
		ry = 0,
		rz = h,
		order = 0,
		sx = 1, -- scale
		sy = 1,
		sz = 1,
	}
end

function F_SaveSets()
	local sorted = {}
	local sets = {}
	for id,set in pairs(gSets) do
		table.insert(sorted,{id,set})
	end
	table.sort(sorted,function(a,b)
		return string.lower(a[1]) < string.lower(b[1])
	end)
	for _,kv in ipairs(sorted) do
		local copy = {}
		for k,v in pairs(kv[2]) do
			if k ~= "update" then
				copy[k] = v
			end
		end
		sets[kv[1]] = copy
	end
	if not pcall(SaveTable,"objects.bin",sets) then
		for player,data in pairs(gPlayers) do
			if data.allow then
				SendNetworkEvent(player,"object_spawner:SaveFailed")
			end
		end
		PrintWarning("failed to save objects.bin")
	end
end
function F_CopyValue(src)
	if type(src) == "table" then
		local dest = {}
		for k,v in pairs(src) do
			dest[k] = F_CopyValue(v)
		end
		return dest
	end
	return src
end
function F_IsOkaySetId(id)
	return not string.find(id,"[^%w_]")
end
function F_CheckPermissions(player)
	for ip in AllConfigStrings(GetScriptConfig(),"allow_ip") do
		if GetPlayerIp(player) == ip then
			return true
		end
	end
	for role in AllConfigStrings(GetScriptConfig(),"allow_role") do
		if DoesPlayerHaveRole(player,role) then
			return true
		end
	end
	return false
end
function F_GetObject(model)
	for _,v in ipairs(gObjects) do
		if v[3] == model then
			return v
		end
	end
end
function F_GetOffset(set,wx,wy,wz)
	local sx,sy,sz,sh = set.x,set.y,set.z,set.h
	local dx,dy,dz = (TransposeMatrix(Rz(sh))*vec3(wx-sx,wy-sy,wz-sz)):unpack()
	return dx,dy,dz
end
function F_GetRotation(set,wp,wr,wh,order)
	return GetMatrixRotation(TransposeMatrix(Rz(set.h))*RotationMatrix(wp,wr,wh,order),order)
end

function F_ActivateDefaults()
	local sets = {}
	for id,set in pairs(gSets) do
		if set.active then
			sets[id] = true
		end
	end
	if next(sets) then
		gDimensions[GetSyncMainDimension()] = sets
	end
end
F_ActivateDefaults()

function F_UpdateObjects()
	local sample = F_CreateObject(gObjects[1],0,0,0,0,0)
	for _,set in pairs(gSets) do
		for _,obj in ipairs(set.objects) do
			for k in pairs(obj) do
				if sample[k] == nil then
					obj[k] = nil -- remove old fields
					set.update = true
				end
			end
			for k,v in pairs(sample) do
				if type(obj[k]) ~= type(v) then
					obj[k] = F_CopyValue(v) -- default new fields
					set.update = true
				end
			end
			for f in pairs(obj.flags) do
				if sample.flags[f] == nil then
					obj.flags[f] = nil -- remove old flags
					set.update = true
				end
			end
			for f,v in pairs(sample.flags) do
				if type(obj.flags[f]) ~= type(v) then
					obj.flags[f] = v -- default new flags
					set.update = true
				end
			end
		end
	end
end
F_UpdateObjects()
