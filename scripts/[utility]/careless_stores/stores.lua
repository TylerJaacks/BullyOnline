RegisterLocalEventHandler("NativeScriptLoaded",function(name,env)
	if name == "SStores.lua" or name == "AreaScripts/StyleStores.lua" then
		env.F_Aggression = F_Aggression
	end
end)
function F_Aggression()
end
