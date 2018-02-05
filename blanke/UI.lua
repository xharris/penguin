UI = Class{
	margin = 4,
	element_width = 100,
	element_height = 20,

	_color = {
		window_bg = Draw.white,
		window_outline = Draw.blue,
		element_bg = Draw.grey,
		text = Draw.white
	},

	_window = nil,
	next_element_x = 0,
	next_element_y = 0,

	color = function(name, value)
		if not value then return UI._color[name]
		else UI._color[name] = value end
	end,

	window = function(label, x, y, width, height)
		UI._window = {label, x, y, width, height}
		UI.next_element_x = x + UI.margin
		UI.next_element_y = y + UI.margin
		
		Draw.setColor(UI.color('window_outline'))
		Draw.rect('line', x,y,width,height)
		Draw.setColor(UI.color('window_bg'))
		Draw.rect('fill',x,y,width,height)
	end,

	spinbox = function(label, options, selected)
		if UI._window then
			local win_title, win_x, win_y, win_w, win_h = unpack(UI._window)
			local selection_index = table.find(options, selected)
			if selection_index < 1 or selection_index > #options then
				selection_index = 1
			end

			local element_x = UI.next_element_x
			local element_y = UI.next_element_y
			local element_w = win_w-(UI.margin*2)
			local element_h = UI.element_height

			-- container
			Draw.setColor(UI.color('element_bg'))
			Draw.rect('fill',element_x,element_y,element_w,element_h)
		
			-- text
			Draw.setColor(UI.color('text'))
			Draw.textf(selected, element_x, element_y+2, element_w, "center")
		end
	end,
}

return UI