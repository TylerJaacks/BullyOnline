gCollision = false

function MissionCleanup()
	if gCollision then
		PedSetUsesCollisionScripted(gPlayer,false)
	end
end
function main()
	while true do
		if PlayerIsInAreaXYZ(183.01,-471.02,11.49,10) then
			if PlayerIsInAreaXYZ(183.01,-471.02,11.49,0.5) and PedIsPlaying(gPlayer,"/GLOBAL/LADDER/LADDER_ACTIONS/CLIMB_ON_BOT",true) then
				PedSetAnchor(gPlayer,183.35,-471.74,13.24)
				PedSetAnchorMatrix(gPlayer,Rz(math.rad(-150.0)))
				ForceActionNode(gPlayer,"/GLOBAL/WPROPS/WALLCLIMB/6FOOTWALL/WALKING/2MWALL","")
				PedSetUsesCollisionScripted(gPlayer,true)
				gCollision = true
				while PedIsPlaying(gPlayer,"/GLOBAL/WPROPS/WALLCLIMB/6FOOTWALL/WALKING/2MWALL",true) and PedGetNodeTime(gPlayer) < 0.3 do
					Wait(0)
				end
				PedSetUsesCollisionScripted(gPlayer,false)
				gCollision = false
			elseif PlayerIsInAreaXYZ(183.72,-472.38,11.49,0.5) and PedIsPlaying(gPlayer,"/GLOBAL/LADDER/LADDER_ACTIONS/CLIMB_ON_BOT",true) then
				PedSetAnchor(gPlayer,183.35,-471.74,13.24)
				PedSetAnchorMatrix(gPlayer,Rz(math.rad(35.0)))
				ForceActionNode(gPlayer,"/GLOBAL/WPROPS/WALLCLIMB/6FOOTWALL/WALKING/2MWALL","")
				PedSetUsesCollisionScripted(gPlayer,true)
				gCollision = true
				while PedIsPlaying(gPlayer,"/GLOBAL/WPROPS/WALLCLIMB/6FOOTWALL/WALKING/2MWALL",true) and PedGetNodeTime(gPlayer) < 0.3 do
					Wait(0)
				end
				PedSetUsesCollisionScripted(gPlayer,false)
				gCollision = false
			elseif PlayerIsInAreaXYZ(183.59,-472.46,10.37,0.5) and PedIsPlaying(gPlayer,"/GLOBAL/WPROPS/PROPINTERACT/PROPINTERACTLOCO/LOCODIRECTWITHDEEQUIP",true) then
				PedSetActionNode(gPlayer,"/GLOBAL/WPROPS/PROPINTERACT/PROPINTERACTLOCO/BASE/PROPINTERACTLOCODIRECT/INTERACT","")
			end
		end
		Wait(0)
	end
end
