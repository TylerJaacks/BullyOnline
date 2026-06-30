LoadScript("offsets.lua")

gPlayers = {}
gUpdated = false

-- offset updating
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterNetworkEventHandler("fakecars:RequestOffset",function(player)
	if DoesPlayerHaveRole(player,"admin") then
		SendNetworkEvent(player,"fakecars:AllowOffset")
		gPlayers[player] = true
	else
		gPlayers[player] = false
	end
	if gUpdated then
		SendNetworkEvent(player,"fakecars:UpdateOffsets",gOffsets,gRotations,gActions)
	end
end)
RegisterNetworkEventHandler("fakecars:AdjustOffset",function(player,key,seat,x,y,z)
	if gPlayers[player] then
		F_GetOffsets(key)[seat] = {x,y,z}
		F_UpdateOffsets()
	end
end)
RegisterNetworkEventHandler("fakecars:MirrorOffsets",function(player,key)
	if gPlayers[player] then
		local offsets = F_GetOffsets(key)
		local fl,bl = offsets[0],offsets[3]
		offsets[1] = {-fl[1],fl[2],fl[3]}
		offsets[2] = {-bl[1],bl[2],bl[3]}
		F_UpdateOffsets()
	end
end)
RegisterNetworkEventHandler("fakecars:AdjustRotation",function(player,key,seat,p,r,h)
	if gPlayers[player] then
		F_GetRotations(key)[seat] = {p,r,h}
		F_UpdateOffsets()
	end
end)
RegisterNetworkEventHandler("fakecars:AdjustAction",function(player,key,seat,node,file)
	if gPlayers[player] then
		F_GetActions(key)[seat] = {node,file}
		F_UpdateOffsets()
	end
end)
RegisterNetworkEventHandler("fakecars:NoteOffset",function(player,key,note)
	if gPlayers[player] then
		F_GetOffsets(key).note = note
		F_UpdateOffsets()
	end
end)

-- offset utility
function F_GetOffsets(key)
	local offsets = gOffsets[key]
	if not offsets then
		offsets = {}
		for i = 0,3 do
			offsets[i] = {0,0,0}
		end
		gOffsets[key] = offsets
	end
	return offsets
end
function F_GetRotations(key)
	local rotation = gRotations[key]
	if not rotation then
		rotation = {}
		for i = 0,3 do
			rotation[i] = {0,0,0}
		end
		gRotations[key] = rotation
	end
	return rotation
end
function F_GetActions(key)
	local actions = gActions[key]
	if not actions then
		actions = {[0]={"/GLOBAL/VEHICLES/CARS/VEHICLES_CARRIDE/RIDE/SEDAN/DRIVER",""}}
		for i = 1,3 do
			actions[i] = {"/GLOBAL/VEHICLES/CARS/VEHICLES_CARRIDE/RIDE/SEDAN/PASSENGER/PASSENGERIDLE",""}
		end
		gActions[key] = actions
	end
	return actions
end
function F_UpdateOffsets()
	F_SaveOffsets()
	for player in pairs(gPlayers) do
		SendNetworkEvent(player,"fakecars:UpdateOffsets",gOffsets,gRotations,gActions)
	end
	gUpdated = true
end

-- offset saving
function F_SaveOffsets()
	local output = OpenFile("offsets.lua","wb")
	local offsets = {}
	for k,v in pairs(gOffsets) do
		table.insert(offsets,{k,v})
	end
	table.sort(offsets,F_SortOffsets)
	WriteFile(output,"gOffsets = {\r\n")
	for _,kv in ipairs(offsets) do
		WriteFile(output,"\t"..F_GetKey(kv[1]).." = {\r\n")
		if kv[2].note then
			WriteFile(output,"\t\tnote = \""..string.gsub(kv[2].note,"\"","\\\"").."\",\r\n")
		end
		for i = 0,3 do
			WriteFile(output,string.format("\t\t[%d] = {%.3f, %.3f, %.3f},\r\n",i,unpack(kv[2][i])))
		end
		WriteFile(output,"\t},\r\n")
	end
	WriteFile(output,"}\r\n")
	offsets = {}
	for k,v in pairs(gRotations) do
		table.insert(offsets,{k,v})
	end
	table.sort(offsets,F_SortOffsets)
	WriteFile(output,"gRotations = {\r\n")
	for _,kv in ipairs(offsets) do
		WriteFile(output,"\t"..F_GetKey(kv[1]).." = {\r\n")
		for i = 0,3 do
			local p,r,h = unpack(kv[2][i])
			WriteFile(output,string.format("\t\t[%d] = {math.rad(%.1f), math.rad(%.1f), math.rad(%.1f)},\r\n",i,math.deg(p),math.deg(r),math.deg(h)))
		end
		WriteFile(output,"\t},\r\n")
	end
	WriteFile(output,"}\r\n")
	offsets = {}
	for k,v in pairs(gActions) do
		table.insert(offsets,{k,v})
	end
	table.sort(offsets,F_SortOffsets)
	WriteFile(output,"gActions = {\r\n")
	for _,kv in ipairs(offsets) do
		WriteFile(output,"\t"..F_GetKey(kv[1]).." = {\r\n")
		for i = 0,3 do
			WriteFile(output,string.format("\t\t[%d] = {\"%s\", \"%s\"},\r\n",i,unpack(kv[2][i])))
		end
		WriteFile(output,"\t},\r\n")
	end
	WriteFile(output,"}\r\n")
	CloseFile(output)
end
function F_SortOffsets(a,b)
	a,b = a[1],b[1]
	if type(a) ~= type(b) then
		return type(a) == "number" -- can only be number or string, and numbers should go first
	elseif type(a) == "number" then
		return a < b -- sort numbers in order
	end
	return string.lower(a) < string.lower(b) -- and strings in case-insensitive order
end
function F_GetKey(key)
	if type(key) == "number" then
		return "["..key.."]"
	elseif string.find(key,"[^%w_]") or string.find(key,"^%d") then
		return "[\""..key.."\"]"
	end
	return key
end
