BlankE.addClassType("Penguin", "Entity")

local k_right, k_left, k_up

Penguin.main_penguin_info = nil
Penguin.net_sync_vars = {'color','hspeed','sprite_speed','sprite_xscale','color','hat'}

function Penguin:init(is_main_player)
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
	self.walk_speed = 180
	-- random shade of blue
	self.sprite_yoffset = -16
	self.sprite_xoffset = -16

	local top, left, right = 7, 0, 14
	self:addShape("main", "rectangle", {left, top, 32-(left+right), 32-(top*2)})		-- rectangle of whole players body
	self:addShape("jump_box", "rectangle", {left, 30, 32-(left+right), 2})	-- rectangle at players feet
	self:setMainShape("main")

	-- initalize player's penguin attributes
	if is_main_player and not Penguin.main_penguin_info then
		local random_hat_name = table.random(Asset.list('image','hat'))

		Penguin.main_penguin_info = {
			color = hex2rgb(table.random({"#81D4FA", "#4FC3F7", "#29B6F6", "#29B6F6"})),
			hat = nil
		}
	end

	self.color = Penguin.main_penguin_info.color
	self:setHat(Penguin.main_penguin_info.hat)
end

function Penguin:setHat(name)
	self.hat = name

	if Image.exists('hat/'..tostring(name)) then
		self.img_hat = Image('hat/'..name)
		local animated = (self.img_hat.width > 32)

		if animated then
			self:addAnimation{
				name = 'hat',
				image = 'hat/'..name,
				frames = {'1-2',1},
				frame_size = {32,32}
			}
		else
			self:addAnimation{
				name = 'hat',
				image = 'hat/'..name
			}
		end
	end
end

function Penguin:onNetUpdate(name, value)
	if name == 'hat' then
		self:setHat(value)
	end
end

function Penguin:update(dt)
	local behind_wall = true
	if not wall or self.x > wall.x then
		behind_wall = false
	end
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
            if not self.can_jump then
				self:netSync("vspeed","x","y")
            end
            self.can_jump = true 
        	self:collisionStopY()
        end 
    end

	-- left/right movement
	if not self.net_object then
		self.hspeed = 0
		if k_right() then
			self.hspeed = self.walk_speed
			self.sprite_speed = 2
		end
		if k_left() then
			self.hspeed = -self.walk_speed
			self.sprite_speed = 2
		end

		if k_up() then
			self:jump()
		end
	end

	-- animation
	if self.hspeed > 0 then
		self.sprite_xscale = 1
	elseif self.hspeed < 0 then
		self.sprite_xscale = -1
	end

	if self.hspeed == 0 then
		self.sprite_speed = 0
		self.sprite_frame = 1
	end

	if self.vspeed ~= 0 then
		self.sprite_speed = 0
		self.sprite_frame = 2
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
	self.sprite['walk'].color = Draw.white
	self.sprite['walk_fill'].color = self.color

	self:drawSprite('walk')
	self:drawSprite('walk_fill')

	-- draw penguin hat
	if self.img_hat then
		local hat_y_offset = -(self.img_hat.height - 32)
		if self.sprite_speed > 0 and self.sprite['walk'].frame == 2 and self.img_hat.width <= 32 then
			hat_y_offset = -(self.img_hat.height - 32) - 1
		end
		self.sprite['hat'].yoffset = hat_y_offset
	end

	self:drawSprite('hat')
end