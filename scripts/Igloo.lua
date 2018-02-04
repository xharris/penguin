BlankE.addClassType("Igloo", "Entity")

function Igloo:init(from_outside)
	self.img_igloo_back = Image("in_igloo_back")
	self.img_igloo_outline = Image("in_igloo_outline")

	self.img_igloo_back.x = self.x
	self.img_igloo_back.y = self.y

	self.igloo_exit_x = game_width - 100

	self:addShape("bottom", "rectangle", {
		game_width,
		605 + 33,
		game_width,
		33
	}, "ground")

	self:addShape("wall", "rectangle", {225, 0, 33, 600}, "ground")

	self.main_penguin = Penguin(true)
	self.main_penguin.x = self.img_igloo_back.x + (self.img_igloo_back.width / 2)
	self.main_penguin.y = 284
	if from_outside then
		self.main_penguin.x = self.igloo_exit_x - 5
		self.main_penguin.sprite_xscale = -1
	end
	self.main_penguin.sprite_yoffset = -24
end

function Igloo:update(dt)
	self.main_penguin.can_jump = false
	self.main_penguin.walk_speed = 360

	if self.main_penguin.x > self.igloo_exit_x then
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
end