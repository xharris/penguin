local cos = math.cos
local sin = math.sin
local rad = math.rad

Entity = Class{
	x = 0,
	y = 0,
	net_sync_vars = {'x', 'y'},
	net_excludes = {'^_images$','^_sprites$','^sprite$','previous$','start$','^shapes$','^collision','^onCollision$','^is_net_entity$'},
    _init = function(self, parent)    
    	self.classname = ifndef(self.classname, 'Entity')
    	self._destroyed = false
	    self._images = {}		
		self._sprites = {} 			-- is actually the animations
		self.sprite = nil			-- currently active animation
		self.pause = false
		self.show_debug = false
		self.scene_show_debug = false

		-- x and y coordinate of sprite
		self.x = Entity.x
		self.y = Entity.y
		self.parent = parent

		Entity.x = 0
		Entity.y = 0

		-- sprite/animation variables
		self._call_sprite_update = {}
		self._sprite_prev = '' 		-- previously used sprite
		self.sprite_index = ''		-- string index of the current sprite
		self.sprite_width = 0		-- readonly
		self.sprite_height = 0		-- readonly
		self.sprite_angle = 0		-- angle of sprite in degrees
		self.sprite_xscale = 1	
		self.sprite_yscale = 1
		self.sprite_xoffset = 0
		self.sprite_yoffset = 0
		self.sprite_xshear = 0
		self.sprite_yshear = 0
		self.sprite_color = {255,255,255}
		self.sprite_alpha = 255
		self.sprite_speed = 1
		self.sprite_frame = 0

		-- movement variables
		self.direction = 0
		self.friction = 0
		self.gravity = 0
		self.gravity_direction = 90
		self.hspeed = 0
		self.vspeed = 0
		self.speed = 0
		self.xprevious = 0
		self.yprevious = 0
		self.xstart = self.x
		self.ystart = self.y

		-- collision
		self.shapes = {}
		self._main_shape = ''
		self.collisionStop = nil
		self.collisionStopX = nil
		self.collisionStopY = nil	

		self.onCollision = {["*"] = function() end}
    	_addGameObject('entity', self)
    end,

    destroy = function(self)
    	-- destroy hitboxes
    	for s, shape in pairs(self.shapes) do
    		shape:destroy()
    	end

    	self._destroyed = true
    	_destroyGameObject('entity', self)
    end,

    _update = function(self, dt)
    	if self._destroyed then return end

		-- bootstrap sprite:goToFrame()
		if not self.sprite then
			self.sprite = {}
			self.sprite.gotoFrame = function() end
		end

		if self.update then
			self:update(dt)
		end	
    	if self._destroyed then return end -- call again in case entity is destroyed during update

		if not self.pause then
			if self.sprite ~= nil and self.sprite.update ~= nil then
				self.sprite:update(self.sprite_speed*dt)
			end
			
			-- clear sprite update call list
			for sprite_name, val in pairs(self._call_sprite_update) do
				self._sprites[sprite_name]:update(self.sprite_speed*dt)
				self._call_sprite_update[sprite_name] = nil
			end
		end

		-- x/y extra coordinates
		if self.xstart == 0 then
			self.xstart = self.x
		end
		if self.ystart == 0 then
			self.ystart = self.y
		end

		-- check for collisions
		if not self.pause then
			-- calculate speed/direction
			local speedx, speedy = 0,0
			if speed ~= 0 then
				speedx = self.speed * cos(rad(self.direction))
				speedy = self.speed * sin(rad(self.direction))
			end

			-- calculate gravity/gravity_direction
			local gravx, gravy = 0,0
			if self.gravity ~= 0 then
				gravx = self.gravity * cos(rad(self.gravity_direction))
				gravy = self.gravity * sin(rad(self.gravity_direction))
			end
	
			-- add gravity to hspeed/vspeed
			if gravx ~= 0 then self.hspeed = self.hspeed + gravx end
			if gravy ~= 0 then self.vspeed = self.vspeed + gravy end

			-- move shapes if the x/y is different
			if self.xprevious ~= self.x or self.yprevious ~= self.y then
				for s, shape in pairs(self.shapes) do
					-- account for x/y offset?
					shape:moveTo(self.x, self.y)
				end
			end
        
			self.xprevious = self.x
			self.yprevious = self.y

			local dx = self.hspeed + speedx
			local dy = self.vspeed + speedy

			-- move all shapes
			for s, shape in pairs(self.shapes) do
				shape:move(dx*dt, dy*dt)
			end

			local _main_shape = self.shapes[self._main_shape]
			
			for name, fn in pairs(self.onCollision) do
				-- make sure it actually exists
				if self.shapes[name] ~= nil and self.shapes[name]._enabled then
					local obj_shape = self.shapes[name]:getHCShape()

					local collisions = HC.neighbors(obj_shape)
					for other in pairs(collisions) do
					    local collides, dx, dy = obj_shape:collidesWith(other)
					    if collides then
		                	local separating_vector = {['x']=dx, ['y']=dy}
		                	
							-- collision action functions
							self.collisionStopX = function(self)
								for name, shape in pairs(self.shapes) do
									shape:move(separating_vector.x, 0)
								end
					            self.hspeed = 0
					            speedx = 0
					            dx = 0
							end

							self.collisionStopY = function(self)
								for name, shape in pairs(self.shapes) do
									shape:move(0, separating_vector.y)
								end
					            self.vspeed = 0
					            speedy = 0
					            dy = 0
							end
							
							self.collisionStop = function(self)
								self:collisionStopX()
								self:collisionStopY()
							end

							-- call users collision callback if it exists
							fn(other, separating_vector)
						end
					end
				end
			end

			-- set position of sprite
			if self.shapes[self._main_shape] ~= nil and self.shapes[self._main_shape]._enabled then
				self.x, self.y = self.shapes[self._main_shape]:center()
			else
				self.x = self.x + dx*dt
				self.y = self.y + dy*dt
			end

			if self.speed > 0 then
				self.speed = self.speed - (self.speed * self.friction)*dt
			end
		end

		self:netSync()

		return self
	end,

	getCollisions = function(self, shape_name)
		if self.shapes[shape_name] then
			local hc_shape = self.shapes[shape_name]:getHCShape()
			return HC.collisions(self.shapes[shape_name])
		end
		return {}
	end,

	debugSprite = function(self, sprite_index)
		local sx = -self.sprite_xoffset
		local sy = -self.sprite_yoffset

		love.graphics.push("all")
		love.graphics.translate(self.x, self.y)
		love.graphics.rotate(math.rad(self.sprite_angle))
		love.graphics.shear(self.sprite_xshear, self.sprite_yshear)
		love.graphics.scale(self.sprite_xscale, self.sprite_yscale)

		-- draw sprite outline
		love.graphics.setColor(0,255,0,255*(2/3))
		if self._sprites[sprite_index] then
			local sprite_width, sprite_height = self:getSpriteDims(sprite_index)
			love.graphics.rectangle("line", -sx, -sy, sprite_width, sprite_height)
		end
		-- draw origin point
		love.graphics.circle("line", 0, 0, 2)

		love.graphics.pop()
		return self
	end,

	debugCollision = function(self)
		-- draw collision shapes
		for s, shape in pairs(self.shapes) do
			shape:draw("line")
		end
		return self
	end,

	setSpriteIndex = function(self, index)
		if index == '' or index == nil then
			self.sprite_index = ''
			self.sprite = nil
		else
			assert(self._sprites[index], "Animation not found: \'"..index.."\'")

			self.sprite_index = index
			self.sprite = self._sprites[self.sprite_index]

			if self._sprite_prev ~= self.sprite_index then
				self.sprite_width, self.sprite_height = self:getSpriteDims(self.sprite_index)
				self._sprite_prev = self.sprite_index
			end
		end
		return self
	end,

	getSpriteDims = function(self, sprite_index)
		return self._sprites[sprite_index]:getDimensions()
	end,

	drawSprite = function(self, sprite_index)
		sprite_index = ifndef(sprite_index, self.sprite_index)
		sprite = self._sprites[sprite_index]

		if self.show_debug or self.scene_show_debug then self:debugCollision() end

		if sprite ~= nil then
			self._call_sprite_update[sprite_index] = true
			-- draw current sprite (image, x,y, angle, sx, sy, ox, oy, kx, ky) s=scale, o=origin, k=shear
			local img = self._images[sprite_index]
			Draw.push('all')

			if self.show_debug or self.scene_show_debug then self:debugSprite(self.sprite_index) end

			love.graphics.setColor(self.sprite_color[1], self.sprite_color[2], self.sprite_color[3], ifndef(self.sprite_color[4], self.sprite_alpha))
			
			-- is it an Animation or an Image
			if sprite.update ~= nil then
				sprite:draw(img(), self.x, self.y, math.rad(self.sprite_angle), self.sprite_xscale, self.sprite_yscale, -self.sprite_xoffset, -self.sprite_yoffset, self.sprite_xshear, self.sprite_yshear)
			elseif img then
				love.graphics.draw(img(), self.x, self.y, math.rad(self.sprite_angle), self.sprite_xscale, self.sprite_yscale, -self.sprite_xoffset, -self.sprite_yoffset, self.sprite_xshear, self.sprite_yshear)
			end
			Draw.pop()
		else
			self.sprite_width = 0
			self.sprite_height = 0
		end
	end,

	draw = function(self)
		if self._destroyed then return end

		if self.preDraw then
			self:preDraw()
		end

		self:drawSprite()

		if self.postDraw then
			self:postDraw()
		end
		return self
	end,

	addAnimation = function(self, args)
		-- main args
		local ani_name = args.name
		local name = args.image
		local frames = ifndef(args.frames, {1,1})
		-- other args
		local offset = ifndef(args.offset, {0,0})
		local left = offset[1]
		local top = offset[2]
		local border = ifndef(args.border, 0)
		local speed = ifndef(args.speed, 0.1)

		if Image.exists(name) then
			local image = Image(name)
			local frame_size = ifndef(args.frame_size, {image.width, image.height})
		    local grid = anim8.newGrid(frame_size[1], frame_size[2], image.width, image.height, left, top, border)
			local sprite = anim8.newAnimation(grid(unpack(frames)), speed)

			self._images[ani_name] = image
			self._sprites[ani_name] = sprite	
		end
		return self
	end,

	-- add a collision shape
	-- str shape: rectangle, polygon, circle, point
	-- str name: reference name of shape
	addShape = function(self, name, shape, args, tag)
		tag = ifndef(tag, self.classname..'.'..name)
		local new_hitbox = Hitbox(shape, args, tag, 0, 0)
		new_hitbox:setParent(self)
		new_hitbox:moveTo(self.x, self.y)
		self.shapes[name] = new_hitbox
		return self
	end,

	-- remove a collision shape
	removeShape = function(self, name)
		if self.shapes[name] ~= nil then
			self.shapes[name]:disable()
		end
		return self
	end,

	-- the shape that the sprite will follow
	setMainShape = function(self, name) 
		if self.shapes[name] ~= nil then
			self._main_shape = name
		end 
		return self
	end,

	distance_point = function(self, x, y)
		return math.sqrt((x - self.x)^2 + (y - self.y)^2)
	end,

	-- other : Entity object
	-- returns distance between center of self and other object in pixels
	distance = function(self, other)
		return self:distance(other.x, other.y)
	end,

	-- self direction and speed will be set towards the given point
	-- this method will not set the speed back to 0 
	move_towards_point = function(self, x, y, speed)
		self.direction = math.deg(math.atan2(y - self.y, x - self.x))
		self.speed = speed
		return self
	end,
    
    -- checks if the point is inside the current sprite
    contains_point = function(self, x, y)
        if x >= self.x and y >= self.y and x < self.x + self.sprite_width and  y < self.y + self.sprite_height then
            return true
        end
        return false
    end
}

return Entity