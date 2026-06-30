-- SYNC+ | ped speech | Xx_Yubari_xX
--  provides server side speech event sync

LoadScript("data/utility/shared/keys.lua")

local st = GetScriptSharedTable()

-- events:
RegisterLocalEventHandler("sync:ValidateData",function(ent,key,value)
	if key == KEY_SPEECH or key == KEY_SPEECH_RSM or key == KEY_SPEECH_COUNT then
		return not st.finite(value)
	end
end)
RegisterLocalEventHandler("sync:CreatePed",function(ped)
	F_InitPed(ped)
end)

-- initialize:
function F_InitPed(ped)
	ped[KEY_SPEECH] = -1
	ped[KEY_SPEECH_RSM] = -1
	ped[KEY_SPEECH_COUNT] = 0
end
for ped in AllSyncPeds() do
	F_InitPed(ped)
end

-- api:
RegisterFunction("SoundStopCurrentSpeechEvent",function(ped)
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	end
	ped[KEY_SPEECH] = -1
	ped[KEY_SPEECH_RSM] = -1
	ped[KEY_SPEECH_COUNT] = math.mod(ped[KEY_SPEECH_COUNT]+1,1000)
end)
RegisterFunction("SoundPlayAmbientSpeechEvent",function(ped,event,rsm) -- rsm is optional
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif type(event) == "string" then
		event = ObjectNameToHashID(event)
		for i,v in ipairs(st.speech) do
			if v == event then
				event = i - 1
				break
			end
		end
		if type(event) ~= "number" then
			argerror(2,"unsupported speech event")
		end
	elseif type(event) ~= "number" then
		typerror(2,"string") -- or number
	end
	if rsm ~= nil and type(rsm) ~= "number" then
		typerror(3,"number")
	end
	ped[KEY_SPEECH] = event
	ped[KEY_SPEECH_RSM] = rsm or -1
	ped[KEY_SPEECH_COUNT] = math.mod(ped[KEY_SPEECH_COUNT]+1,1000)
end)
RegisterFunction("SoundSpeechPlaying",function(ped,event,rsm) -- event and rsm are optional
	if not IsSyncPedValid(ped) then
		typerror(1,"ped")
	elseif event ~= nil then
		if rsm ~= nil and ped[KEY_SPEECH_RSM] ~= rsm then
			return false
		end
		return ped[KEY_SPEECH] == event
	end
	return ped[KEY_SPEECH] ~= -1
end)
