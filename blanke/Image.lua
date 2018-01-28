local _images = {}
 
Image = Class{
	init = function(self, name)
		self.name = name 

		if type(name) == "string" and assets[name] then
			self.image = assets[name]()
		else
			self.image = love.graphics.newImage(name)
		end
		self.image:setWrap("clampzero","clampzero")

		self.quad = nil
		self.x = 0
		self.y = 0
		self.angle = 0
		self.xscale = 1
		self.yscale = 1
		self.xoffset = 0
		self.yoffset = 0
		self.color = {['r']=255,['g']=255,['b']=255}
		self.alpha = 255

		self.orig_width = self.image:getWidth()
		self.orig_height = self.image:getHeight()
		self.width = self.orig_width
		self.height = self.orig_height
	end,

	-- static: check if an image exists
	exists = function(img_name)
		return (assets[img_name] ~= nil)
	end,

	setWidth = function(self, width)
		self.xscale = width / self.orig_width
		return self
	end,

	setHeight = function(self, height)
		self.yscale = height / self.orig_height
		return self
	end,

	setSize = function(self, width, height)
		self.setWidth(width)
		self.setHeight(height)
	end,

	draw = function(self)
		self.width = self.orig_width * self.xscale
		self.height = self.orig_height * self.yscale

		love.graphics.push()
		love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.alpha)	
		if self.quad then
			love.graphics.draw(self.image, self.quad, self.x, self.y, math.rad(self.angle), self.xscale, self.yscale, self.xoffset, self.yoffset, self.xshear, self.yshear)
		else
			love.graphics.draw(self.image, self.x, self.y, math.rad(self.angle), self.xscale, self.yscale, self.xoffset, self.yoffset, self.xshear, self.yshear)
		end
		love.graphics.pop()
		return self
	end,

    __call = function(self)
    	return self.image
	end,

	-- break up image into pieces
	chop = function(self, piece_w, piece_h)
		piece_w = math.ceil(piece_w)
		piece_h = math.ceil(piece_h)

		local img_list = {}
		local new_quad = love.graphics.newQuad(0,0,piece_w,piece_h, self.image:getDimensions())
		for x=0, self.orig_width, piece_w do
			for y=0, self.orig_height, piece_h do
				if x < self.orig_width or y < self.orig_height then
					local new_image = self:crop(x,y,piece_w,piece_h)
					new_image.x = self.x + x
					new_image.y = self.y + y
					table.insert(img_list, new_image)
				end
			end
		end
		return img_list
	end,

	crop = function(self, x, y, w, h)
		local src_image_data = self.image:getData()
		local dest_image_data = love.image.newImageData(w,h)
		dest_image_data:paste(src_image_data, 0, 0, x, y, w, h)

		return Image(dest_image_data)
	end,
}

return Image