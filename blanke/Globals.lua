mouse_x = 0
mouse_y = 0
game_width = 0
game_height = 0
window_width = 0
window_height = 0
game_time = 0

function updateGlobals(dt)
	game_time = game_time + dt

	local width, height = love.window.fromPixels(love.graphics.getDimensions())
	local x_scale, y_scale = width / 800, height / 600
	local new_width, new_height = width, height

	BlankE.scale_mode = 'scale'

	if BlankE.scale_mode == 'stretch' then
		BlankE.scale_x = x_scale
		BlankE.scale_y = y_scale
		BlankE._offset_x = 0
		BlankE._offset_y = 0
		new_width, new_height = width / x_scale, height / y_scale
	end

	if BlankE.scale_mode == 'scale' then
		local scale = math.min(x_scale, y_scale)
		new_width, new_height = width / x_scale, height / y_scale

		BlankE.scale_x = scale
		BlankE.scale_y = scale
		BlankE._offset_x = 0
		BlankE._offset_y = 0
		if x_scale > y_scale then
			BlankE._offset_x = (width / scale / 2) - (new_width / 2)
		else
			BlankE._offset_y = (height / scale / 2) - (new_height / 2)
		end
	end

	mouse_x, mouse_y = BlankE.scaledMouse(love.mouse.getX() + ifndef(Effect._mouse_offx, 0), love.mouse.getY() + ifndef(Effect._mouse_offy, 0))
	game_width = new_width
	game_height = new_height
	window_width = width / BlankE.scale_x
	window_height = height / BlankE.scale_y
end

CONF = {
    window = {
        width = 800,
        height = 600
    }
}