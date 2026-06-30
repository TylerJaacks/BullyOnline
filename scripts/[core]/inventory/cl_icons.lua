gIcons = {}

function F_PrepareIcon(name)
	local v = gIcons[name]
	if not v then
		error("missing "..name)
	end
	SetTextureBounds(unpack(v))
	return v[1]
end

function F_LoadIconSheet(name,width,height)
	local index = 0
	local image = CopyTexture(CreateTexture("images/"..name..".png"),"D3DFMT_DXT5")
	local list,lbytes = OpenFile("images/"..name..".txt","rb")
	local rows,cols = GetTextureResolution(image)
	rows,cols = rows/width,cols/height
	for icon in string.gfind(ReadFile(list,lbytes),"([^\r\n]+)") do
		local x1 = math.mod(index,rows) / rows
		local y1 = math.floor(index/rows) / cols
		local x2 = x1 + 1 / rows
		local y2 = y1 + 1 / cols
		gIcons[icon] = {image,x1,y1,x2,y2}
		index = index + 1
	end
	CloseFile(list)
end

F_LoadIconSheet("icons1",64,64)
F_LoadIconSheet("icons2",64,64)
