BlankE.addClassType("FragImage", "Entity")

frag_images = {}

function FragImage:init(image)
	self.img_frags = image:chop(image.width/5,image.width/5)

	-- add gravity to images
	table.forEach(self.img_frags, function(f, frag)
		frag.random_g = randRange(7,10)
		frag.gravity = 0
	end)

	table.insert(frag_images, self)
end

function FragImage:update(dt)	
	local wall_x = 0
	if wall then wall_x = wall.x end

	table.forEach(self.img_frags, function(f, frag)
		if wall_x > frag.x + (frag.random_g*5) then
			frag.gravity = frag.gravity + frag.random_g
			frag.y = frag.y + frag.gravity * dt
			frag.x = frag.x - 12 * dt
		end
	end)
end

function FragImage:draw()
	for f, frag in ipairs(self.img_frags) do
		frag:draw()
	end
end

FragImage.drawAll = function()
	for f, frag_image in ipairs(frag_images) do
		frag_image:draw()
	end
end