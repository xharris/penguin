BlankE.addClassType("Ground", "Entity")

function Ground:init(x, y, frame)
	self:addShape("ground", "rectangle", {tile_snap, tile_snap, tile_snap, tile_snap}, "ground")
	
	self.x = x
	self.y = y

	self.img_tile = Image("ground"):frame(frame, tile_snap, tile_snap, 1, 1)

	self.img_tile.x = self.x
	self.img_tile.y = self.y
	
	self.fragged = false
	self.img_frags = {}
end

function Ground:update(dt)
	local wall_x = 0
	if wall then wall_x = wall.x end

	if wall_x > self.x and not self.fragged then
		if wall_x > self.x + self.img_tile.width then self:removeShape("ground") end
		self.fragged = true
		self.img_frags = self.img_tile:chop(self.img_tile.width/5,self.img_tile.width/5)

		-- add gravity to images
		table.forEach(self.img_frags, function(f, frag)
			frag.random_g = randRange(2,7)
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
end
	