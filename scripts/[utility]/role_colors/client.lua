LoadScript("colors.lua")

function exports.GetColorFromIndex(index)
	local v = gRoles[index]
	if v then
		return v[2],v[3],v[4]
	end
	return unpack(gDefaultRole)
end
