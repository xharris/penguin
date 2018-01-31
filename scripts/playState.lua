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

	bg_sky = Image('background')
	bg_sky.color = {0,0,210}

	main_view = View()
	lvl_objects = Group()

	k_join = Input('j')
	k_leave = Input('d')
	k_destruct = Input('k')

	loadLevel("test")
	-- add player's penguin
	spawnPlayer()
	Net.join()
end

local send_ready = false
function playState:update(dt)
	bg_sky.color = hsv2rgb({195,37,100})--hsv2rgb({186,39,88})
	water_color = hsv2rgb({212,70,100})
	
	if k_join() then
		Steam.init()
	end

	if Net.getPopulation() >= 3 and not send_ready then
		send_ready = true
		Net.send({
			type="netevent",
			event="spawn_wall"
		})
	end

	if k_leave() and Net.is_connected then
		Net.disconnect()
	end
end

local spawn_wall_count = 0
function playState:draw()
	-- draw water
	Draw.setColor(water_color)
	Draw.rect('fill',0,0,game_width,game_height)
	
	-- draw sky
	Draw.resetColor()
	bg_sky:tileX()

	-- draw objects
	main_view:draw(function()
		if wall then wall:draw() end
		Net.draw('DestructionWall')
		Net.draw('Penguin')
		lvl_objects:call(function(o, obj)
			obj:draw()
			if main_penguin then main_penguin:draw() end 
		end)
	end)
	Draw.text(tostring(spawn_wall_count)..'/'..tostring(Net.getPopulation()), game_width/2, 50)
	
	Draw.setColor('black')
	Draw.rect('line', 5, 5, game_width-10, game_height-10)

	Debug.draw()
end	


function loadLevel(name)
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

function startDestruction()
	if not wall then
		wall = DestructionWall()
		wall.x = -32
		--Net.addObject(wall)
	end
end

function Net:onReady()
	-- add player's penguin
	spawnPlayer()

	Net.addObject(main_penguin)
end

Net.onEvent = function(data)
	if data.event == "spawn_wall" then
		spawn_wall_count = spawn_wall_count + 1

		if spawn_wall_count >= Net.getPopulation() then
			startDestruction()
		end
	end
end