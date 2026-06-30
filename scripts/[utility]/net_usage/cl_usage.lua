HISTORY_MS = 2000

gBytes = 0
gShowing = false

function main()
	local history = {n = 0}
	GetSentBytes()
	Wait(0)
	while true do
		local sent = GetSentBytes()
		local timer = GetAccurateTimer()
		local value = history[1]
		while value and timer - value[1] >= HISTORY_MS do
			gBytes = gBytes - table.remove(history,1)[2]
			value = history[1]
		end
		table.insert(history,{timer,sent})
		gBytes = gBytes + sent
		if gShowing then
			F_DrawUsage(gBytes)
		end
		Wait(0)
	end
end
function F_DrawUsage(bytes)
	SetTextFont("Cascadia Code")
	SetTextBold()
	SetTextColor(255,255,255,255)
	SetTextAlign("R","B")
	SetTextPosition(1,1)
	SetDrawLayer("PRE_FADE2")
	local w,h = DrawText(F_FormatBytes(bytes*(1000/HISTORY_MS)))
	SetDrawLayer("PRE_FADE")
	DrawRectangle(1-w,1-h,w,h,0,0,0,255)
end
function F_FormatBytes(bytes)
	local unit = 1
	local units = {"B","KiB","MiB","GiB"}
	while bytes >= 1024 do
		bytes = bytes / 1024
		unit = unit + 1
	end
	if units[unit] then
		return string.format("%.1f %s / s",bytes,units[unit])
	end
	return "? / s"
end
function CB_UsageCommand(arg)
	if arg then
		arg = string.lower(arg)
		if arg == "show" then
			gShowing = true
		elseif arg == "hide" then
			gShowing = false
		else
			PrintError("expected \"show\", \"hide\", or no argument")
		end
	else
		PrintOutput("client outgoing: "..F_FormatBytes(gBytes*(1000/HISTORY_MS)))
		SendNetworkEvent("net_usage:Request")
	end
end

RegisterNetworkEventHandler("net_usage:Allow",function()
	SetCommand("usage",CB_UsageCommand,false,"Usage: usage [\"show\" | \"hide\"]\nPrint the outgoing network usage, or make it display on-screen.")
end)
RegisterNetworkEventHandler("net_usage:Print",function(bytes)
	PrintOutput("server outgoing: "..F_FormatBytes(bytes*(1000/HISTORY_MS)))
end)

SendNetworkEvent("net_usage:Init")
