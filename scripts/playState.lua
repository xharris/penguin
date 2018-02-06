BlankE.addClassType("playState", "State")

play_mode = 'online'
game_start_population = 3

local k_join, k_leave, k_destruct

-- Called every time when entering the state.
function playState:enter(previous)
	wall = nil
	main_penguin = nil
	next_lvl_start = {0,0}
	last_lvl_end = {0,0}
	penguin_spawn = {}
	tile_snap = 32

	img_igloo_front = nil
	img_igloo_back = nil
	in_igloo_menu = false

	igloo_enter_x = 0
	destruct_ready_x = 0

	img_penguin = Image('penguin')
	Draw.setBackgroundColor('white2')
	water_color = hsv2rgb({212,70,100})

	bg_sky = Image('background')
	bg_sky.color = {0,0,210}
	img_igloo_front = Image("igloo_front")
	img_igloo_back = Image("igloo_back")

	igloo_enter_x = img_igloo_front.x + img_igloo_front.width - 25

	main_view = View()
	main_view.zoom_type = 'damped'
	main_view.zoom_speed = .05
	lvl_objects = Group()

	k_join = Input('j')
	k_leave = Input('d')
	k_destruct = Input('k')

	loadLevel("spawn")
	-- add player's penguin
	spawnPlayer()
	loadLevel("level1")
	loadLevel("level1")
end

local send_ready = false
function playState:update(dt)
	bg_sky.color = hsv2rgb({195,37,100})-- hsv2rgb({186,39,88})
	water_color = hsv2rgb({212,70,100})
	
	if k_join() then
		Steam.init()
	end

	-- enough players to start game
	if main_penguin.x > destruct_ready_x and not in_igloo_menu then
		if play_mode == 'online' and Net.getPopulation() >= game_start_population and not send_ready then
			send_ready = true
			Net.send({
				type="netevent",
				event="spawn_wall"
			})
		end

		if play_mode == 'single' then
			--startDestruction()
		end
	end

	-- player wants to enter igloo
	if main_penguin.x < igloo_enter_x then
		Net.disconnect()

		-- zoom in on igloo
		main_view:follow()
		main_view:moveToPosition(img_igloo_front.x + 90.25, img_igloo_front.y + img_igloo_front.height - (main_penguin.sprite['walk'].height / 2))

		-- transition to menu when zoomed in all the way
		if not in_igloo_menu and not wall then
			in_igloo_menu = true
			main_view:zoom(3, 3, function()
				State.transition(menuState, "circle-out")
			end)
		end

	elseif not Net.is_connected then
		Net.join()
		in_igloo_menu = false
		main_view:zoom(1)
		main_view:follow(main_penguin)
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
		FragImage.drawAll()

		Net.draw('DestructionWall')

		if not wall then img_igloo_back:draw() end
		Net.draw('Penguin')
		lvl_objects:call(function(o, obj)
			obj:draw()
			if main_penguin then main_penguin:draw() end 
		end)
		if not wall then img_igloo_front:draw() end
	end)
	local ready = ''
	if main_penguin.x > destruct_ready_x then ready = '\nREADY!' end
	Draw.text(tostring(Net.getPopulation())..' / '..tostring(game_start_population)..ready, game_width/2, 50)

	-- draw igloo menu
	if in_igloo_menu then

	end
end	

function loadLevel(name)
	local lvl_string = Asset.file(name)
	local lvl_length = lvl_string:len()
	local lvl_array = {{}}

	local lvl_start = {lvl_string:match("start (%d+),(%d+)")}
	local lvl_end = {lvl_string:match("end (%d+),(%d+)")}
	local offset_x = (last_lvl_end[1])*tile_snap
	local offset_y = (last_lvl_end[2])*tile_snap
	if name ~= 'spawn' then
		offset_x = (last_lvl_end[1] - lvl_start[1])*tile_snap
		offset_y = (last_lvl_end[2] - lvl_start[2])*tile_snap
	end

	Debug.log(name,offset_x, offset_y)

	last_lvl_end[1] = last_lvl_end[1] + (lvl_end[1] - lvl_start[1])
	last_lvl_end[2] = last_lvl_end[2] + (lvl_end[2] - lvl_start[2])

	local x, y = 1, 1
	local max_x, max_y = 1, 1
	local reading_map = false
	for c = 0, lvl_length do
		char = lvl_string:at(c)

		if c < lvl_length and reading_map then
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

		if char == "-" then
			reading_map = true
		end
	end

	local pos_x, pos_y = 0, 0
	for y = 1, max_y do
		for x = 1, max_x do
			char = lvl_array[y][x]
			pos_x, pos_y = x*tile_snap-tile_snap+offset_x, y*tile_snap-tile_snap+offset_y

			-- ice ground			
			if char == 'g' or char == 'c' then
				local ground_type = ''
				if char == 'c' then 
					destruct_ready_x = pos_x
					ground_type = "cracked"
				end
				lvl_objects:add(Ground(pos_x,pos_y,bitmask4(lvl_array, {'g','c'}, x, y),ground_type))
			end

			-- invisible block
			if char == 'q' then
				lvl_objects:add(Ground(pos_x,pos_y,-1))
			end

			-- igloo/player spawn
			if char == 'i' then
				lvl_objects:add(Ground(pos_x,pos_y,-1))
				img_igloo_front.x, img_igloo_front.y = pos_x, pos_y + tile_snap - img_igloo_front.height
				img_igloo_back.x, img_igloo_back.y = pos_x, pos_y + tile_snap - img_igloo_front.height

				penguin_spawn = {igloo_enter_x + 5, pos_y}
			end

			-- past this point to be ready
			if char == 'd' then
				destruct_ready_x = pos_x
			end
		end
	end
end

function spawnPlayer()
	main_penguin = Penguin(true)
	main_penguin.x, main_penguin.y = unpack(penguin_spawn)
	main_penguin:netSync('x','y')
end

function startDestruction()
	if not wall then
		wall = DestructionWall()
		wall.x = -32

		FragImage(img_igloo_front)
		FragImage(img_igloo_back)
	end
end

function Net:onReady()
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