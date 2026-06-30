function main()
	while true do
		local area = AreaGetVisible()
		if area == 0 then
			if AreaIsDoorLocked(TRIGGER._DT_tschool_RoofDoor) then
				AreaSetDoorLocked(TRIGGER._DT_tschool_RoofDoor, false) -- Unlocks the roof door outside the school
			end
		elseif area == 2 then
			if AreaIsDoorLocked(TRIGGER._ISCHOOL_DOOR25) then
				AreaSetDoorLocked(TRIGGER._ISCHOOL_DOOR25, false) -- Unlocks the door leading to the staircase
			end
			if AreaIsDoorLocked(TRIGGER._DT_ISCHOOL_ROOFDOOR) then
				AreaSetDoorLocked(TRIGGER._DT_ISCHOOL_ROOFDOOR, false) -- Unlocks the roof door inside the school
			end
		end
		Wait(1000)
	end
end
