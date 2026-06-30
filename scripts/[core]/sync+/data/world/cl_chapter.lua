-- SYNC+ | chapter | Xx_Yubari_xX
--  provides client side chapter sync

gChapter = -1

-- events
RegisterNetworkEventHandler("sync+:SetChapter",function(chapter)
	gChapter = chapter
end)

-- controller
CreateThread(function()
	SendNetworkEvent("sync+:GetChapter")
	while gChapter == -1 do
		Wait(0)
	end
	while true do
		if ChapterGet() ~= gChapter and not AreaIsLoading() then
			ChapterSet(gChapter)
			while AreaIsLoading() do
				Wait(0)
			end
			for sped in AllSyncPeds() do
				local ped = PedFromSyncPed(sped)
				if PedIsValid(ped) then
					F_UpdateModel(ped)
				end
			end
		end
		Wait(0)
	end
end)

-- fix
function F_UpdateModel(ped)
	local model = gPedModels[PedGetModelId(ped)]
	if model == "Peter" then
		PedSwapModel(ped,"Nemesis_Gary")
	else
		PedSwapModel(ped,"Peter")
	end
	PedSwapModel(ped,model)
end

-- models
gPedModels = {
	[0] = "player","DEFAULTPED","DOgirl_Zoe_EG","NDGirl_Beatrice","NDH1a_Algernon","NDH1_Fatty","ND2nd_Melvin","NDH2_Thad",
	"NDH3_Bucky","NDH2a_Cornelius","NDLead_Earnest","NDH3a_Donald","JKH1_Damon","JKH1a_Kirby","JKGirl_Mandy","JKH2_Dan",
	"JKH2a_Luis","JKH3_Casey","JKH3a_Bo","JKlead_Ted","JK2nd_Juri","GR2nd_Peanut","GRH2A_Hal","GRlead_Johnny",
	"GRH1_Lefty","GRGirl_Lola","GRH3_Lucky","GRH1a_Vance","GRH3a_Ricky","GRH2_Norton","PRH1_Gord","PRH1a_Tad",
	"PRH2a_Chad","PR2nd_Bif","PRH3_Justin","PRH2_Bryce","PRH2_Bryce_OBOX","PRlead_Darby","PRGirl_Pinky","GN_Asiangirl",
	"PRH3a_Parker","DOH2_Jerry","DOH1a_Otto","DOH2a_Leon","DOH1_Duncan","DOH3_Henry","DOH3a_Gurney","DO2nd_Omar",
	"DOGirl_Zoe","PF2nd_Max","PFH1_Seth","PFH2_Edward","PFlead_Karl","TO_Orderly","TE_HallMonitor","TE_GymTeacher",
	"TE_Janitor","TE_English","TE_Cafeteria","TE_Secretary","TE_Nurse","TE_MathTeacher","TE_Librarian","TE_Art",
	"TE_Biology","TE_Principal","GN_Littleblkboy","GN_SexyGirl","GN_Littleblkgirl","GN_Hispanicboy","GN_Greekboy","GN_Fatboy",
	"GN_Boy01","GN_Boy02","GN_Fatgirl","DOlead_Russell","TO_Business1","TO_Business2","TO_BusinessW1","TO_BusinessW2",
	"TO_RichW1","TO_RichW2","TO_Fireman","TO_Cop","TO_Comic","GN_Bully03","TO_Bikeowner","TO_Hobo",
	"Player_Mascot","TO_GroceryOwner","GN_Sexygirl_UW","DOLead_Edgar","JK_LuisWrestle","JKGirl_MandyUW","PRGirl_PinkyUW","NDGirl_BeatriceUW",
	"GRGirl_LolaUW","TO_Cop2","Player_OWres","GN_Bully02","TO_RichM1","TO_RichM2","GN_Bully01","TO_FireOwner",
	"TO_CSOwner_2","TO_CSOwner_3","TE_Chemistry","TO_Poorwoman","TO_MotelOwner","JKKirby_FB","JKTed_FB","JKDan_FB",
	"JKDamon_FB","TO_Carny02","TO_Carny01","TO_CarnyMidget","TO_Poorman2","PRH2A_Chad_OBOX","PRH3_Justin_OBOX","PRH3a_Parker_OBOX",
	"TO_BarberRich","GenericWrestler","ND_FattyWrestle","TO_Industrial","TO_Associate","TO_Asylumpatient","TE_Autoshop","TO_Mailman",
	"TO_Tattooist","TE_Assylum","Nemesis_Gary","TO_Oldman2","TO_BarberPoor","PR2nd_Bif_OBOX","Peter","TO_RichM3",
	"Rat_Ped","GN_LittleGirl_2","GN_LittleGirl_3","GN_WhiteBoy","TO_FMidget","Dog_Pitbull","GN_SkinnyBboy","TO_Carnie_female",
	"TO_Business3","GN_Bully04","GN_Bully05","GN_Bully06","TO_Business4","TO_Business5","DO_Otto_asylum","TE_History",
	"TO_Record","DO_Leon_Assylum","DO_Henry_Assylum","NDH1_FattyChocolate","TO_GroceryClerk","TO_Handy","TO_Orderly2","GN_Hboy_Ween",
	"Nemesis_Ween","GRH3_Lucky_Ween","NDH3a_Donald_ween","PRH3a_Parker_Ween","JKH3_Casey_Ween","Peter_Ween","GN_AsianGirl_Ween","PRGirl_Pinky_Ween",
	"JKH1_Damon_ween","GN_WhiteBoy_Ween","GN_Bully01_Ween","GN_Boy02_Ween","PR2nd_Bif_OBOX_D1","GRH1a_Vance_Ween","NDH2_Thad_Ween","PRGirl_Pinky_BW",
	"DOlead_Russell_BU","PRH1a_Tad_BW","PRH2_Bryce_BW","PRH3_Justin_BW","GN_Asiangirl_CH","GN_Sexygirl_CH","PRGirl_Pinky_CH","TO_NH_Res_01",
	"TO_NH_Res_02","TO_NH_Res_03","NDH1_Fatty_DM","TO_PunkBarber","FightingMidget_01","FightingMidget_02","TO_Skeletonman","TO_Beardedwoman",
	"TO_CarnieMermaid","TO_Siamesetwin2","TO_Paintedman","TO_GN_Workman","DOLead_Edgar_GS","DOH3a_Gurney_GS","DOH2_Jerry_GS","DOH2a_Leon_GS",
	"GRH2a_Hal_GS","GRH2_Norton_GS","GR2nd_Peanut_GS","GRH1a_Vance_GS","JKH3a_Bo_GS","JKH1_Damon_GS","JK2nd_Juri_GS","JKH1a_Kirby_GS",
	"NDH1a_Algernon_GS","NDH3_Bucky_GS","NDH2_Thad_GS","PRH3a_Parker_GS","PRH3_Justin_GS","PRH1a_Tad_GS","PRH1_Gord_GS","NDLead_Earnest_EG",
	"JKlead_Ted_EG","GRlead_Johnny_EG","PRlead_Darby_EG","Dog_Pitbull2","Dog_Pitbull3","TE_CafeMU_W","TO_Millworker","TO_Dockworker",
	"NDH2_Thad_PJ","GN_Lblkboy_PJ","GN_Hboy_PJ","GN_Boy01_PJ","GN_Boy02_PJ","TE_Gym_Incog","JK_Mandy_Towel","JK_Bo_FB",
	"JK_Casey_FB","PunchBag","TO_Cop3","GN_GreekboyUW","TO_Construct01","TO_Construct02","TO_Cop4","PRH2_Bryce_OBOX_D1",
	"PRH2_Bryce_OBOX_D2","PRH2A_Chad_OBOX_D1","PRH2A_Chad_OBOX_D2","PR2nd_Bif_OBOX_D2","PRH3_Justin_OBOX_D1","PRH3_Justin_OBOX_D2","PRH3a_Prkr_OBOX_D1","PRH3a_Prkr_OBOX_D2",
	"TE_Geography","TE_Music","TO_ElfF","TO_ElfM","TO_HoboSanta","TO_Santa","TO_Santa_NB","Peter_Nutcrack","GN_Fatgirl_Fairy","GN_Lgirl_2_Flower","GN_Hboy_Flower"
}
