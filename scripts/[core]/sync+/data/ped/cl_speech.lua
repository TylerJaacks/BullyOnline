-- SYNC+ | ped speech | Xx_Yubari_xX
--  provides client side speech event sync

LoadScript("data/utility/shared/keys.lua")

local counts = setmetatable({},{__mode = "k"})
local playing = false

CreateThread(function()
	while true do
		for sped in AllSyncPeds() do
			if sped[KEY_SPEECH] ~= -1 and IsSyncEntityOwned(sped) then
				local ped = PedFromSyncPed(sped)
				if PedIsValid(ped) and not SoundSpeechPlaying(ped) then
					sped[KEY_SPEECH] = -1
					sped[KEY_SPEECH_RSM] = -1
					sped[KEY_SPEECH_COUNT] = math.mod(sped[KEY_SPEECH_COUNT]+1,1000)
				end
			end
		end
		Wait(0)
	end
end)
RegisterLocalEventHandler("PedPlaySpeech",function(ped,event,line)
	if not playing and PedIsValid(ped) then
		local sped = PedGetSyncPed(ped)
		if sped then
			if not IsSyncEntityOwned(sped) then
				return true
			end
			sped[KEY_SPEECH] = event
			sped[KEY_SPEECH_RSM] = line
			sped[KEY_SPEECH_COUNT] = math.mod(sped[KEY_SPEECH_COUNT]+1,1000)
		end
	end
end)
RegisterLocalEventHandler("sync:SpawnPed",function(sped)
	counts[sped] = nil
end)
RegisterLocalEventHandler("sync:PreUpdatePed",function(sped)
	if WasSyncEntityUpdated(sped,KEY_SPEECH) or not IsSyncEntityOwned(sped) then
		if (counts[sped] or 0) ~= sped[KEY_SPEECH_COUNT] then
			local ped = PedFromSyncPed(sped)
			if PedIsValid(ped) then
				playing = true
				xpcall(function()
					SoundStopCurrentSpeechEvent(ped)
					if sped[KEY_SPEECH_RSM] ~= -1 then
						SoundPlayAmbientSpeechEventSpecific(ped,sped[KEY_SPEECH],sped[KEY_SPEECH_RSM])
					elseif sped[KEY_SPEECH] ~= -1 then
						SoundPlayAmbientSpeechEventSpecific(ped,sped[KEY_SPEECH])
					end
				end,function(err)
					PrintWarning("failed to play speech event ("..tostring(err)..")")
				end)
				playing = false
			end
		end
		counts[sped] = sped[KEY_SPEECH_COUNT]
	end
end)
