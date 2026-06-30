LoadScript("offsets.lua")

gPlayers = {}
gUpdated = false

-- offset updating
RegisterLocalEventHandler("PlayerDropped",function(player)
	gPlayers[player] = nil
end)
RegisterNetworkEventHandler("first_person:RequestOffset",function(player)
	if DoesPlayerHaveRole(player,"admin") then
		SendNetworkEvent(player,"first_person:AllowOffset")
		gPlayers[player] = true
	else
		gPlayers[player] = false
	end
	if gUpdated then
		SendNetworkEvent(player,"first_person:UpdateOffsets",gOffsets,gRotations)
	end
end)
RegisterNetworkEventHandler("first_person:AdjustOffset",function(player,key,seat,x,y,z)
	if gPlayers[player] then
		F_GetOffsets(key)[seat] = {x,y,z}
		F_UpdateOffsets()
	end
end)
RegisterNetworkEventHandler("first_person:MirrorOffsets",function(player,key)
	if gPlayers[player] then
		local offsets = F_GetOffsets(key)
		local fl,bl = offsets[0],offsets[3]
		offsets[1] = {-fl[1],fl[2],fl[3]}
		offsets[2] = {-bl[1],bl[2],bl[3]}
		F_UpdateOffsets()
	end
end)
RegisterNetworkEventHandler("first_person:AdjustRotation",function(player,key,seat,p,r,h,o)
	if gPlayers[player] then
		F_GetRotations(key)[seat] = {p,r,h,o}
		F_UpdateOffsets()
	end
end)
RegisterNetworkEventHandler("first_person:NoteOffset",function(player,key,note)
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
			rotation[i] = {0,0,0,2}
		end
		gRotations[key] = rotation
	end
	return rotation
end
function F_UpdateOffsets()
	F_SaveOffsets()
	for player in pairs(gPlayers) do
		SendNetworkEvent(player,"first_person:UpdateOffsets",gOffsets,gRotations)
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
			local p,r,h,o = unpack(kv[2][i])
			WriteFile(output,string.format("\t\t[%d] = {math.rad(%.1f), math.rad(%.1f), math.rad(%.1f), %d},\r\n",i,math.deg(p),math.deg(r),math.deg(h),o))
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
