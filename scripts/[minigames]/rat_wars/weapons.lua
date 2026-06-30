DEBUG_TRANSPARENT_WEAPON = false -- see through gun to see projectile spawns easier
DEBUG_UP_RECOIL = false -- always offset 100% upwards to test jumping off screen
DEBUG_NO_RECOIL = false -- disable recoil to test ballistics

gWeapons = {}

-- (MODELED) g17: 17+1 round 9mm semi auto pistol, 30 damage (4 shots)
gWeapons.g17 = {
	-- info --
	name = "Pistol",
	secondary = true,
	-- visual --
	icon_index = 1,
	icon_scale = 1,
	texture_name = "g17.png",
	texture_decock = false,
	scope_size = 0, -- set to 0 to disable scope
	hip_size = 0.575, -- directly sets height, width determined automatically
	hip_offset = 0.22, -- horizontal offset
	aim_size = 0.585,
	aim_offset = 0.0018,
	dot_color = {0,0,0},
	dot_size = 0,
	-- flash --
	flash_effects = {"SpudGunSecondary"},
	flash_offset = {0,0.5,0.065},
	flash_pitch = 0,
	flash_heading = 0,
	-- scope --
	scope_fov = 0.9, -- also affects aim in general
	scope_stages = 1,
	scope_maximum = 0,
	scope_minimum = 0,
	-- sounds --
	sound_distance = 0.26, -- lower values make sounds seem to have more range
	sound_duplicate = 1, -- how many times all sounds are played
	sound_names = {"BTL_RKT_EXP_NR","DunkSeat"},
	sound_banks = {"Btlrokt.bnk","DnkTnk.bnk"},
	-- assist --
	assist_on_kb = false,
	assist_range = 10, -- also used to scale the assist speed
	assist_angle = 10,
	assist_fast = 0.12, -- minimum amount of seconds to snap to target
	assist_slow = 0.43, -- maximum amount of seconds to snap to target
	-- handling --
	reload_ms = 500,
	rechamber_ms = 200,
	equip_ms = 150,
	unequip_ms = 100,
	aim_in_ms = 175,
	aim_out_ms = 125,
	can_aim = true,
	-- recoil --
	recoil_push_ms = 115, -- duration for camera push (kick) effect
	recoil_push_amount = 32, -- max degrees per second over duration
	recoil_push_ratio = 0.42, -- max angle ratio (1 is 360 degrees, 0 is none)
	recoil_push_base = 0, -- base angle for kicking (counter clockwise)
	recoil_push_hip = 1.97, -- hip fire multiplier for push
	recoil_time_ms = 95, -- duration for fov and offset effects
	recoil_fov = 1.02, -- how much recoil scales fov
	recoil_scale = 1.27, -- how much recoil scales the gun
	recoil_offset = 0.16, -- kick to the side when scaling
	recoil_upwards = true, -- don't let recoil_offset kick downwards
	recoil_spread = 12, -- amount of projectile spread from offset kick
	recoil_ratio = 0.7, -- horizontal scale for recoil_offset
	recoil_ads = 1, -- recoil reduction when aiming
	-- action --
	magazine_size = 17,
	fire_delay = 60,
	bolt_action = false, -- don't automatically chamber next round
	open_bolt = false, -- don't use the chamber, just magazine
	full_auto = false, -- allow trigger to be held
	-- ballistics --
	projectile_id = 304,
	projectile_power = 1.4,
	projectile_damage = 30,
	spawn_dist_base = 0.3, -- distance in front of player
	spawn_dist_pitch = 0.2, -- distance increase when looking up
	shoot_hip_height = -0.08, -- y offset for barrel from hip
	shoot_hip_offset = 0.16, -- x offset for barrel from hip
	shoot_hip_pitch = 0.27, -- pitch added to direction from hip
	shoot_hip_heading = 0.31, -- heading added to direction from hip
	shoot_aim_height = -0.04, -- height for aiming
	shoot_aim_pitch = 0.45, -- pitch for aiming
}

-- (MODELED) m249: 30 round 5.56x45mm full auto assault rifle, 40 damage (3 shots)
gWeapons.m249 = {
	-- info --
	name = "Machine Gun",
	secondary = false,
	-- visual --
	icon_index = 3,
	icon_scale = 1,
	texture_name = "m249.png",
	texture_decock = false,
	scope_size = 0, -- set to 0 to disable scope
	hip_size = 0.6, -- directly sets height, width determined automatically
	hip_offset = 0.35, -- horizontal offset
	aim_size = 0.649,
	aim_offset = -0.0026,
	dot_color = {0,0,0},
	dot_size = 0,
	-- flash --
	flash_effects = {"SpudGunSecondary"},
	flash_offset = {0,0.5,0.065},
	flash_pitch = 0,
	flash_heading = 0,
	-- scope --
	scope_fov = 0.7, -- also affects aim in general
	scope_stages = 1,
	scope_maximum = 0,
	scope_minimum = 0,
	-- sounds --
	sound_distance = 0.15, -- lower values make sounds seem to have more range
	sound_duplicate = 1, -- how many times all sounds are played
	sound_names = {"CHRY_EXP_NR","x_sleigh_hit","CartDmge"},
	sound_banks = {"Chrybmb2.bnk","XmasObj.bnk","GoKart01.bnk"},
	-- assist --
	assist_on_kb = false,
	assist_range = 15, -- also used to scale the assist speed
	assist_angle = 10,
	assist_fast = 0.15, -- minimum amount of seconds to snap to target
	assist_slow = 0.45, -- maximum amount of seconds to snap to target
	-- handling --
	reload_ms = 600,
	rechamber_ms = 200,
	equip_ms = 550,
	unequip_ms = 200,
	aim_in_ms = 375,
	aim_out_ms = 275,
	can_aim = true,
	-- recoil --
	recoil_push_ms = 120, -- duration for camera push (kick) effect
	recoil_push_amount = 24, -- max degrees per second over duration
	recoil_push_ratio = 0.45, -- max angle ratio (1 is 360 degrees, 0 is none)
	recoil_push_base = -15, -- base angle for kicking (counter clockwise)
	recoil_push_hip = 1.8, -- hip fire multiplier for push
	recoil_time_ms = 130, -- duration for fov and offset effects
	recoil_fov = 1.04, -- how much recoil scales fov
	recoil_scale = 1.35, -- how much recoil scales the gun
	recoil_offset = 0.11, -- kick to the side when scaling
	recoil_upwards = true, -- don't let recoil_offset kick downwards
	recoil_spread = 12, -- amount of projectile spread from offset kick
	recoil_ratio = 0.8, -- horizontal scale for recoil_offset
	recoil_ads = 1, -- recoil reduction when aiming
	-- action --
	magazine_size = 30,
	fire_delay = 70,
	bolt_action = false, -- don't automatically chamber next round
	open_bolt = true, -- don't use the chamber, just magazine
	full_auto = true, -- allow trigger to be held
	-- ballistics --
	projectile_id = 322,
	projectile_power = 1.6,
	projectile_damage = 40,
	spawn_dist_base = 0.3, -- distance in front of player
	spawn_dist_pitch = 0.2, -- distance increase when looking up
	shoot_hip_height = -0.12, -- y offset for barrel from hip
	shoot_hip_offset = 0.12, -- x offset for barrel from hip
	shoot_hip_pitch = 0.39, -- pitch added to direction from hip
	shoot_hip_heading = 1.2, -- heading added to direction from hip
	shoot_aim_height = -0.085, -- height for aiming
	shoot_aim_pitch = 0.45, -- pitch for aiming
}

-- (MODELED) awm: 5+1 round .338 lapua magnum bolt action sniper rifle, 100 damage (1 shot)
gWeapons.awm = {
	-- info --
	name = "Sniper Rifle",
	secondary = false,
	-- visual --
	icon_index = 4,
	icon_scale = 1,
	texture_name = "awm.png",
	texture_decock = false,
	scope_size = 0.23, -- set to 0 to disable scope
	hip_size = 0.6, -- directly sets height, width determined automatically
	hip_offset = 0.31, -- horizontal offset
	aim_size = 0.694,
	aim_offset = 0.049,
	dot_color = {255,0,0},
	dot_size = 0.002,
	-- flash --
	flash_effects = {"SpudGunSecondary"},
	flash_offset = {0,0.5,0.065},
	flash_pitch = 0,
	flash_heading = 0,
	-- scope --
	scope_fov = 0.55, -- also affects aim in general
	scope_stages = 10,
	scope_maximum = 3,
	scope_minimum = 1.5,
	-- sounds --
	sound_distance = 0.08, -- lower values make sounds seem to have more range
	sound_duplicate = 3, -- how many times all sounds are played
	sound_names = {"BTL_RKT_EXP_NR","MedExplode"},
	sound_banks = {"Btlrokt.bnk","ArtClass.bnk"},
	-- assist --
	assist_on_kb = false,
	assist_range = 35, -- also used to scale the assist speed
	assist_angle = 10,
	assist_fast = 0.15, -- minimum amount of seconds to snap to target
	assist_slow = 0.35, -- maximum amount of seconds to snap to target
	-- handling --
	reload_ms = 850,
	rechamber_ms = 200,
	equip_ms = 500,
	unequip_ms = 200,
	aim_in_ms = 375,
	aim_out_ms = 250,
	can_aim = true,
	-- recoil --
	recoil_push_ms = 250, -- duration for camera push (kick) effect
	recoil_push_amount = 21, -- max degrees per second over duration
	recoil_push_ratio = 0.2, -- max angle ratio (1 is 360 degrees, 0 is none)
	recoil_push_base = 0, -- base angle for kicking (counter clockwise)
	recoil_push_hip = 2.1, -- hip fire multiplier for push
	recoil_time_ms = 475, -- duration for fov and offset effects
	recoil_fov = 1.05, -- how much recoil scales fov
	recoil_scale = 1.4, -- how much recoil scales the gun
	recoil_offset = 0.12, -- kick to the side when scaling
	recoil_upwards = true, -- don't let recoil_offset kick downwards
	recoil_spread = 15, -- amount of projectile spread from offset kick
	recoil_ratio = 0.7, -- horizontal scale for recoil_offset
	recoil_ads = 1, -- recoil reduction when aiming
	-- action --
	magazine_size = 5,
	fire_delay = 100,
	bolt_action = true, -- don't automatically chamber next round
	open_bolt = false, -- don't use the chamber, just magazine
	full_auto = false, -- allow trigger to be held
	-- ballistics --
	projectile_id = 304,
	projectile_power = 3.5,
	projectile_damage = 150,
	spawn_dist_base = 0.3, -- distance in front of player
	spawn_dist_pitch = 0.2, -- distance increase when looking up
	shoot_hip_height = -0.1, -- y offset for barrel from hip
	shoot_hip_offset = 0.15, -- x offset for barrel from hip
	shoot_hip_pitch = 0.27, -- pitch added to direction from hip
	shoot_hip_heading = -1, -- heading added to direction from hip
	shoot_aim_height = -0.1, -- height for aiming
	shoot_aim_pitch = 0.51, -- pitch for aiming
}

-- (REALISTIC) 92fs: 15+1 round 9mm semi auto pistol, 30 damage (4 shots)
gWeapons["92fs"] = {
	-- info --
	name = "9mm Pistol",
	secondary = true,
	-- visual --
	icon_index = 5,
	icon_scale = 1,
	texture_name = "92fs.png",
	texture_decock = true,
	scope_size = 0, -- set to 0 to disable scope
	hip_size = 0.575, -- directly sets height, width determined automatically
	hip_offset = 0.22, -- horizontal offset
	aim_size = 0.585,
	aim_offset = 0.0018,
	dot_color = {0,0,0},
	dot_size = 0,
	-- flash --
	flash_effects = {"SpudGunSecondary"},
	flash_offset = {0,0.5,0.065},
	flash_pitch = 0,
	flash_heading = 0,
	-- scope --
	scope_fov = 0.9, -- also affects aim in general
	scope_stages = 1,
	scope_maximum = 0,
	scope_minimum = 0,
	-- sounds --
	sound_distance = 0.26, -- lower values make sounds seem to have more range
	sound_duplicate = 1, -- how many times all sounds are played
	sound_names = {"BTL_RKT_EXP_NR","DunkSeat"},
	sound_banks = {"Btlrokt.bnk","DnkTnk.bnk"},
	-- assist --
	assist_on_kb = false,
	assist_range = 10, -- also used to scale the assist speed
	assist_angle = 15,
	assist_fast = 0.09, -- minimum amount of seconds to snap to target
	assist_slow = 0.41, -- maximum amount of seconds to snap to target
	-- handling --
	reload_ms = 500,
	rechamber_ms = 200,
	equip_ms = 150,
	unequip_ms = 100,
	aim_in_ms = 175,
	aim_out_ms = 125,
	can_aim = true,
	-- recoil --
	recoil_push_ms = 115, -- duration for camera push (kick) effect
	recoil_push_amount = 29, -- max degrees per second over duration
	recoil_push_ratio = 0.39, -- max angle ratio (1 is 360 degrees, 0 is none)
	recoil_push_base = 0, -- base angle for kicking (counter clockwise)
	recoil_push_hip = 1.94, -- hip fire multiplier for push
	recoil_time_ms = 95, -- duration for fov and offset effects
	recoil_fov = 1.02, -- how much recoil scales fov
	recoil_scale = 1.27, -- how much recoil scales the gun
	recoil_offset = 0.14, -- kick to the side when scaling
	recoil_upwards = true, -- don't let recoil_offset kick downwards
	recoil_spread = 12, -- amount of projectile spread from offset kick
	recoil_ratio = 0.7, -- horizontal scale for recoil_offset
	recoil_ads = 1, -- recoil reduction when aiming
	-- action --
	magazine_size = 15,
	fire_delay = 60,
	bolt_action = false, -- don't automatically chamber next round
	open_bolt = false, -- don't use the chamber, just magazine
	full_auto = false, -- allow trigger to be held
	-- ballistics --
	projectile_id = 304,
	projectile_power = 1.4,
	projectile_damage = 30,
	spawn_dist_base = 0.3, -- distance in front of player
	spawn_dist_pitch = 0.2, -- distance increase when looking up
	shoot_hip_height = -0.08, -- y offset for barrel from hip
	shoot_hip_offset = 0.16, -- x offset for barrel from hip
	shoot_hip_pitch = 0.27, -- pitch added to direction from hip
	shoot_hip_heading = 0.31, -- heading added to direction from hip
	shoot_aim_height = -0.04, -- height for aiming
	shoot_aim_pitch = 0.45, -- pitch for aiming
}

-- (REALISTIC) c39v2: 30+1 round 7.62x39mm full auto assault rifle, 40 damage (3 shots)
gWeapons.c39v2 = {
	-- info --
	name = "AK-47",
	secondary = false,
	-- visual --
	icon_index = 6,
	icon_scale = 1.1667,
	texture_name = "c39v2.png",
	texture_decock = false,
	scope_size = 0, -- set to 0 to disable scope
	hip_size = 0.6, -- directly sets height, width determined automatically
	hip_offset = 0.35, -- horizontal offset
	aim_size = 0.649,
	aim_offset = -0.0026,
	dot_color = {0,0,0},
	dot_size = 0,
	-- flash --
	flash_effects = {"SpudGunSecondary"},
	flash_offset = {0,0.5,0.065},
	flash_pitch = 0,
	flash_heading = 0,
	-- scope --
	scope_fov = 0.7, -- also affects aim in general
	scope_stages = 1,
	scope_maximum = 0,
	scope_minimum = 0,
	-- sounds --
	sound_distance = 0.15, -- lower values make sounds seem to have more range
	sound_duplicate = 1, -- how many times all sounds are played
	sound_names = {"CHRY_EXP_NR","x_sleigh_hit","CartDmge"},
	sound_banks = {"Chrybmb2.bnk","XmasObj.bnk","GoKart01.bnk"},
	-- assist --
	assist_on_kb = false,
	assist_range = 15, -- also used to scale the assist speed
	assist_angle = 12,
	assist_fast = 0.11, -- minimum amount of seconds to snap to target
	assist_slow = 0.45, -- maximum amount of seconds to snap to target
	-- handling --
	reload_ms = 600,
	rechamber_ms = 200,
	equip_ms = 500,
	unequip_ms = 200,
	aim_in_ms = 325,
	aim_out_ms = 250,
	can_aim = true,
	-- recoil --
	recoil_push_ms = 120, -- duration for camera push (kick) effect
	recoil_push_amount = 26, -- max degrees per second over duration
	recoil_push_ratio = 0.45, -- max angle ratio (1 is 360 degrees, 0 is none)
	recoil_push_base = -25, -- base angle for kicking (counter clockwise)
	recoil_push_hip = 1.8, -- hip fire multiplier for push
	recoil_time_ms = 130, -- duration for fov and offset effects
	recoil_fov = 1.04, -- how much recoil scales fov
	recoil_scale = 1.4, -- how much recoil scales the gun
	recoil_offset = 0.12, -- kick to the side when scaling
	recoil_upwards = true, -- don't let recoil_offset kick downwards
	recoil_spread = 12, -- amount of projectile spread from offset kick
	recoil_ratio = 0.8, -- horizontal scale for recoil_offset
	recoil_ads = 0.85, -- recoil reduction when aiming
	-- action --
	magazine_size = 30,
	fire_delay = 70,
	bolt_action = false, -- don't automatically chamber next round
	open_bolt = false, -- don't use the chamber, just magazine
	full_auto = true, -- allow trigger to be held
	-- ballistics --
	projectile_id = 322,
	projectile_power = 1.6,
	projectile_damage = 40,
	spawn_dist_base = 0.3, -- distance in front of player
	spawn_dist_pitch = 0.2, -- distance increase when looking up
	shoot_hip_height = -0.12, -- y offset for barrel from hip
	shoot_hip_offset = 0.12, -- x offset for barrel from hip
	shoot_hip_pitch = 0.39, -- pitch added to direction from hip
	shoot_hip_heading = 1.2, -- heading added to direction from hip
	shoot_aim_height = -0.085, -- height for aiming
	shoot_aim_pitch = 0.45, -- pitch for aiming
}

-- (REALISTIC) patriot: 4+1 round .30-06 bolt action sniper rifle, 100 damage (1 shot)
gWeapons.patriot = {
	-- info --
	name = ".30-06 Sniper Rifle",
	secondary = false,
	-- visual --
	icon_index = 7,
	icon_scale = 1.1667,
	texture_name = "patriot.png",
	texture_decock = true,
	scope_size = 0.4, -- set to 0 to disable scope
	hip_size = 0.7, -- directly sets height, width determined automatically
	hip_offset = 0.32, -- horizontal offset
	aim_size = 0.76,
	aim_offset = 0.0208,
	dot_color = {255,0,0},
	dot_size = 0,
	-- flash --
	flash_effects = {"SpudGunSecondary"},
	flash_offset = {0,0.5,0.065},
	flash_pitch = 0,
	flash_heading = 0,
	-- scope --
	scope_fov = 0.55, -- also affects aim in general
	scope_stages = 10,
	scope_maximum = 3,
	scope_minimum = 1.5,
	-- sounds --
	sound_distance = 0.08, -- lower values make sounds seem to have more range
	sound_duplicate = 3, -- how many times all sounds are played
	sound_names = {"BTL_RKT_EXP_NR","MedExplode"},
	sound_banks = {"Btlrokt.bnk","ArtClass.bnk"},
	-- assist --
	assist_on_kb = false,
	assist_range = 25, -- also used to scale the assist speed
	assist_angle = 5,
	assist_fast = 0.12, -- minimum amount of seconds to snap to target
	assist_slow = 0.45, -- maximum amount of seconds to snap to target
	-- handling --
	reload_ms = 850,
	rechamber_ms = 200,
	equip_ms = 500,
	unequip_ms = 200,
	aim_in_ms = 375,
	aim_out_ms = 250,
	can_aim = true,
	-- recoil --
	recoil_push_ms = 250, -- duration for camera push (kick) effect
	recoil_push_amount = 21, -- max degrees per second over duration
	recoil_push_ratio = 0.2, -- max angle ratio (1 is 360 degrees, 0 is none)
	recoil_push_base = 0, -- base angle for kicking (counter clockwise)
	recoil_push_hip = 2.1, -- hip fire multiplier for push
	recoil_time_ms = 475, -- duration for fov and offset effects
	recoil_fov = 1.05, -- how much recoil scales fov
	recoil_scale = 1.4, -- how much recoil scales the gun
	recoil_offset = 0.12, -- kick to the side when scaling
	recoil_upwards = true, -- don't let recoil_offset kick downwards
	recoil_spread = 15, -- amount of projectile spread from offset kick
	recoil_ratio = 0.7, -- horizontal scale for recoil_offset
	recoil_ads = 1, -- recoil reduction when aiming
	-- action --
	magazine_size = 4,
	fire_delay = 100,
	bolt_action = true, -- don't automatically chamber next round
	open_bolt = false, -- don't use the chamber, just magazine
	full_auto = false, -- allow trigger to be held
	-- ballistics --
	projectile_id = 304,
	projectile_power = 3.5,
	projectile_damage = 150,
	spawn_dist_base = 0.3, -- distance in front of player
	spawn_dist_pitch = 0.2, -- distance increase when looking up
	shoot_hip_height = -0.11, -- y offset for barrel from hip
	shoot_hip_offset = 0.16, -- x offset for barrel from hip
	shoot_hip_pitch = 0.27, -- pitch added to direction from hip
	shoot_hip_heading = 0.72, -- heading added to direction from hip
	shoot_aim_height = -0.1, -- height for aiming
	shoot_aim_pitch = 0.51, -- pitch for aiming
}
