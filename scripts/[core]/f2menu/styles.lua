function styles.Morpheus()
	local title_format,option_format,description_format
	DiscardText()
	SetTextFont("Cascadia Code")
	SetTextAlign("C","C")
	SetTextBold()
	-- SetTextItalic()
	SetTextShadow()
	SetTextScale(1.4)
	SetTextColor(115,222,117,255)
	SetTextWrapping(width)
	title_format = PopTextFormatting()
	SetTextFont("Cascadia Code")
	SetTextAlign("L","T")
	SetTextBold()
	SetTextScale(0.9)
	SetTextColor(210,210,210,255)
	option_format = PopTextFormatting()
	SetTextFont("Cascadia Code")
	SetTextAlign("L","T")
	SetTextBold()
	SetTextScale(0.7)
	SetTextColor(210,210,210,255)
	description_format = PopTextFormatting()
	return {
		menu_x = 0.04, -- x and w values are divided by aspect ratio
		menu_y = 0.285,
		menu_w_min = 0.48,
		menu_w_max = 0.58,
		title_pad_x = 0.008, -- padding is the total on both sides
		title_pad_y = 0.016,
		option_pad_x = 0.004,
		option_pad_y = 0.004,
		option_right_w = 0.8, -- relative to calculated width
		option_count = 16,
		desc_off_y = 0.006,
		desc_pad_x = 0.010,
		desc_pad_y = 0.010,
		scrollbar_width = 0.008,
		title_background = {20,20,20,190},
		option_background = {115,222,117,190},
		title_format = title_format,
		option_format = option_format,
		description_format = description_format,
	}
end
function styles.Academy()
	local title_format,option_format,description_format
	DiscardText()
	SetTextFont("Georgia")
	SetTextAlign("C","C")
	SetTextBold()
	-- SetTextItalic()
	SetTextShadow()
	SetTextScale(1.4)
	SetTextColor(250,200,2,255)
	SetTextWrapping(width)
	title_format = PopTextFormatting()
	SetTextFont("Georgia")
	SetTextAlign("L","T")
	SetTextBold()
	SetTextScale(0.9)
	SetTextColor(227,189,0,255)
	option_format = PopTextFormatting()
	SetTextFont("Georgia")
	SetTextAlign("L","T")
	SetTextBold()
	SetTextScale(0.7)
	SetTextColor(210,210,210,255)
	description_format = PopTextFormatting()
	return {
		menu_x = 0.04, -- x and w values are divided by aspect ratio
		menu_y = 0.285,
		menu_w_min = 0.48,
		menu_w_max = 0.58,
		title_pad_x = 0.008, -- padding is the total on both sides
		title_pad_y = 0.020,
		option_pad_x = 0.008,
		option_pad_y = 0.008,
		option_right_w = 0.8, -- relative to calculated width
		option_count = 16,
		desc_off_y = 0.006,
		desc_pad_x = 0.010,
		desc_pad_y = 0.010,
		scrollbar_width = 0.008,
		title_background = {28,65,145,190},
		option_background = {227,189,0,190},
		title_format = title_format,
		option_format = option_format,
		description_format = description_format,
	}
end
