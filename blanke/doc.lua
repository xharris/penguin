--[[ 
TODO
* manually adding assets

WIP
* View.squeezeH()
* Image.chop()
* Input region

variable - value (arg)
variable = value (keyword arg)
aMethod(arg, [optional_arg])

When to click 'Reload' button
* init() method of object has been modified
* asset has been added
]]

--- INITIALIZE BLANKE ENGINE

-- in main.lua:
require('blanke.Blanke')

function love.load()
	BlankE.init()
end

--- THINGS TO KNOW

-- 1) do NOT create objects outside of functions
-- WRONG:
main_camera = View()
function state0:enter()

end

-- BETTER:
main_camera = nil
function state0:enter()
	main_camera = View()
end

-- possible init options
Blanke.init(first_state) -- first_state: can be string or object

--[[
 ###  #######     #     ####### ###### 
#        #       # #       #    #      
 ###     #      #   #      #    #####  
    #    #     #######     #    #      
 ###     #    #       #    #    ###### 

State
]]

-- init code generated by IDE
BlankE.addClassType(name, "State")

-- methods
-- Ex: function myState:enter(arg) end
load()				-- run only first time state is loaded
enter(previous)		-- run every time state is loaded. previous = prev state
leave()				-- run every time state is left for another.
update(dt)
draw()

-- loading a state
State.switch(name)	-- name can be string or State object. If empty, it will just clear the current state.


--[[
###### #   #  ####### ##### ####### #     # 
#      ##  #     #      #      #     #   #  
#####  # # #     #      #      #      # #   
#      #  ##     #      #      #       #    
###### #   #     #    #####    #       #    

Entity
	game object that can have hitboxes/collisions and sprite animations
	collisions use HardonCollider
]]

-- init code generated by IDE
BlankE.addClassType("entity_name", "Entity")

-- instance properties
str sprite_index
num	sprite_width, sprite_height
num sprite_angle					-- in degrees
num sprite_xscale, sprite_yscale	-- 1 = normal scaling, -1 = flip
num sprite_xoffset, sprite_yoffset
num sprite_xshear, sprite_yshear
num sprite_color[r, g, b]			-- blend color for sprite. default = 255(white)
num sprite_alpha					-- default = 255
num sprite_speed					-- default = 1
num sprite_frame					-- TODO: doesn't work

num direction						-- in degrees
num friction
num gravity
num gravity_direction				-- in degrees. 0 = right, 90 = down, default = 90
num hspeed, vspeed
num speed 							-- best used with 'direction'
num xprevious, yprevious			-- location during last update loop
num xstart, ystart					-- location when object is first created. not always 0,0

{} net_sync_vars					-- variables to be synced by the Net library
bool show_debug

-- overridable methods
preUpdate(dt)
update(dt)							-- caution: controls all physics/motion/position variables
postUpdate(dt)
preDraw()
draw()								-- caution: controls sprite, animation
postDraw()

-- regular methods
debugSprite()						-- green: call during drawing (ex. state:draw)
debugCollision()					-- red: shows hitboxes
setSpriteIndex(str index)			
addAnimation{...}					--[[
	name = str
	image = str 					-- name of asset (ex. bob_stand, bob_walk)
	frames = {...}					-- {'1-2', 1} means columns 1-2 and row 1
	frame_size = {width, height}	-- {32,32} means each frame is 32 by 32
	speed = float					-- 0.1 smaller = faster
]]
addShape(...)						--[[
	name - str
	shape - str rectangle, circle, polygon, point
	dimensions - {...}
		- rectangle {left, top, width, height}
		- circle {center_x, center_y, radius}
	}
]]
setMainShape(name)
removeShape(name)					-- disables a shape. it is still in the shapes table however and will be replaced using addShape(same_name)
distance_point(x ,y)				-- entity origin distance from point
move_towards_point(x, y, speed)		-- sets direction and speed vars
contains_point(x, y)				-- checks if a point is inside the sprite (not hitboxes)

-- special collision methods
func onCollision{name}
func collisionStopX()
func collisionStopY()

-- platformer collisions example
function entity0:init()
	self.gravity = 30
	self.can_jump = true
	self.k_left = Input('left', 'a')
	self.k_right = Input('right', 'd')
	self.k_jump = Input('up', 'w')

	self:addShape("main", "rectangle", {0, 0, 32, 32})		-- rectangle of whole players body
	self:addShape("jump_box", "rectangle", {4, 30, 24, 2})	-- rectangle at players feet
	self:setMainShape("main")								-- dont forget this! Used to figure out where to place the sprite
end

function entity0:update(dt)
	self.onCollision["main"] = function(other, sep_vector)	-- other: other hitbox in collision
		if other.tag == "ground" then
			-- ceiling collision
            if sep_vector.y > 0 and self.vspeed < 0 then
                self:collisionStopY()
            end
            -- horizontal collision
            if math.abs(sep_vector.x) > 0 then
                self:collisionStopX() 
            end
		end
	end

	self.onCollision["jump_box"] = function(other, sep_vector)
        if other.tag == "ground" and sep_vector.y < 0 then
            -- floor collision
            self.can_jump = true 
        	self:collisionStopY()
        end 
    end

    if self.k_right() and not self.k_left() then
    	self.hspeed = 180
    end

    if self.k_left() and not self.k_right() then
    	self.hspeed = 180
    end

    if self.k_up() then
    	self:jump()
    end
end

function entity0:jump()
	if self.can_jump then
        self.vspeed = -700
        self.can_jump = false
    end	
end

--[[
#     # ##### ###### #      # 
#     #   #   #      #      # 
 #   #    #   #####  #      # 
  # #     #   #      #  ##  # 
   #    ##### ###### ##    ## 

View
	extension of HUMP camera
]]

-- instance properties
bool disabled
Entity follow_entity		-- entity for view to follow

num follow_x, follow_y 		-- better to use moveToPosition()
num offset_x, offset_y		
str motion_type 			-- none, linear, smooth
num speed 					-- = 1
num max_distance			-- = 0

num angle 					-- default: 0 degrees
num rot_speed				-- angle rotation speed
str rot_type				-- none, damped
num scale_x, scale_y		-- = 1, stretch/squeeze view
num zoom_speed				-- = .5
str zoom_type				-- none, damped

num port_x, port_y			-- uses love2d Scissor to crop view
num port_width, port_height -- uses love2d Scissor to crop view
bool noclip					-- HUMP attach option. no idea what it does

num shake_x, shake_y		-- = 0
num shake_intensity			-- = 7
num shake_falloff 			-- = 2.5
str shake_type 				-- smooth, rigid

bool draggable				-- drag the camera around using mouse_position
Input drag_input			-- input that toggles whether camera is being dragged

-- methods
position()					-- returns camera position
follow(Entity)				-- follows an Entity
moveTo(Entity) 				-- camera smoothly/linearly moves to entity position
snapTo(Entity)				-- camera immediately moves to entity
moveToPosition(x,y)			
snapToPosition(x,y)
rotateTo(angle)
zoom(scale_x, [scale_y])	-- if only scale_x is supplied, scale_y is set to scale_x
mousePosition()				-- get mouse position relative to world
shake(x, [y])				-- sets shake_x
squeezeH(amt)				-- similar to scale_x except view is centered
attach()					-- set the camera for drawing
detach()					-- unset camera for drawing
draw(draw_function)			-- wraps draw_function in attach/detach methods

--[[
##### #     #      #      #####  ###### 
  #   ##   ##     # #    #       #      
  #   ### ###    #   #   # ####  #####  
  #   #  #  #   #######  #     # #      
##### #     #  #       #  #####  ###### 

Image
]]

-- instance properties
num x, y 					-- position for draw()
num angle 					-- degrees
num xscale, yscale 			-- = 1
							-- xscale = -1 to flip horizontally
							-- yscale = -1 to flip vertically
num xoffset, yoffset 		
num color{r,g,b}			-- = 255, blend color
num alpha 					-- = 255, opacity
num orig_width 				-- original width of image (before scaling)
num orig_height
num width, height 			-- width/height including scaling

-- methods
draw()
setWidth(width)
setHeight(height)
setSize(width, height)
chop(width, height)			-- chops image into smaller images of width/height
crop(x, y, w, h)			-- obvious

--[[
##### #   #  ####  #     # ####### 
  #   ##  #  #   # #     #    #    
  #   # # #  ####  #     #    #    
  #   #  ##  #     #     #    #    
##### #   #  #      #####     #    

Input
]]

Input(...)					--[[ constructor containing tracked inputs
Keyboard
	a, b, c, 1, 2, 3...
	!, ", #, &...
	space, backspace, return 		return is also enter
	up, down, left, right
	home, end, pageup, pagedown
	insert, tab, clear
	f1, f2, f3...
	numlock, capslock, scrolllock
	lshift, rshift
	rctrl, lctrl, ralt, lalt
	rgui, lgui						Command/Windows key
	menu						
	application						windows menu key
	mode 							?

Numpad
	kp0, kp1...				number
	kp. kp, kp+
	kpenter

	https://love2d.org/wiki/KeyConstant

Mouse
	mouse.1		left mouse button
	mouse.2		middle mouse button
	mouse.3 	right mouse button

Mouse Wheel
	wheel.up
	wheel.down
	wheel.right	very rare
	wheel.left	also very rare lol

Region			mouse click in a region
	WIP
]]

-- usage
k_left = Input('left', 'a')
if k_left() then
	hspeed = -125
end

--[[
 ###    ##### ###### #   #  ###### 
#      #      #      ##  #  #      
 ###   #      #####  # # #  #####  
    #  #      #      #  ##  #      
 ###    ##### ###### #   #  ###### 

Scene
	To create a Scene in the IDE just type 
		my_scene = Scene("mylevel")
	as if it already existed. A blank scene will be created.
]]

Scene(scene_name)							-- initialize a scene as scene_name.json

-- instance methods
addEntity(Entity)
addTile(image_name, x, y, crop_options)		--[[
	crop_options - {x, y, width, height}
]]
getTile(x, y, layer, img_name)				-- returns list of tile_data?
getTileImage(x, y, layer, img_name)			-- same as geTTile but returns list of Image()
removeTile(x, y, layer, img_name)
removeHitboxAtPoint(x, y, layer)
getList(object_type)						-- object_type: 'entity', 'tile', 'hitbox'
getEntity(classname, [layer_name])
draw()

-- json format
{
	"data": {
		"layer0": {
			"tile": [
				{x, y, img_name, crop:{x, y, img_name, width, height}},
				...
			],
			"hitbox": [
				{name, points:[10,20,30,50,...]},
				...
			],
			"entity": [
				?
			]
		}
	},
	"order": {
		"layers": ["layer0","layer1"...],
	}
}

--[[
#####   #####      #     #      #
#    #  #   #     # #    #      #
#    #  ####     #   #   #      #
#    #  #   #   #######  #  ##  #
#####   #    # #       # ##    ##

Draw
]]

-- class properties
num[4] color 						-- {r, g, b, a} used for ALL Draw operations
num[4] reset_color					-- {255, 255, 255, 255} (white) : used in resetColor()
num[4] 	red 
		pink
		purple
		indigo
		blue
		green
		yellow
		orange
		brown
		grey 
		black 
		white 
		black2 						-- lighter black
		white2 						-- eggshell white :)

-- class methods
setBackgroundColor(r, g, b, a)
setColor(r, g, b, a)				
resetColor()						-- color = reset_color
-- shapes
point(x, y, ...)					-- also takes in a table							
points								-- the same as point()
line(x1, y1, x2, y2)				
rect(mode, x, y, width, height)		-- mode = "line"/"fill"
circle(mode, x, y, radius)
polygon(mode, x1, y2, x2, y2, ...)
text(text, x, y, rotation, scale_x, scale_y, offset_x, offset_y)
									-- rotation in radians

--[[
####### ##### #     #  ###### #####
   #      #   ##   ##  #      #   #
   #      #   ### ###  #####  ####
   #      #   #  #  #  #      #   #
   #    ##### #     #  ###### #    #

Timer
]]

-- all time units are in seconds for Timer

-- constructor
Timer([duration])						-- in seconds

-- instance properties
int duration							-- 0s
bool disable_on_all_called				-- true. The timer will stop running once every supplied function is called
int time 								-- elapsed time in seconds

-- instance methods
before(function, [delay])				-- starts immediately unless delay is supplied
every(function, [interval])				-- interval=1 , function happens on every interal
after(function, [delay])				-- happens after `duration` supplied to constructor with optional delay
start()									-- MUST BE CALLED TO START THE TIMER. DO NOT FORGET THIS OR YOU WILL GO NUTS

-- example: have an 'enemy' entity shoot a laser every 2 seconds
function enemy:shootLaser()
	...
end

function enemy:spawn()
	self.shoot_timer = Timer()
	self.shoot_timer:every(self.shootLaser, 2):start()
end

--[[
###### ###### ###### ######   ##### #######
#      #      #      #       #         #
#####  #####  #####  #####   #         #
#      #      #      #       #         #
###### #      #      ######   #####    #

Effect
]]

-- Creating a new shader effect
EffectManager.new{name, params, effect, vertex, shader, warp_effect}
--[[
	name: name of effect
	params: list of variables that can be sent to shader
		table (vec2, vec3, vec4)
		number
		boolean (converted to 1/0)
	effect: string containing pixel shader code
	vertex: string containing vertex shader code
	shader: completely custom shader code (not wrapped in built-in code)
	warp_effect: if the effect is a warp effect (default: false)

-- Shader string if 'shader' arg is not supplied: 

/* From glfx.js : https://github.com/evanw/glfx.js */
float random(vec2 scale, vec2 gl_FragCoord, float seed) {
	/* use the fragment position for a different seed per-pixel */
	return fract(sin(dot(gl_FragCoord + seed, scale)) * 43758.5453 + seed);
}

#ifdef VERTEX
	vec4 position(mat4 transform_projection, vec4 vertex_position) {
 		<-- VERTEX CODE --> 
		return transform_projection * vertex_position;
	}
#endif

#ifdef PIXEL
	vec4 effect(vec4 in_color, Image texture, vec2 texCoord, vec2 screen_coords){
		vec4 pixel = Texel(texture, texCoord);
		<-- PIXEL CODE -->
		return pixel * in_color;
	}
#endif

-- If warp_effect is true, <-- PIXEL CODE --> is also wrapped in this:

		vec2 coord =  texCoord * texSize;
		<-- PIXEL CODE -->
		gl_FragColor = texture2D(texture, coord / texSize);
		vec2 clampedCoord = clamp(coord, vec2(0.0), texSize);
		if (coord != clampedCoord) {
			gl_FragColor.a *= max(0.0, 1.0 - length(coord - clampedCoord));
		}

Most GLSL code should work as some keywords are converted:
	float			--> number
	sampler2D		--> Image
	uniform			--> extern
	texture2D		--> Texel
	gl_FragColor	--> pixel
	gl_FragCoord.xy --> screen_coords
These are converted in vertex/pixel/shader code as well.
]]		

-- Using a shader effect
my_effect = Effect(name)
--[[
Built-in effects and their params:
	chroma shift
		num angle = 0	(degrees)
		num radius = 4
		vec2 direction = {0, 0}
	zoom blur
		vec2 center = {0, 0}
		num strength = 0.3
	warp sphere
		num radius = 50
		num strength = -2
		vec2 center = {0, 0}
	grayscale
		num factor = 1
]]

-- instance methods
send(var_name, value)		-- send a parameter to the shader
draw(func)					-- draw shader and affect any draw operations in func()

-- Example:
function state:enter()
	my_effect = Effect("zoom blur")
end

function state:draw()
	my_effect:send("center", {mouse_x, mouse_y})
	my_effect:draw(function()
		my_scene:draw()
	end)
end

--[[
#     # ####### ##### #
#     #    #      #   #
#     #    #      #   #
#     #    #      #   #
 #####     #    ##### #######

Util
]]

-- lone methods
bool ifndef(var, default)
num[3] hex2rgb(hex)

num decimal_places(num)			-- number of dec places in float
num clamp(x, min, max)
num lerp(a, b, amt)
num randRange(min, max)
num sinusoidal(min, max, speed, start_offset)

num bitmask4(map_table, tile_value, x, y)	-- https://gamedevelopment.tutsplus.com/tutorials/how-to-use-tile-bitmasking-to-auto-tile-your-level-layouts--cms-25673
num bitmask8(map_table, tile_value, x, y)	-- untested

str basename(str)
str dirname(str)
str extname(str)

-- STRING
replaceAt(pos, new_str)
starts(str)
ends(str)
split(sep_str)
contains(str)
trim()
at(num)

-- TABLE
find(t, value)
hasValue(t, value)
copy(t)
toNumber(t)
len(t)
forEach(t, func)

-- MATH
round(num, places)

--[[
#   #  ###### #######
##  #  #         #
# # #  #####     #
#  ##  #         #
#   #  ######    #

Net 
]]

-- class methods
join([address], [port])				-- address = "localhost", port = 12345
disconnect()
send(data)
--[[ to send an event
	Net.send({
		type="netevent",
		event="object.sploosh",
		info={
			bob = {1,2,"oatmeal"}
		}
	})
]]
getPopulation()						-- get number of clients connected (including self)
draw([classname])					-- draw objects synced through network, or just a certain class
addObject(obj)						-- add an object to be synced with other clients
--[[
> optional obj properties
	net_sync_vars = {}				-- table containing the names of properties to sync ('x','hspeed','walk_speed','sprite_xcsale')

> this method adds the netSync method to the object
	obj:netSync("x","y","sprite_color") 	-- used to manually sync an object (use wisely)
]]

-- callback methods
onReady()
onEvent(data)