-- SYNC+ | stat configuration | Xx_Yubari_xX
--  this file is used by sv_stats.lua and cl_stats.lua

-- each stat can be listed in either gStatRange or gStatWhitelist
-- if in gStatRange, the value must be within the inclusive range to be valid
-- if in gStatWhitelist, the value must return true when used as a key to be valid

-- most limits are arbitrary to keep on the safe side of things
-- values are adjusted if needed before being sent to the server

local missions = {[65535] = true} -- used to signal when a weapon is available
local weapons = {} -- used for pickups and weapons
local pickups = {}
for _,w in ipairs({
	299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 
	311, 312, 313, 314, 315, 316, 317, 318, 320, 321, 322, 323, 
	324, 325, 326, 327, 328, 329, 330, 331, 332, 335, 336, 337, 
	338, 339, 341, 342, 343, 345, 346, 348, 349, 350, 351, 352, 
	353, 354, 355, 356, 357, 358, 359, 360, 363, 364, 372, 377, 
	378, 381, 383, 384, 385, 387, 388, 389, 390, 391, 394, 395, 
	396, 397, 399, 400, 401, 402, 403, 404, 405, 409, 410, 411, 
	412, 413, 414, 415, 416, 417, 418, 420, 422, 425, 426, 432, 
	433, 435, 437, 65535
}) do
	weapons[w] = true
	pickups[w] = true
end
pickups[362] = true

gStatRange = {
	[1] = {0,100}, -- Likelihood (n/100) of dropping an item
	[2] = {0,360}, -- Vision Yaw (in degrees) - note this is total yaw and not angle from facing direction (which is this value / 2)
	[3] = {0,65534}, -- Vision Range (in metres)
	[5] = {0,65534}, -- Health regeneration rate - percentage of maximum rate (n/100)
	[6] = {0,100}, -- Fear (n/100)
	[7] = {0,100}, -- Chicken (n/100) (chance of tattling/ yelling for help)
	[8] = {0,100}, -- Attack Frequency (n/100)
	[9] = {0,100}, -- Bike Attack Frequency (n/100)
	[10] = {0,100}, -- Projectile Attack Accuracy (n/100)
	[11] = {0,100}, -- Projectile Attack Frequency (n/100)
	[12] = {0,100}, -- Block Frequency (n/100) 
	[13] = {0,100}, -- Evade Frequency (n/100)
	[14] = {0,100}, -- "Aggresion (n/100) (how likely are they to initiate a fight, and how likely they are to contnue it)"
	[15] = {0,100}, -- Criminality
	[16] = {0,65534}, -- Sprint Meter
	[17] = {0,4}, -- Character Class
	[18] = {0,2}, -- Preferred Combat Zone (0/1/2 = short/medium/long)
	[19] = {0,7}, -- "Preferred Orientation (Bit field: 0001 front, 0010 side, 0100 back. So front+side = 011 = 3, and 111 = 7)"
	[20] = {0,65534}, -- Animation Speed factor (100 = 100% speed)
	[21] = {0,1}, -- Zone Promote
	[22] = {0,65534}, -- Special Meter
	[23] = {0,65534}, -- Special Points
	[24] = {0,65534}, -- Bike Cruise Speed
	[25] = {0,65534}, -- Bike Top Speed
	[26] = {0,65534}, -- Bike Wait Speed
	[27] = {0,65534}, -- Bike Flee Distance
	[28] = {0,65534}, -- Bike Catchup Distance
	[29] = {0,65534}, -- Bike Wait Distance
	[30] = {0,100}, -- Bike Projectile Usage (n/100)
	[31] = {0,65534}, -- Damage_Scale
	[32] = {0,100}, -- Dive probability
	[33] = {0,100}, -- "Tenacity (n/100), indicates how tough they are to knock down or off a bike"
	[34] = {0,100}, -- Evasion (n/100)
	[35] = {0,65534}, -- Bike Flee Speed
	[36] = {0,65534}, -- Bike Follow Speed
	[37] = {0,65534}, -- Bike Catchup Speed
	[38] = {0,100}, -- Grap1Reversal (Strikes)
	[39] = {0,100}, -- Grap2Reversal (Grapples)
	[41] = {272,298}, -- "Name of the bike model which the ped can ride (""""None"""" if the ped can't ride any bike)"
	[42] = {272,298}, -- "Name of the bike model which the ped can ride (""""None"""" if the ped can't ride any bike)"
	[43] = {272,298}, -- "Name of the bike model which the ped can ride (""""None"""" if the ped can't ride any bike)"
	[44] = {0,100}, -- Likelihood (n/100) of having a weapon
	[46] = {0,100}, -- Weapon slot 1: Amount of Ammo
	[47] = {0,65534}, -- Weapon slot 1: Selection weight for melee/projectile weapon - HIGHEST NUMBER WINS
	[50] = {0,100}, -- Weapon slot 2: Amount of Ammo
	[51] = {0,65534}, -- Weapon slot 2: Selection weight for melee/projectile weapon
	[54] = {0,100}, -- Weapon slot 3: Amount of Ammo
	[55] = {0,65534}, -- Weapon slot 3: Selection weight for melee/projectile weapon
	[58] = {0,100}, -- Weapon slot 4: Amount of Ammo
	[59] = {0,65534}, -- Weapon slot 4: Selection weight for melee/projectile weapon
	[61] = {0,100}, -- Stun Resistance (n/100) how resistant a ped is to stunning
	[62] = {0,1}, -- "Ped can be knocked down (0 = no, 1+ = yes)"
	[63] = {0,65534}, -- health at which the ped can be humiliated in combat
}
gStatWhitelist = {
	[0] = pickups, -- Id of pickup def (c. Pickups.dat)
	[40] = weapons, -- Night weapon
	[45] = weapons, -- Weapon slot 1: Type of melee/projectile
	[48] = missions, -- "Weapon slot 1: Available after mission (use ""init"" to signify start of game)"
	[49] = weapons, -- Weapon slot 2: Type of melee/projectile
	[52] = missions, -- "Weapon slot 2: Available after mission (use ""init"" to signify start of game)"
	[53] = weapons, -- Weapon slot 3: Type of melee/projectile
	[56] = missions, -- "Weapon slot 3: Available after mission (use ""init"" to signify start of game)"
	[57] = weapons, -- Weapon slot 4: Type of melee/projectile
	[60] = missions, -- "Weapon slot 4: Available after mission (use ""init"" to signify start of game)"
}
