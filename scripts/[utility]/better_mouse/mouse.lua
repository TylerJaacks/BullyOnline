local gSteering = false -- auto skateboard mouse steering
local gLimited = false -- disable direct mouse input
local gThread
local gEvent -- ControllersUpdated event
local gMult

function main()
	local data = GetPersistentDataTable("Xx_Yubari_xX").better_mouse
	if type(data) == "table" then
		if type(data.mult) == "number" then
			gEvent = RegisterLocalEventHandler("ControllersUpdated",CB_ControllersUpdated)
			gMult = data.mult
		end
		if data.steer == true then
			gSteering = true
		end
		F_UpdateThread()
	end
	RegisterLocalEventHandler("f2menu:Open",CB_F2MenuOpen)
end
function CB_F2MenuOpen(f_add)
	f_add({
		name = "Better Mouse Controls",
		description = "Configure mouse controls.",
		thread = M_BetterMouse,
	})
end

function M_BetterMouse(parent,selected)
	local menu = parent:submenu(selected.name)
	while menu:active() do
		if menu:option("Auto Skateboard Steering",gSteering and "[ON]" or "[OFF]","Turn mouse steering for vehicles on / off automatically when the skateboard is equipped.") then
			gSteering = not gSteering
			F_SaveSettings()
			F_UpdateThread()
		end
		if menu:option("Direct Mouse Input",gEvent and "[ON]" or "[OFF]","Use more direct mouse input for the virtual controller. Improves responsiveness.") then
			if gEvent then
				RemoveEventHandler(gEvent)
				gEvent = nil
			else
				gEvent = RegisterLocalEventHandler("ControllersUpdated",CB_ControllersUpdated)
				gMult = -0.01 -- default
			end
			F_SaveSettings()
			F_UpdateThread()
		elseif gEvent and menu:option("Direct Sensitivity",string.format("[%.3f]",-gMult)) then
			local typing = StartTyping()
			if typing then
				while menu:active() do
					if not IsTypingActive(typing) then
						if not WasTypingAborted(typing) then
							local mult = tonumber(GetTypingString(typing))
							if mult and mult >= 0 and mult <= 1 then
								gMult = -mult
								F_SaveSettings()
								SoundPlay2D("RightBtn")
							else
								menu:alert("Invalid multiplier, try again.")
								SoundPlay2D("WrongBtn")
							end
						end
						break
					end
					menu:draw(GetTypingString(typing,true))
					Wait(0)
				end
			end
		end
		menu:draw()
		Wait(0)
	end
end
function F_SaveSettings()
	local persist = GetPersistentDataTable("Xx_Yubari_xX") -- .better_mouse = nil | number
	if gEvent or gSteering then
		local data = {}
		if gEvent then
			data.mult = gMult
		end
		if gSteering then
			data.steer = true
		end
		persist.better_mouse = data
	else
		persist.better_mouse = nil
	end
	SavePersistentDataTables()
end
function F_UpdateThread()
	if gEvent or gSteering then
		if not gThread then
			gThread = CreateThread("T_UpdateMouse")
		end
	elseif gThread then
		TerminateThread(gThread)
		gThread = nil
	end
end

function CB_ControllersUpdated()
	if not IsUsingJoystick(0) then
		local x,y = GetMouseInput()
		x,y = x*gMult,y*gMult
		if gLimited then
			local h = math.atan2(x,y)
			local dist = math.sqrt(x*x+y*y)
			if dist > 1 then
				dist = 1
			end
			x,y = math.sin(h)*dist,math.cos(h)*dist
		end
		if GetStickValue(18,0) ~= 0 then -- respect other scripts disabling sticks
			SetStickValue(18,0,x)
		end
		if GetStickValue(19,0) ~= 0 then
			SetStickValue(19,0,y)
		end
	end
end
function T_UpdateMouse()
	while true do
		local steering = GetMouseVehicleSteering()
		local skateboard = PlayerHasWeapon(437)
		if gSteering and not IsUsingJoystick(0) then
			if steering then
				if not skateboard then
					SetMouseVehicleSteering(false)
				end
			elseif skateboard then
				SetMouseVehicleSteering(true)
			end
		end
		gLimited = steering and skateboard
		Wait(0)
	end
end
