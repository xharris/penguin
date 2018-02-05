BlankE.addClassType("Igloo", "Entity")

function Igloo:init(from_outside)
	-- setup igloo 
	self.img_igloo_back = Image("in_igloo_back")
	self.img_igloo_outline = Image("in_igloo_outline")

	self.img_igloo_back.x = self.x
	self.img_igloo_back.y = self.y

	self.igloo_exit_x = game_width - 100

	local igloo_bottom = 605
	local igloo_left = 257

	-- igloo hitboxes
	self:addShape("bottom", "rectangle", {
		game_width,
		igloo_bottom + 33,
		game_width,
		33
	}, "ground")
	self:addShape("wall", "rectangle", {igloo_left-16, 0, 32, 600}, "ground")
	self:addShape("closet", "rectangle", {igloo_left+160,igloo_bottom-64,64,64}, "penguin.outfit")

	-- add player and upscale its sprite
	self.main_penguin = Penguin(true)
	self.main_penguin.x = self.img_igloo_back.x + (self.img_igloo_back.width / 2)
	self.main_penguin.y = 284
	if from_outside then
		self.main_penguin.x = self.igloo_exit_x - 5
		self.main_penguin.sprite_xscale = -1
	end
	self.main_penguin.sprite_yoffset = -24

	-- igloo furniture
	self.ent_closet = nil
end

function Igloo:update(dt)
	if not self:hadCollision("closet", "Penguin") and self.ent_closet then
		self.ent_closet:destroy()
		self.ent_closet = nil
	end

	self.onCollision["closet"] = function(other, sep_vector)
		if other.tag:contains("Penguin") and Input.global('confirm') then
			if not self.ent_closet then
				self.ent_closet = OutfitMenu(self.main_penguin)
			end
		end
	end

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

	if self.ent_closet then self.ent_closet:draw() end

	UI.window("label", 20, 20, 100, 100)
	UI.spinbox("hat", {"top", "polar", "pan"}, "polar")
	--self:debugCollision()
end