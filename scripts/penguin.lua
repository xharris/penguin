BlankE.addClassType("Penguin", "Entity")

local k_right, k_left, k_up

Penguin.net_sync_vars = {'color','hspeed','sprite_speed','sprite_xscale'}

function Penguin:init()
	self:addAnimation{
		name = 'stand',
		image = 'penguin',
		frames = {1,1},
		frame_size = {32,32}
	}
	self:addAnimation{
		name = 'walk',
		image = 'penguin',
		frames = {'1-2', 1},
		frame_size = {32, 32},
		speed = .1
	}
	self:addAnimation{
		name = 'walk_fill',
		image = 'penguin_filler',
		frames = {'1-2', 1},
		frame_size = {32, 32},
		speed = .1
	}

	-- INPUT
	k_left = Input('left')
	k_right = Input('right')
	k_up = Input('up')

	self.gravity = 30
	self.can_jump = true
	-- random shade of blue
	self.color = hex2rgb(table.random({"#81D4FA", "#4FC3F7", "#29B6F6", "#29B6F6"}))
	self.sprite_yoffset = -16
	self.sprite_xoffset = -16

	self:addShape("main", "rectangle", {0, 0, 32, 32})		-- rectangle of whole players body
	self:addShape("jump_box", "rectangle", {4, 30, 24, 2})	-- rectangle at players feet
	self:setMainShape("main")

	--self.show_debug = true
end

function Penguin:update(dt)
	local behind_wall = true
	if not wall or self.x > wall.x then
		behind_wall = false
	end
	self.onCollision["main"] = function(other, sep_vector)	-- other: other hitbox in collision
		if not behind_wall and other.tag == "ground" then
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
        if not behind_wall and other.tag == "ground" and sep_vector.y < 0 then
            -- floor collision
            self.can_jump = true 
        	self:collisionStopY()
			self:netSync("vspeed","x","y")
        end 
    end

	-- left/right movement
	if not self.net_object then
		self.hspeed = 0
		if k_right() then
			self.hspeed = 180
			self.sprite_speed = 2
		end
		if k_left() then
			self.hspeed = -180
			self.sprite_speed = 2
		end

		if not k_left() and not k_right() then
			self.sprite_speed = 0
		end

		if k_up() then
			self:jump()
		end
	else
		--Debug.log("hspeed:",self.hspeed)
	end

	if self.hspeed > 0 then
		self.sprite_xscale = 1
	elseif self.hspeed < 0 then
		self.sprite_xscale = -1
	end

	if self.hspeed == 0 then
		self.sprite_frame = 1
	end
end

function Penguin:jump()
	if self.can_jump then
		self.vspeed = -700
		self:netSync("vspeed","x","y")
		self.can_jump = false
	end
end

function Penguin:draw()
	self.sprite_color = Draw.white
	self:drawSprite('walk')
	self.sprite_color = self.color
	self:drawSprite('walk_fill')
end