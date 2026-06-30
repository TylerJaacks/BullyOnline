FORCE_STYLE_ROOT = "/Global/Player"
FORCE_STYLE_FILE = "Player.act"

function main()
	while true do
		local r,f = PedGetActionTree(gPlayer)
		if not PedIsModel(gPlayer,136) and PedMePlaying(gPlayer,"DEFAULT_KEY",true) and (r ~= FORCE_STYLE_ROOT or f ~= FORCE_STYLE_FILE) then
			PedSetActionTree(gPlayer,FORCE_STYLE_ROOT,FORCE_STYLE_FILE)
		end
		Wait(0)
	end
end
