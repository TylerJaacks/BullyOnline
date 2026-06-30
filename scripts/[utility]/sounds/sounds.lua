auto = {n = 0}
banks = {} -- [bank] = {[script] = true}
count = 0
script = GetCurrentScript()
SoundLoadBank = SoundLoadBank
SoundUnLoadBank = SoundUnLoadBank

MAX_BANKS = GetConfigNumber(GetScriptConfig(),"max_banks",10)
PLAY_DELAY = 100

-- max_banks acts more as a "target" than a limit
-- there can always be at least 1 auto loaded bank
-- auto banks will unload to attempt to stay at max_banks
-- if other scripts load max_banks, auto can bring it over by 1
-- in short: scripts shouldn't load over (max_banks - 1) banks manually

function exports.Play(sound,bank)
	bank = string.upper(bank)
	if GetTimer() - F_Sort(bank).when >= PLAY_DELAY then
		return SoundPlay2D(sound)
	end
	CreateThread(function()
		Wait(PLAY_DELAY)
		SoundPlay2D(sound)
	end)
end
function exports.Play3D(x,y,z,sound,bank)
	bank = string.upper(bank)
	if GetTimer() - F_Sort(bank).when >= PLAY_DELAY then
		return SoundPlay3D(x,y,z,sound)
	end
	CreateThread(function()
		Wait(PLAY_DELAY)
		SoundPlay3D(x,y,z,sound)
	end)
end
function F_Sort(bank)
	if not auto[1] then
		thread = CallFunctionFromScript(script,CreateThread,"T_Auto",AreaGetVisible())
	end
	for i,v in ipairs(auto) do
		if v.bank == bank then
			table.insert(auto,table.remove(auto,i))
			return v
		end
	end
	F_Load(bank,"auto")
	table.insert(auto,{bank = bank,when = GetTimer()})
	return auto[auto.n]
end
function T_Auto(area)
	while true do
		if AreaGetVisible() ~= area then -- unload banks on area transition
			while auto[1] do
				F_Unload(table.remove(auto).bank,"auto")
			end
			thread = nil
			return
		end
		Wait(0)
	end
end

function F_Load(bank,script)
	local scripts = banks[bank]
	if not scripts then
		if auto[1] and count >= MAX_BANKS then
			if not auto[2] then
				TerminateThread(thread)
				thread = nil
			end
			F_Unload(table.remove(auto,1).bank,"auto")
		end
		scripts = {}
		banks[bank] = scripts
		SoundLoadBank(bank)
		count = count + 1
	end
	scripts[script] = true
end
function F_Unload(bank,script)
	local scripts = banks[bank]
	if scripts then
		scripts[script] = nil
		if not next(scripts) then
			SoundUnLoadBank(bank)
			banks[bank] = nil
			count = count - 1
		end
	end
end
function F_Script()
	return GetCurrentScript() or GetCurrentNativeScript() or "unknown"
end

ReplaceFunction("SoundLoadBank",function(_,bank)
	F_Load(bank,F_Script())
end)
ReplaceFunction("SoundUnLoadBank",function(_,bank)
	F_Unload(bank,F_Script())
end)
RegisterLocalEventHandler("ScriptShutdown",function(script)
	if script == GetCurrentScript() then
		for bank in pairs(banks) do
			SoundUnLoadBank(bank)
		end
	end
end)
RegisterLocalEventHandler("ScriptDestroyed",function(script)
	for bank in pairs(banks) do
		F_Unload(bank,script)
	end
end)
