function main()
	while true do
		for sped in AllSyncPeds() do
			local ped = PedFromSyncPed(sped)
			if PedIsValid(ped) and PedIsModel(ped,136) then
				PedSetEntityFlag(ped,41,false) -- targetable again
				PedSetEntityFlag(ped,45,false) -- not visible again
			end
		end
		if PedIsModel(gPlayer,136) then
			PedSetFacialNodeSimple(gPlayer,"/GLOBAL")
		end
		Wait(0)
	end
end

function F_ValidateNode(node,...)
	local index = 1
	for str in string.gfind(node,"/([^/]+)") do
		if not IsHash(ObjectNameToHashID(str),arg[index]) then
			return false
		elseif index >= arg.n then
			break
		end
		index = index + 1
	end
	return true
end
function F_CheckNode(ped,node)
	local model = PedGetModelId(ped)
	if model == 136 then
		if not F_ValidateNode(node,"026A69A7","42951BDF") then -- check for /GLOBAL/AN_RAT
			return false
		end
	elseif (model == 141 or model == 219 or model == 220) and not F_ValidateNode(node,"026A69A7","4291787E") then -- /GLOBAL/AN_DOG
		return false
	end
	return true
end

RegisterLocalEventHandler("first_person:Activate",function()
	local model = PedGetModelId(gPlayer)
	if model == 141 or model == 219 or model == 220 then
		return true
	end
end)
RegisterLocalEventHandler("sync:SwapModel",function(model)
	if model == 136 then
		if PedGetActionTree(gPlayer) ~= "" then
			PedSetActionTree(gPlayer,"","")
		end
	elseif (model == 141 or model == 219 or model == 220) and PedGetActionTree(gPlayer) ~= "" then
		PedSetActionTree(gPlayer,"","")
	end
end)

function exports.IsPedAnimal(ped)
	local model = PedGetModelId(ped)
	return model == 136 or model == 141 or model == 219 or model == 220
end
function exports.IsNodeSafe(ped,node)
	return F_CheckNode(ped,node)
end

ReplaceFunction("PedSetActionNode",function(func,ped,node,file)
	if not F_CheckNode(ped,node) then
		return false
	end
	return func(ped,node,file)
end)
ReplaceFunction("PedSetActionTree",function(func,ped,node,file)
	if F_CheckNode(ped,node) then
		return func(ped,node,file)
	end
end)
