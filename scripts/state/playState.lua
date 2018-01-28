BlankE.addClassType("playState", "State")

local k_join, k_leave, k_destruct
wall = nil
main_view = nil
test_scene = nil

-- Called every time when entering the state.
function playState:enter(previous)
	Draw.setBackgroundColor('white2')

	main_view = View()
	test_scene = Scene('level1')
	k_join = Input('j')
	k_leave = Input('d')
	k_destruct = Input('k')
end

function Net:onReady()
	-- add player's penguin
	new_penguin = Penguin()
	test_scene:addEntity(new_penguin)
	main_view:follow(new_penguin)

	Net.addObject(new_penguin)
end

function playState:update(dt)
	if k_join() and not Net.is_connected then
		Net.join()
	end

	if k_destruct() and not wall then
		wall = DestructionWall()
		wall.x = -32
		Net.addObject(wall)
	end

	if k_leave() and Net.is_connected then
		Net.disconnect()
	end
end

function playState:draw()
	main_view:draw(function()
		Net.draw('Penguin')
		test_scene:draw()
	end)
	Debug.draw()
end	
