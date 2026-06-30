-- SYNC+ | action configuration | Xx_Yubari_xX
--  this file is used by sv_actions.lua and cl_actions.lua

local ALLOW
local STYLES
local allow
local node

-- utility functions
function F_IsNodeAllowed(node)
	-- return true if the node is allowed using the ALLOW table (at the bottom)
	-- the node is expected to be in /#XXXXXXXX format already
	return allow(node,ALLOW,1)
end
function F_GetTreeFile(tree)
	-- returns the file for the action tree, or nil if it isn't allowed
	-- the tree is converted into /#XXXXXXXX if needed
	return STYLES[node(tree)]
end
function allow(node,t,i)
	for ak,av in pairs(t) do
		local a1,a2 = string.find(node,"^"..ak,i)
		if a1 then
			for dk,dv in pairs(av) do
				local d1,d2 = string.find(node,"^"..dk,a2+1)
				if d1 then
					return allow(node,dv,d2+1) -- in the denies table, so check its allows
				end
			end
			return true -- in the allows table
		end
	end
	return false -- not in the allows table
end

-- convert nodes (into /#XXXXXXXX format)
function F_ConvertNode(convert)
	local result = ""
	for str in string.gfind(convert,"/([^/]+)") do
		result = result.."/"..GetHashString(ObjectNameToHashID(str)) -- forces into #XXXXXXXX
	end
	return result
end
node = F_ConvertNode

-- tree permissions
STYLES = {
	-- all trees with a default_key
	[node("/GLOBAL/1_02B/CONSTANTINOSIDLE")] = "1_02B.ACT",
	[node("/GLOBAL/1_03_DAVIS")] = "1_03_DAVIS.ACT",
	[node("/GLOBAL/2_07_GORD")] = "P_2_07_GORD.ACT",
	[node("/GLOBAL/AMBIENT/SPECTATOR")] = "AMBIENT.ACT",
	[node("/GLOBAL/AN_DOG")] = "AN_DOG.ACT",
	[node("/GLOBAL/AN_RAT")] = "AN_RAT.ACT",
	[node("/GLOBAL/AUTHORITY")] = "AUTHORITY.ACT",
	[node("/GLOBAL/BASKETBALL/BASKETBALL")] = "BASKETBALL.ACT",
	[node("/GLOBAL/BAT")] = "BAT.ACT",
	[node("/GLOBAL/BOOKS/BOOKS")] = "BOOKS.ACT",
	[node("/GLOBAL/BOSS_DARBY")] = "BOSS_DARBY.ACT",
	[node("/GLOBAL/BOSS_RUSSELL")] = "BOSS_RUSSELL.ACT",
	[node("/GLOBAL/BOXINGPLAYER")] = "BOXINGPLAYER.ACT",
	[node("/GLOBAL/B_STRIKER_A")] = "B_STRIKER_A.ACT",
	[node("/GLOBAL/CRAZY_BASIC")] = "CRAZY_BASIC.ACT",
	[node("/GLOBAL/CV_DRUNK")] = "CV_DRUNK.ACT",
	[node("/GLOBAL/CV_FEMALE_A")] = "CV_FEMALE_A.ACT",
	[node("/GLOBAL/CV_MALE_A")] = "CV_MALE_A.ACT",
	[node("/GLOBAL/CV_OLD")] = "CV_OLD.ACT",
	[node("/GLOBAL/DO_EDGAR")] = "DO_EDGAR.ACT",
	[node("/GLOBAL/DO_GRAPPLER_A")] = "DO_GRAPPLER_A.ACT",
	[node("/GLOBAL/DO_MELEE_A")] = "DO_MELEE_A.ACT",
	[node("/GLOBAL/DO_STRIKER_A")] = "DO_STRIKER_A.ACT",
	[node("/GLOBAL/EDGARSHIELD")] = "EDGARSHIELD.ACT",
	[node("/GLOBAL/FIGHT_TUTORIAL")] = "FIGHT_TUTORIAL.ACT",
	[node("/GLOBAL/FLASHLIGHT/FLASHLIGHT")] = "FLASHLIGHT.ACT",
	[node("/GLOBAL/GS_FAT_A")] = "GS_FAT_A.ACT",
	[node("/GLOBAL/GS_FEMALE_A")] = "GS_FEMALE_A.ACT",
	[node("/GLOBAL/GS_MALE_A")] = "GS_MALE_A.ACT",
	[node("/GLOBAL/GUN/GUN")] = "GUN.ACT",
	[node("/GLOBAL/G_GRAPPLER_A")] = "G_GRAPPLER_A.ACT",
	[node("/GLOBAL/G_JOHNNY")] = "G_JOHNNY.ACT",
	[node("/GLOBAL/G_MELEE_A")] = "G_MELEE_A.ACT",
	[node("/GLOBAL/G_RANGED_A")] = "G_RANGED_A.ACT",
	[node("/GLOBAL/G_STRIKER_A")] = "G_STRIKER_A.ACT",
	[node("/GLOBAL/HF_SPECTATOR")] = "HF_SPECTATOR.ACT",
	[node("/GLOBAL/HOBO_BLOCKER")] = "HOBO_BLOCKER.ACT",
	[node("/GLOBAL/JBROOM")] = "JBROOM.ACT",
	[node("/GLOBAL/J_DAMON")] = "J_DAMON.ACT",
	[node("/GLOBAL/J_GRAPPLER_A")] = "J_GRAPPLER_A.ACT",
	[node("/GLOBAL/J_MASCOT")] = "J_MASCOT.ACT",
	[node("/GLOBAL/J_MELEE_A")] = "J_MELEE_A.ACT",
	[node("/GLOBAL/J_STRIKER_A")] = "J_STRIKER_A.ACT",
	[node("/GLOBAL/J_TED")] = "J_TED.ACT",
	[node("/GLOBAL/KICKMESIGN/KICKMESIGN")] = "KICKMESIGN.ACT",
	[node("/GLOBAL/LE_ORDERLY_A")] = "LE_ORDERLY_A.ACT",
	[node("/GLOBAL/NEMESIS")] = "NEMESIS.ACT",
	[node("/GLOBAL/NONWEAPON/NONWEAPON")] = "NONWEAPON.ACT",
	[node("/GLOBAL/NORTON")] = "3_05_NORTON.ACT",
	[node("/GLOBAL/NPC1_09")] = "NPC1_09.ACT",
	[node("/GLOBAL/NPC_CHEER_A")] = "NPC_CHEER_A.ACT",
	[node("/GLOBAL/N_EARNEST")] = "N_EARNEST.ACT",
	[node("/GLOBAL/N_RANGED_A")] = "N_RANGED_A.ACT",
	[node("/GLOBAL/N_STRIKER_A")] = "N_STRIKER_A.ACT",
	[node("/GLOBAL/N_STRIKER_B")] = "N_STRIKER_B.ACT",
	[node("/GLOBAL/PLAYER")] = "PLAYER.ACT",
	[node("/GLOBAL/P_BIF")] = "P_BIF.ACT",
	[node("/GLOBAL/P_GRAPPLER_A")] = "P_GRAPPLER_A.ACT",
	[node("/GLOBAL/P_STRIKER_A")] = "P_STRIKER_A.ACT",
	[node("/GLOBAL/P_STRIKER_B")] = "P_STRIKER_B.ACT",
	[node("/GLOBAL/RUSSELL_102")] = "RUSSELL_102.ACT",
	[node("/GLOBAL/SHIELDS")] = "SHIELDS.ACT",
	[node("/GLOBAL/SIMPLELOCO")] = "SIMPLELOCO.ACT",
	[node("/GLOBAL/SLASHER")] = "SLASHER.ACT",
	[node("/GLOBAL/SLEDGEHAMMER")] = "SLEDGEHAMMER.ACT",
	[node("/GLOBAL/SLINGSHOT/SLINGSHOT")] = "SLINGSHOT.ACT",
	[node("/GLOBAL/SNOWSHOVEL/SNOWSHOVEL")] = "SNOWSHOVEL.ACT",
	[node("/GLOBAL/SPECIAL_ITEMS")] = "SPECIAL_ITEMS.ACT",
	[node("/GLOBAL/SPRAYCAN")] = "SPRAYCAN.ACT",
	[node("/GLOBAL/TE_FEMALE_A")] = "TE_FEMALE_A.ACT",
	[node("/GLOBAL/TE_SECRETARY")] = "TE_SECRETARY.ACT",
	[node("/GLOBAL/THROWN/THROWN")] = "THROWN.ACT",
	[node("/GLOBAL/TO_SIAMESE")] = "TO_SIAMESE.ACT",
	[node("/GLOBAL/UMBRELLA")] = "UMBRELLA.ACT",
	[node("/GLOBAL/WATERPIPE")] = "WATERPIPE.ACT",
	[node("/GLOBAL/WCAMERA/WCAMERA")] = "WCAMERA.ACT",
	[node("/GLOBAL/WFIREEXT")] = "WFIREEXT.ACT",
	[node("/GLOBAL/WRESTLINGACT")] = "WRESTLINGACT.ACT",
	[node("/GLOBAL/WRESTLINGNPC")] = "WRESTLINGNPC_ACT.ACT",
}

-- node permissions (flips from ALLOW to DENY in each table)
ALLOW = {
	-- common (arbitrary nodes that are common enough to be needed)
	[node("/GLOBAL/ACTIONS")] = {},
	[node("/GLOBAL/AMBIENT")] = {
		[node("/MISSIONSPEC/GETONCANNON")] = {},
		[node("/TALKING/TALKING/GEN/SPEECHANIMS/SPAWNS")] = {},
	},
	[node("/GLOBAL/DOOR/PEDPROPACTIONS")] = {
		[node("/EXECUTES")] = {},
		[node("/USINGDOOR")] = {},
		[node("/USINGDOORSPAWNER")] = {},
		[node("/USINGDOORSPAWNERRUN")] = {},
	},
	[node("/GLOBAL/HITTREE")] = {},
	[node("/GLOBAL/SODAMACH")] = {},
	[node("/GLOBAL/LADDER/LADDER_ACTIONS/CLIMB_ON_BOT")] = {},
	
	-- mission (arbitrary picks that were tested for stability)
	[node("/GLOBAL/1_11X1/ANIMATIONS/GARYIDLEINBED")] = {},
	
	-- */default_key/executenodes/free
	[node("/GLOBAL/#02834716/FREE")] = {},
	
	-- */default_key/executenodes/locomotionoverride
	[node("/GLOBAL/#037BF360/LOCOMOTIONOVERRIDE")] = {},
	
	-- */default_key/locomotion
	[node("/GLOBAL/#5F7E8739/LOCOMOTION")] = {},
	
	-- nc_loco
	[node("/GLOBAL/#0066AC1A/GLOBALLOCO/LOCOMOTION/LOCOMOTIONEXECUTES/NONCOMBATSTRAFE/NC_LOCO")] = {},
	
	-- shared moves (used for some moves in some styles)
	[node("/GLOBAL/#1A200030/DO_STRIKECOMBO")] = {},
	
	-- snowballs
	[node("/GLOBAL/WEAPONS/PICKUPACTIONS/PICKUPSNOWBALL/PICKUPWEAPON/PICKUPWEAPON")] = {},
	
	-- sitting
	[node("/GLOBAL/PXSITSTL/DISENGAGE")] = {},
	[node("/GLOBAL/PXSITSTL/PEDPROPSACTIONS")] = {},
	
	-- vehicle stuff
	[node("/GLOBAL/VEHICLES/BIKES")] = {
		[node("/AIR/THROW")] = {},
		[node("/EXECUTENODES")] = {},
		[node("/GROUND/WEAPONSELECTSPAWN")] = {},
		[node("/SCRIPTCALLS")] = {},
		[node("/SPAWNBANK")] = {},
		[node("/TEST")] = {},
	},
	[node("/GLOBAL/VEHICLES/CARS")] = {},
	[node("/GLOBAL/VEHICLES/MOTORCYCLE")] = {
		[node("/EXECUTENODES")] = {},
	},
	[node("/GLOBAL/VEHICLES/SCOOTER")] = {
		[node("/EXECUTENODES")] = {},
		[node("/GROUND/ATTACKS/PUNCH")] = {
			[node("/PUNCHLEFTCHARGE/PUNCHLEFTCHARGEATTACK/PUNCHLEFTCHARGEATTACKFULL/PUNCHLEFT/PUNCHLEFTHOLD/PUNCHLEFTRELEASE")] = {},
			[node("/PUNCHLEFTCHARGE/PUNCHLEFTCHARGEATTACK/PUNCHLEFTCHARGEATTACKPARTIAL/PUNCHLEFT/PUNCHLEFTHOLD/PUNCHLEFTRELEASE")] = {},
			[node("/PUNCHRIGHTCHARGE/PUNCHRIGHTCHARGEATTACK/PUNCHRIGHTCHARGEATTACKFULL/PUNCHRIGHT/PUNCHRIGHTHOLD/PUNCHRIGHTRELEASE")] = {},
			[node("/PUNCHRIGHTCHARGE/PUNCHRIGHTCHARGEATTACK/PUNCHRIGHTCHARGEATTACKPARTIAL/PUNCHRIGHT/PUNCHRIGHTHOLD/PUNCHRIGHTRELEASE")] = {},
		},
	},
	[node("/GLOBAL/VEHICLES/SKATEBOARD/LOCOMOTION")] = {
		[node("/HANDLEDOORS")] = {},
		[node("/KICKBALLSPAWN")] = {},
		[node("/RIDE/ANCHOREDTOVEHICLE")] = {},
		[node("/WAIT")] = {},
	},
	
	-- styles (nodes that have a DEFAULT_KEY)
	[node("/GLOBAL/1_02B/CONSTANTINOSIDLE")] = {},
	[node("/GLOBAL/1_03_DAVIS")] = {},
	[node("/GLOBAL/2_07_GORD")] = {},
	[node("/GLOBAL/AMBIENT/SPECTATOR")] = {},
	[node("/GLOBAL/AN_DOG")] = {},
	[node("/GLOBAL/AN_RAT")] = {},
	[node("/GLOBAL/AUTHORITY")] = {},
	[node("/GLOBAL/BASKETBALL/BASKETBALL")] = {},
	[node("/GLOBAL/BAT")] = {},
	[node("/GLOBAL/BOOKS/BOOKS")] = {},
	[node("/GLOBAL/BOSS_DARBY")] = {},
	[node("/GLOBAL/BOSS_RUSSELL")] = {},
	[node("/GLOBAL/BOXINGPLAYER")] = {},
	[node("/GLOBAL/B_STRIKER_A")] = {},
	[node("/GLOBAL/CRAZY_BASIC")] = {},
	[node("/GLOBAL/CV_DRUNK")] = {},
	[node("/GLOBAL/CV_FEMALE_A")] = {},
	[node("/GLOBAL/CV_MALE_A")] = {},
	[node("/GLOBAL/CV_OLD")] = {},
	[node("/GLOBAL/DO_EDGAR")] = {},
	[node("/GLOBAL/DO_GRAPPLER_A")] = {},
	[node("/GLOBAL/DO_MELEE_A")] = {},
	[node("/GLOBAL/DO_STRIKER_A")] = {},
	[node("/GLOBAL/EDGARSHIELD")] = {},
	[node("/GLOBAL/FIGHT_TUTORIAL")] = {},
	[node("/GLOBAL/FLASHLIGHT/FLASHLIGHT")] = {},
	[node("/GLOBAL/GS_FAT_A")] = {},
	[node("/GLOBAL/GS_FEMALE_A")] = {},
	[node("/GLOBAL/GS_MALE_A")] = {},
	[node("/GLOBAL/GUN/GUN")] = {},
	[node("/GLOBAL/G_GRAPPLER_A")] = {},
	[node("/GLOBAL/G_JOHNNY")] = {},
	[node("/GLOBAL/G_MELEE_A")] = {},
	[node("/GLOBAL/G_RANGED_A")] = {},
	[node("/GLOBAL/G_STRIKER_A")] = {},
	[node("/GLOBAL/HF_SPECTATOR")] = {},
	[node("/GLOBAL/HOBO_BLOCKER")] = {},
	[node("/GLOBAL/JBROOM")] = {},
	[node("/GLOBAL/J_DAMON")] = {},
	[node("/GLOBAL/J_GRAPPLER_A")] = {},
	[node("/GLOBAL/J_MASCOT")] = {},
	[node("/GLOBAL/J_MELEE_A")] = {},
	[node("/GLOBAL/J_STRIKER_A")] = {},
	[node("/GLOBAL/J_TED")] = {},
	[node("/GLOBAL/KICKMESIGN/KICKMESIGN")] = {},
	[node("/GLOBAL/LE_ORDERLY_A")] = {},
	[node("/GLOBAL/NEMESIS")] = {},
	[node("/GLOBAL/NONWEAPON/NONWEAPON")] = {},
	[node("/GLOBAL/NORTON")] = {},
	[node("/GLOBAL/NPC1_09")] = {},
	[node("/GLOBAL/NPC_CHEER_A")] = {},
	[node("/GLOBAL/N_EARNEST")] = {},
	[node("/GLOBAL/N_RANGED_A")] = {},
	[node("/GLOBAL/N_STRIKER_A")] = {},
	[node("/GLOBAL/N_STRIKER_B")] = {},
	[node("/GLOBAL/PLAYER")] = {
		[node("/ATTACKS/GROUNDATTACKS/GROUNDATTACKS/STRIKES/HEAVYATTACKS/GROUNDKICK")] = {
			[node("/GROUNDKICK")] = {},
			[node("/GROUNDKICKCHARGED")] = {},
		},
		[node("/ATTACKS/STRIKES/LIGHTATTACKS")] = {
			-- deny light attacks *unless*
			[node("/LEFT1/RELEASE")] = {},
			[node("/LEFT1/RIGHT2/RELEASE")] = {},
			[node("/LEFT1/RIGHT2/LEFT3/RELEASE")] = {},
			[node("/LEFT1/RIGHT2/LEFT3//RIGHT4/RELEASE")] = {},
			[node("/LEFT1/RIGHT2/LEFT3//RIGHT4/LEFT5/RELEASE")] = {},
			[node("/SHOVE")] = {},
		},
		[node("/ATTACKS/STRIKES/RUNNINGATTACKS")] = {
			-- deny running attacks *unless*
			[node("/HEAVYATTACKS")] = {
				-- but not the running after
				[node("/RUNPUNCH")] = {},
				[node("/RUNSHOULDER")] = {},
			},
		},
		[node("/BED")] = {},
		[node("/GIFTS")] = {},
		[node("/SOCIAL_ACTIONS")] = {},
		[node("/SOCIAL_COMBAT")] = {},
		[node("/SOCIAL_SPEECH")] = {},
	},
	[node("/GLOBAL/P_BIF")] = {},
	[node("/GLOBAL/P_GRAPPLER_A")] = {},
	[node("/GLOBAL/P_STRIKER_A")] = {},
	[node("/GLOBAL/P_STRIKER_B")] = {},
	[node("/GLOBAL/RUSSELL_102")] = {},
	[node("/GLOBAL/SHIELDS")] = {},
	[node("/GLOBAL/SIMPLELOCO")] = {},
	[node("/GLOBAL/SLASHER")] = {},
	[node("/GLOBAL/SLEDGEHAMMER")] = {},
	[node("/GLOBAL/SLINGSHOT/SLINGSHOT")] = {},
	[node("/GLOBAL/SNOWSHOVEL/SNOWSHOVEL")] = {},
	[node("/GLOBAL/SPECIAL_ITEMS")] = {},
	[node("/GLOBAL/SPRAYCAN")] = {},
	[node("/GLOBAL/TE_FEMALE_A")] = {},
	[node("/GLOBAL/TE_SECRETARY")] = {},
	[node("/GLOBAL/THROWN/THROWN")] = {},
	[node("/GLOBAL/TO_SIAMESE")] = {},
	[node("/GLOBAL/UMBRELLA")] = {},
	[node("/GLOBAL/WATERPIPE")] = {},
	[node("/GLOBAL/WCAMERA/WCAMERA")] = {},
	[node("/GLOBAL/WFIREEXT")] = {},
	[node("/GLOBAL/WRESTLINGACT")] = {},
	[node("/GLOBAL/WRESTLINGNPC")] = {},
}

-- nodes that should be corrected immediately when an un-owned ped is in combat
gStopAttacks = {
	-- this is a list of lua search patterns
	node("/ATTACKS"),
	node("/OFFENSE"),
}
