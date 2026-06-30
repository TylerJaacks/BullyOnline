LoadScript("colors.lua")

function exports.GetColor(player)
	if not IsPlayerValid(player,false) then
		argerror(1,"invalid player")
	end
	for _,v in ipairs(gRoles) do
		if DoesPlayerHaveRole(player,v[1]) then
			return v[2],v[3],v[4]
		end
	end
	return unpack(gDefaultRole)
end
function exports.GetColorIndex(player)
	if not IsPlayerValid(player,false) then
		argerror(1,"invalid player")
	end
	for i,v in ipairs(gRoles) do
		if DoesPlayerHaveRole(player,v[1]) then
			return i
		end
	end
	return 0
end
function exports.GetColorFromIndex(index)
	local v = gRoles[index]
	if v then
		return v[2],v[3],v[4]
	end
	return unpack(gDefaultRole)
end
