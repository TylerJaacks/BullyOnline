-- SYNC+ | entity keys | Xx_Yubari_xX
--  optimizes network usage by using hashes for sync entity keys

-- using hashes (light udata) means we only use 4 bytes per key
-- if we used strings, it would be 4 bytes + string length (over double on average)

-- key function
local hashes = {}
local function key(str)
	local hash = ObjectNameToHashID(str)
	if hashes[hash] then
		PrintWarning("hash collision: \""..hashes[hash].."\" and \""..str.."\"")
	end
	hashes[hash] = str
	return hash
end

-- ped keys
KEY_ACT_COUNT = key("ACT_COUNT")
KEY_ACT_NODE = key("ACT_NODE")
KEY_ACT_TIMER = key("ACT_TIMER")
KEY_ACT_TREE = key("ACT_TREE")
KEY_AI_ARG = key("AI_ARG")
KEY_AI_TARGET = key("AI_TARGET")
KEY_AI_TASK = key("AI_TASK")
KEY_AI_TREE = key("AI_TREE")
KEY_AI_VALID = key("AI_VALID")
KEY_AI_XYZ = key("AI_XYZ")
KEY_AMMO = key("AMMO")
KEY_ANCHOR = key("ANCHOR")
KEY_ATTITUDES = {}
for f = 0,13 do
	if f ~= 12 then -- don't track faction 12 (the game's global attitude array is only 13 ints so it must not include DEFAULT)
		KEY_ATTITUDES[f] = key("ATTITUDE_"..f)
	end
end
KEY_DAMAGE_GIVEN = key("DAMAGE_GIVEN")
KEY_DAMAGE_TAKEN = key("DAMAGE_TAKEN")
KEY_DEAD = key("DEAD")
KEY_DIRECTION = key("DIRECTION")
KEY_EMOTIONS = key("EMOTION")
KEY_FLAGS = key("FLAGS")
KEY_GRAVITY = key("GRAVITY")
KEY_HP = key("HP")
KEY_INVULNERABLE = key("INVULNERABLE")
KEY_MAXHP = key("MAXHP")
KEY_PUNISHMENT = key("PUNISHMENT")
KEY_SPEECH = key("SPEECH")
KEY_SPEECH_COUNT = key("SPEECH_COUNT")
KEY_SPEECH_RSM = key("SPEECH_RSM")
KEY_SPRINT = key("SPRINT")
KEY_STAMINA = key("STAMINA")
KEY_STATS = {}
for s = 0,63 do
	if s ~= 4 then -- use STAT_MAXHP instead
		KEY_STATS[s] = key("STAT_"..s)
	end
end
KEY_TARGET = key("TARGET")
KEY_TARGET_GRAPPLE = key("TARGET_GRAPPLE")
KEY_TARGET_VEHICLE = key("TARGET_VEHICLE")
KEY_THROTTLE = key("THROTTLE")
KEY_WEAPON = key("WEAPON")

-- vehicle keys
KEY_COLOR_A = key("COLOR_A")
KEY_COLOR_B = key("COLOR_B")
KEY_ENGINE = key("ENGINE")
KEY_SIREN = key("SIREN")
