BlankE.addClassType("OutfitMenu", "Entity")

function OutfitMenu:init(penguin_ref)
	self.x = penguin_ref.x
	self.y = penguin_ref.y + 16

	self.penguin = penguin_ref
	self.penguin.hspeed = 0
	self.penguin.pause = true

	self.old_hat = Penguin.main_penguin_info.hat
	self.old_color = Penguin.main_penguin_info.color

	self.menu_highlight = 1
end

function OutfitMenu:update(dt)
	if self.menu_highlight == 3 and Input.global('confirm') then
		Penguin.main_penguin_info.hat = "top"
		self.penguin:setHat("top")
	end
end

function OutfitMenu:draw()
	Draw.setColor('white')
	Draw.rect("fill", self.x - 50, self.y + 20, 100, 100)
end