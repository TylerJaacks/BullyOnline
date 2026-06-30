gNeedCleanup = false

-- main
function main()
	while true do
		local area = AreaGetVisible()
		if area == 0 then
			F_Outside()
		elseif area == 43 then
			F_Inside()
		end
		Wait(0)
	end
end
function MissionCleanup()
	if gNeedCleanup then
		AreaDisableCameraControlForTransition(false)
		PedSetUsesCollisionScripted(gPlayer,false)
		PedSetEffectedByGravity(gPlayer,true)
	end
end
function F_Outside()
	local x,y,z = PlayerGetPosXYZ()
	if x >= 545.15 and x < 551.82 and y >= -494.96 and y < -492.78 and z >= 5.3 and z < 5.8 and F_Facing(math.rad(163.42)) and PedGetFlag(gPlayer,37) and F_Jumping() then
		gNeedCleanup = true
		PlayerSetPosSimple(x,y,5.7)
		PedSetActionNode(gPlayer,"/GLOBAL/2_B/DRBYVAULT","2_B.ACT")
		PedSetEffectedByGravity(gPlayer,false)
		PedFaceHeading(gPlayer,163.42,0)
		while PedIsPlaying(gPlayer,"/GLOBAL/2_B/DRBYVAULT",true) do
			if PedGetNodeTime(gPlayer) >= 0.9 then
				if not AreaIsLoading() and AreaGetVisible() == 0 then
					F_Swap(true)
					x,y = PlayerGetPosXYZ()
					PlayerSetPosSimple(x,math.min(y,-624.72),4.49)
					PedSetActionNode(gPlayer,"/GLOBAL/PLAYER/JUMPACTIONS/JUMP/FALLING/LAND/FALL_LAND","")
				end
				break
			end
			Wait(0)
		end
		PedSetUsesCollisionScripted(gPlayer,false)
		PedSetEffectedByGravity(gPlayer,true)
		gNeedCleanup = false
	end
end
function F_Inside()
	local x,y,z = PlayerGetPosXYZ()
	if x >= -586.96 and x < -580.29 and y >= -624.23 and y < -622.05 and z >= 5.26 and z < 5.76 and F_Facing(math.rad(-16.42)) --[[and PedGetFlag(gPlayer,37)]] and F_Jumping() then
		gNeedCleanup = true
		PlayerSetPosSimple(x,y,5.7)
		PedSetActionNode(gPlayer,"/GLOBAL/2_B/DRBYVAULT","2_B.ACT")
		PedSetEffectedByGravity(gPlayer,false)
		PedFaceHeading(gPlayer,-16.42,0)
		while PedIsPlaying(gPlayer,"/GLOBAL/2_B/DRBYVAULT",true) do
			if PedGetNodeTime(gPlayer) >= 0.9 then
				if not AreaIsLoading() and AreaGetVisible() == 43 then
					F_Swap(false)
					x,y = PlayerGetPosXYZ()
					PlayerSetPosSimple(x,math.max(-493.72,y),4.45)
					PedSetActionNode(gPlayer,"/GLOBAL/PLAYER/JUMPACTIONS/JUMP/FALLING/LAND/FALL_LAND","")
				end
				break
			end
			Wait(0)
		end
		PedSetUsesCollisionScripted(gPlayer,false)
		PedSetEffectedByGravity(gPlayer,true)
		gNeedCleanup = false
	elseif x >= -739.43 and x < -737.67 and y >= -632.92 and y < -632.07 and z >= 4.5 and F_Facing(math.rad(-170)) and PedGetFlag(gPlayer,37) and F_Jumping() then
		gNeedCleanup = true
		PlayerSetPosSimple(x,y,5.2)
		PedSetActionNode(gPlayer,"/GLOBAL/2_B/DRBYVAULT","2_B.ACT")
		PedFaceHeading(gPlayer,-170,0)
		while PedIsPlaying(gPlayer,"/GLOBAL/2_B/DRBYVAULT",true) do
			Wait(0)
		end
		PedSetUsesCollisionScripted(gPlayer,false)
		gNeedCleanup = false
	end
end
function F_Facing(h)
	h = PedGetHeading(gPlayer) - h
	while h > math.pi do
		h = h - math.pi * 2
	end
	while h <= -math.pi do
		h = h + math.pi * 2
	end
	return math.abs(h) <= math.rad(20)
end
function F_Jumping()
	return PedIsPlaying(gPlayer,"/GLOBAL/PLAYER/JUMPACTIONS/JUMP",true) and (PedMePlaying(gPlayer,"RUNJUMP",true) or PedMePlaying(gPlayer,"SPRINTJUMP",true))
end
function F_Swap(go_inside)
	local px,py,pz = PlayerGetPosXYZ()
	local ox,oy,oz = -1132.113,-129.273,0.039
	AreaDisableCameraControlForTransition(true)
	if go_inside then
		PlayerSetPosXYZArea(px+ox,py+oy,pz+oz,43)
	else
		PlayerSetPosXYZArea(px-ox,py-oy,pz-oz,0)
	end
	while AreaIsLoading() do
		PedSetUsesCollisionScripted(gPlayer,true)
		PedSetEffectedByGravity(gPlayer,false)
		Wait(0)
	end
	AreaDisableCameraControlForTransition(false)
end
