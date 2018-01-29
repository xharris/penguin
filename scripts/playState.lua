BlankE.addClassType("playState", "State")

local k_join, k_leave, k_destruct
wall = nil
main_view = nil
lvl_objects = nil
last_lvl_end = {0,0}

-- Called every time when entering the state.
function playState:enter(previous)
	Draw.setBackgroundColor('white2')

	main_view = View()
	lvl_objects = Group()

	k_join = Input('j')
	k_leave = Input('d')
	k_destruct = Input('k')

	load_level("test")
end

function load_level(name)
	lvl_string = Asset.file('test')
	lvl_length = lvl_string:len()

	local x = 0
	local y = 0
	local snap = 32
	for c = 0, lvl_length do
		char = lvl_string:at(c)
		if char == '\n' then
			x = 0
			y = y + snap
		end

		if char == 'g' then
			lvl_objects:add(Ground(x,y))
		end

		x = x + snap
	end
end

function Net:onReady()
	-- add player's penguin
	new_penguin = Penguin()
	level_container:addEntity(new_penguin)
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
		if wall then wall:draw() end
		Net.draw('DestructionWall')
		Net.draw('Penguin')
		lvl_objects:call(function(o, obj)
			obj:draw()
		end)
	end)
	Debug.draw()
end	
