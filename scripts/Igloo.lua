BlankE.addClassType("Igloo", "Entity")

function Igloo:init(from_outside)
	self.img_igloo_back = Image("in_igloo_back")
	self.img_igloo_outline = Image("in_igloo_outline")

	self.img_igloo_back.x = self.x
	self.img_igloo_back.y = self.y

	self:addShape("bottom", "rectangle", {
		game_width,
		600 + 33,
		game_width,
		33
	}, "ground")

	self:addShape("wall", "rectangle", {225, 0, 33, 600}, "ground")

	self.main_penguin = Penguin()
	self.main_penguin.x = self.img_igloo_back.x + (self.img_igloo_back.width / 2)
	self.main_penguin.y = 284
	if from_outside then
		self.main_penguin.x = game_width - 120 - 32
		self.main_penguin.sprite_xscale = -1
	end
	self.main_penguin.sprite_yoffset = -24
end

function Igloo:update(dt)
	self.main_penguin.can_jump = false
	self.main_penguin.walk_speed = 360

	if self.main_penguin.x > game_width - 120 then
		State.transition(playState, 'circle-in')
	end
end

function Igloo:draw()
	self.img_igloo_back:draw()

	Draw.translate(-self.main_penguin.x, -self.main_penguin.y)
	Draw.scale(2)
	self.main_penguin:draw()
	Draw.reset()

	self.img_igloo_outline:draw()

	Draw.setColor('red')
	Draw.circle('fill', game_width - 120, self.main_penguin.y, 10)

	self.main_penguin:debugCollision()
	self:debugCollision()
end