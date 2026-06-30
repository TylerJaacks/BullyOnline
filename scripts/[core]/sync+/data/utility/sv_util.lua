-- SYNC+ | server utility | Xx_Yubari_xX
--  provides utility functions for other sync+ server scripts

local st = GetScriptSharedTable()

-- Shared Tables
st.attitude = LoadTable("data/attitude.bin") -- {[faction] = {[faction] = attitude}}
st.colors = LoadTable("data/colors.bin") -- {[vehicle_model] = {color_a, color_b}}
st.factions = LoadTable("data/factions.bin") -- {[ped_model] = faction}
st.speech = LoadTable("data/speech.bin") -- array of all speech events as hashed userdata in order, without NUM_SPEECH_EVENTS
st.stats = LoadTable("data/stats.bin") -- {[ped_model] = stat_name, [stat_name] = {[stat] = value}}

-- Utility Functions
function st.array_finite(value,count)
	local check = 0
	if type(value) ~= "table" or value.n ~= nil then
		return false -- should be a table without an "n"
	end
	for _,v in pairs(value) do
		if not st.finite(v) or check >= count then
			return false -- should be a certain amount of finite numbers
		end
		check = check + 1
	end
	return table.getn(value) == count -- shouldn't have other fields
end
function st.finite(value)
	-- not NaN and not either infinity
	return type(value) == "number" and value > (-1 / 0) and value < (1 / 0)
end
