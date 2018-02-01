BlankE.addClassType("Ground", "Entity")

function Ground:init(x, y, frame)
	self:addShape("ground", "rectangle", {tile_snap, tile_snap, tile_snap, tile_snap}, "ground")
	
	self.x = x
	self.y = y

	if frame < 0 then
		frame = 1
		self.img_tile = Image("ground"):frame(frame, tile_snap, tile_snap, 1, 1)
		self.img_tile.alpha = 0
	else
		self.img_tile = Image("ground"):frame(frame, tile_snap, tile_snap, 1, 1)
	end

	self.img_tile.x = self.x
	self.img_tile.y = self.y
	
	self.fragged = false
end

function Ground:update(dt)
	local wall_x = 0
	if wall then wall_x = wall.x end

	if wall_x > self.x + self.img_tile.width then self:removeShape("ground") end
	if wall_x > self.x and not self.fragged then
		self.fragged = true
		FragImage(self.img_tile)
	end
end

function Ground:draw()
	if not self.fragged then
		self.img_tile:draw()
	end
end
	