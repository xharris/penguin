BlankE.addClassType("playState", "State")

local k_join, k_leave, k_destruct
wall = nil
main_view = nil
main_penguin = nil
lvl_objects = nil
last_lvl_end = {0,0}
penguin_spawn = {}
tile_snap = 32

-- Called every time when entering the state.
function playState:enter(previous)
	Draw.setBackgroundColor('white2')

	main_view = View()
	lvl_objects = Group()

	k_join = Input('j')
	k_leave = Input('d')
	k_destruct = Input('k')

	load_level("test")
	-- add player's penguin
	spawnPlayer()
	Net.join()
end

function load_level(name)
	lvl_string = Asset.file('test')
	lvl_length = lvl_string:len()
	lvl_array = {{}}

	local x, y = 1, 1
	local max_x, max_y = 1, 1
	for c = 0, lvl_length do
		char = lvl_string:at(c)
		if c < lvl_length then
			if char == '\n' then
				x = 1
				y = y + 1
				lvl_array[y] = {}
			elseif char:trim() ~= '' then
				lvl_array[y][x] = char
				x = x + 1
			end
			if x > max_x then max_x = x end
			if y > max_y then max_y = y end
		end
	end

	local pos_x, pos_y = 0, 0
	for y = 1, max_y do
		for x = 1, max_x do
			char = lvl_array[y][x]
			pos_x, pos_y = x*tile_snap-tile_snap, y*tile_snap-tile_snap

			if char == 'g' then
				lvl_objects:add(Ground(pos_x,pos_y,bitmask4(lvl_array, 'g', x, y)))
			end

			if char == 'p' then
				table.insert(penguin_spawn, {pos_x, pos_y})
			end
		end
	end
end

function spawnPlayer()
	main_penguin = Penguin()
	main_penguin.x, main_penguin.y = unpack(penguin_spawn[1])
	main_view:follow(main_penguin)
end

function Net:onReady()
	-- add player's penguin
	spawnPlayer()

	Net.addObject(main_penguin)
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
			if main_penguin then main_penguin:draw() end 
		end)
	end)
	Debug.draw()
end	
