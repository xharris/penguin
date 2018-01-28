BlankE.addClassType("Ground", "Entity")

function Ground:init()
	self:addShape("ground", "rectangle", {32, 32, 32, 32}, "ground")
	self.img_tile = self.parent:getTileImage(self.x, self.y, nil, "ground")
	self.img_tile.x = self.x
	self.img_tile.y = self.y
	
	self.fragged = false
	self.img_frags = {}
end

function Ground:update(dt)
	local wall_x = 0
	if wall then wall_x = wall.x end

	if wall_x > self.x and not self.fragged then
		self.parent:removeTile(self.x, self.y, nil, "ground")

		if wall_x > self.x + 32 then self:removeShape("ground") end
		self.fragged = true
		self.img_frags = self.img_tile:chop(32/5,32/5)

		-- add gravity to images
		table.forEach(self.img_frags, function(f, frag)
			frag.random_g = randRange(2,5)
			frag.gravity = 0
		end)
	end

	-- update broken pieces
	if self.fragged then
		table.forEach(self.img_frags, function(f, frag)
			if wall_x > frag.x + (frag.random_g*5) then
				frag.gravity = frag.gravity + frag.random_g
				frag.y = frag.y + frag.gravity * dt
				frag.x = frag.x - 10 * dt
			end
		end)
	end
end

function Ground:draw()
	if not self.fragged then
		self.img_tile:draw()
	else
		for f, frag in ipairs(self.img_frags) do
			frag:draw()
		end
	end

	if self.scene_show_debug then
		self:debugCollision()
	end
end
