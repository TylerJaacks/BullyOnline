-- SYNC+ | convenience api | Xx_Yubari_xX
--  provides server functions that attempt to replicate client ones

-- to keep this file simple and performant, there is little extra error checking
-- bad arguments are guaranteed to raise errors, but the error message may be unexpected

local dist
local gPedModels

-- every global function in this script gets registered using RegisterFunction
setfenv(1,setmetatable({},{__index=_G,__newindex=function(_,name,func)
	-- any error that happens inside a registered function will show the location of the caller instead
	-- this is because the 3rd argument of RegisterFunction can redirect the error message
	RegisterFunction(name,func,true)
end}))

-- internal utility
function dist(x1,y1,z1,x2,y2,z2)
	local dx,dy,dz = x2-x1,y2-y1,z2-z1
	return dx*dx+dy*dy+dz*dz
end

-- general api
function DistanceBetweenCoords2d(x1,y1,x2,y2)
	x2,y2 = x2-x1,y2-y1
	return math.sqrt(x2*x2+y2*y2)
end
function DistanceBetweenCoords3d(x1,y1,z1,x2,y2,z2)
	x2,y2,z2 = x2-x1,y2-y1,z2-z1
	return math.sqrt(x2*x2+y2*y2+z2*z2)
end

-- ped api
function AllPeds()
	return AllSyncPeds(GetSyncActiveDimension())
end
function DistanceBetweenPeds2D(ped1,ped2)
	-- the inconsistent spelling is intentional, because it's consistent with the client.
	local x1,y1 = GetSyncEntityPos(ped1)
	local x2,y2 = GetSyncEntityPos(ped2)
	x2,y2 = x2-x1,y2-y1
	return math.sqrt(x2*x2+y2*y2)
end
function DistanceBetweenPeds3D(ped1,ped2)
	local x,y,z = GetSyncEntityPos(ped1)
	return math.sqrt(dist(x,y,z,GetSyncEntityPos(ped2)))
end
function PedCreateXYZ(model,x,y,z)
	local ped = CreateSyncPed(model)
	SetSyncEntityPos(ped,x,y,z)
	return ped
end
function PedDelete(ped)
	DeleteSyncEntity(ped)
end
function PedDetachFromVehicle(ped)
	SetSyncPedVehicle(ped,nil)
end
function PedFindInAreaObject(obj,range)
	local results = {}
	local ox,oy,oz = GetSyncEntityPos(obj) -- the client only allows peds but we'll allow any.
	range = range * range
	for ped in AllSyncPeds(GetSyncActiveDimension()) do
		local px,py,pz = GetSyncEntityPos(ped)
		if dist(px,py,pz,ox,oy,oz) < range then
			table.insert(results,ped)
		end
	end
	if results[1] then
		return true,unpack(results)
	end
	return false
end
function PedFindInAreaXYZ(x,y,z,range)
	local results = {}
	range = range * range
	for ped in AllSyncPeds(GetSyncActiveDimension()) do
		local px,py,pz = GetSyncEntityPos(ped)
		if dist(px,py,pz,x,y,z) < range then
			table.insert(results,ped)
		end
	end
	if results[1] then
		return true,unpack(results)
	end
	return false
end
function PedFromSyncId(id)
	local ped = GetSyncEntityFromId(id)
	if IsSyncPedValid(ped) then
		return ped
	end
	return nil
end
function PedGetHeading(ped)
	local x,y,z,h = GetSyncEntityPos(ped)
	return h
end
function PedGetModelId(ped)
	return GetSyncEntityModel(ped)
end
function PedGetSyncId(ped)
	return GetSyncEntityId(ped)
end
function PedGetPosXYZ(ped)
	local x,y,z = GetSyncEntityPos(ped)
	return x,y,z
end
function PedIsInAnyVehicle(ped)
	return GetSyncPedVehicle(ped) ~= nil
end
function PedIsInAreaObject(ped,obj,otype,range)
	local x,y,z = GetSyncEntityPos(ped)
	if otype == 1 then
		if not IsSyncVehicleValid(obj) then
			typerror(2,"vehicle")
		end
	elseif otype == 2 or otype == 3 then
		if not IsSyncPedValid(obj) then
			typerror(2,"ped")
		end
	elseif type(otype) ~= "number" then
		typerror(3,"number")
	end
	return dist(x,y,z,GetSyncEntityPos(obj)) < range * range
end
function PedIsInAreaXYZ(ped,x,y,z,range)
	local px,py,pz = GetSyncEntityPos(ped)
	return dist(px,py,pz,x,y,z) < range * range
end
function PedIsInVehicle(ped,vehicle)
	return GetSyncPedVehicle(ped) == vehicle
end
function PedIsValid(ped)
	return IsSyncPedValid(ped)
end
function PedPutOnBike(ped,bike)
	if bike == nil then
		error("expected vehicle")
	end
	SetSyncPedVehicle(ped,bike)
end
function PedSetPosXYZ(ped,x,y,z)
	SetSyncEntityPos(ped,x,y,z)
end
function PedSwapModel(ped,model)
	if type(model) == "string" then
		model = string.lower(model)
		for m = 0,258 do
			if gPedModels[m] == model then
				model = m
				break
			end
		end
		if type(model) == "string" then
			error("unknown model")
		end
	end
	SetSyncEntityModel(ped,model)
end
function PedWarpIntoCar(ped,vehicle,seat)
	if vehicle == nil then
		error("expected vehicle")
	end
	SetSyncPedVehicle(ped,vehicle,seat)
end
function PedWarpOutOfCar(ped)
	SetSyncPedVehicle(ped,nil)
end

-- vehicle api
function AllVehicles()
	return AllSyncVehicles(GetSyncActiveDimension())
end
function VehicleCreateXYZ(model,x,y,z)
	local vehicle = CreateSyncVehicle(model)
	SetSyncEntityPos(vehicle,x,y,z)
	return vehicle
end
function VehicleDelete(vehicle)
	DeleteSyncEntity(vehicle)
end
function VehicleFaceHeading(vehicle,h)
	local x,y,z = GetSyncEntityPos(vehicle)
	SetSyncEntityPos(vehicle,x,y,z,h)
end
function VehicleFindInAreaXYZ(x,y,z,range)
	local results = {}
	range = range * range
	for vehicle in AllSyncVehicles(GetSyncActiveDimension()) do
		local vx,vy,vz = GetSyncEntityPos(vehicle)
		if dist(vx,vy,vz,x,y,z) < range then
			table.insert(results,vehicle)
		end
	end
	if results[1] then
		return results
	end
	return nil
end
function VehicleFromDriver(ped)
	return (GetSyncPedVehicle(ped))
end
function VehicleFromSyncId(id)
	local vehicle = GetSyncEntityFromId(id)
	if IsSyncVehicleValid(vehicle) then
		return vehicle
	end
	return nil
end
function VehicleGetHeading(vehicle)
	local x,y,z,h = GetSyncEntityPos(vehicle)
	return h
end
function VehicleGetModelId(vehicle)
	return GetSyncEntityModel(vehicle)
end
function VehicleGetSyncId(vehicle)
	return GetSyncEntityId(vehicle)
end
function VehicleGetPosXYZ(vehicle)
	local x,y,z = GetSyncEntityPos(vehicle)
	return x,y,z
end
function VehicleIsInAreaXYZ(vehicle,x,y,z,range)
	local vx,vy,vz = GetSyncEntityPos(vehicle)
	return dist(vx,vy,vz,x,y,z) < range * range
end
function VehicleIsValid(vehicle)
	return IsSyncVehicleValid(vehicle)
end
function VehicleSetPosXYZ(vehicle,x,y,z)
	SetSyncEntityPos(vehicle,x,y,z)
end

-- ped models for PedSwapModel
gPedModels = {
	"defaultped","dogirl_zoe_eg","ndgirl_beatrice","ndh1a_algernon","ndh1_fatty","nd2nd_melvin","ndh2_thad","ndh3_bucky",
	"ndh2a_cornelius","ndlead_earnest","ndh3a_donald","jkh1_damon","jkh1a_kirby","jkgirl_mandy","jkh2_dan","jkh2a_luis",
	"jkh3_casey","jkh3a_bo","jklead_ted","jk2nd_juri","gr2nd_peanut","grh2a_hal","grlead_johnny","grh1_lefty",
	"grgirl_lola","grh3_lucky","grh1a_vance","grh3a_ricky","grh2_norton","prh1_gord","prh1a_tad","prh2a_chad",
	"pr2nd_bif","prh3_justin","prh2_bryce","prh2_bryce_obox","prlead_darby","prgirl_pinky","gn_asiangirl","prh3a_parker",
	"doh2_jerry","doh1a_otto","doh2a_leon","doh1_duncan","doh3_henry","doh3a_gurney","do2nd_omar","dogirl_zoe",
	"pf2nd_max","pfh1_seth","pfh2_edward","pflead_karl","to_orderly","te_hallmonitor","te_gymteacher","te_janitor",
	"te_english","te_cafeteria","te_secretary","te_nurse","te_mathteacher","te_librarian","te_art","te_biology",
	"te_principal","gn_littleblkboy","gn_sexygirl","gn_littleblkgirl","gn_hispanicboy","gn_greekboy","gn_fatboy","gn_boy01",
	"gn_boy02","gn_fatgirl","dolead_russell","to_business1","to_business2","to_businessw1","to_businessw2","to_richw1",
	"to_richw2","to_fireman","to_cop","to_comic","gn_bully03","to_bikeowner","to_hobo","player_mascot",
	"to_groceryowner","gn_sexygirl_uw","dolead_edgar","jk_luiswrestle","jkgirl_mandyuw","prgirl_pinkyuw","ndgirl_beatriceuw","grgirl_lolauw",
	"to_cop2","player_owres","gn_bully02","to_richm1","to_richm2","gn_bully01","to_fireowner","to_csowner_2",
	"to_csowner_3","te_chemistry","to_poorwoman","to_motelowner","jkkirby_fb","jkted_fb","jkdan_fb","jkdamon_fb",
	"to_carny02","to_carny01","to_carnymidget","to_poorman2","prh2a_chad_obox","prh3_justin_obox","prh3a_parker_obox","to_barberrich",
	"genericwrestler","nd_fattywrestle","to_industrial","to_associate","to_asylumpatient","te_autoshop","to_mailman","to_tattooist",
	"te_assylum","nemesis_gary","to_oldman2","to_barberpoor","pr2nd_bif_obox","peter","to_richm3","rat_ped",
	"gn_littlegirl_2","gn_littlegirl_3","gn_whiteboy","to_fmidget","dog_pitbull","gn_skinnybboy","to_carnie_female","to_business3",
	"gn_bully04","gn_bully05","gn_bully06","to_business4","to_business5","do_otto_asylum","te_history","to_record",
	"do_leon_assylum","do_henry_assylum","ndh1_fattychocolate","to_groceryclerk","to_handy","to_orderly2","gn_hboy_ween","nemesis_ween",
	"grh3_lucky_ween","ndh3a_donald_ween","prh3a_parker_ween","jkh3_casey_ween","peter_ween","gn_asiangirl_ween","prgirl_pinky_ween","jkh1_damon_ween",
	"gn_whiteboy_ween","gn_bully01_ween","gn_boy02_ween","pr2nd_bif_obox_d1","grh1a_vance_ween","ndh2_thad_ween","prgirl_pinky_bw","dolead_russell_bu",
	"prh1a_tad_bw","prh2_bryce_bw","prh3_justin_bw","gn_asiangirl_ch","gn_sexygirl_ch","prgirl_pinky_ch","to_nh_res_01","to_nh_res_02",
	"to_nh_res_03","ndh1_fatty_dm","to_punkbarber","fightingmidget_01","fightingmidget_02","to_skeletonman","to_beardedwoman","to_carniemermaid",
	"to_siamesetwin2","to_paintedman","to_gn_workman","dolead_edgar_gs","doh3a_gurney_gs","doh2_jerry_gs","doh2a_leon_gs","grh2a_hal_gs",
	"grh2_norton_gs","gr2nd_peanut_gs","grh1a_vance_gs","jkh3a_bo_gs","jkh1_damon_gs","jk2nd_juri_gs","jkh1a_kirby_gs","ndh1a_algernon_gs",
	"ndh3_bucky_gs","ndh2_thad_gs","prh3a_parker_gs","prh3_justin_gs","prh1a_tad_gs","prh1_gord_gs","ndlead_earnest_eg","jklead_ted_eg",
	"grlead_johnny_eg","prlead_darby_eg","dog_pitbull2","dog_pitbull3","te_cafemu_w","to_millworker","to_dockworker","ndh2_thad_pj",
	"gn_lblkboy_pj","gn_hboy_pj","gn_boy01_pj","gn_boy02_pj","te_gym_incog","jk_mandy_towel","jk_bo_fb","jk_casey_fb",
	"punchbag","to_cop3","gn_greekboyuw","to_construct01","to_construct02","to_cop4","prh2_bryce_obox_d1","prh2_bryce_obox_d2",
	"prh2a_chad_obox_d1","prh2a_chad_obox_d2","pr2nd_bif_obox_d2","prh3_justin_obox_d1","prh3_justin_obox_d2","prh3a_prkr_obox_d1","prh3a_prkr_obox_d2","te_geography",
	"te_music","to_elff","to_elfm","to_hobosanta","to_santa","to_santa_nb","peter_nutcrack","gn_fatgirl_fairy","gn_lgirl_2_flower","gn_hboy_flower"
}
gPedModels[0] = "player"
