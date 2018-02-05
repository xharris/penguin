BlankE.addClassType("OutfitMenu", "Entity")

function OutfitMenu:init(penguin_ref)
	self.penguin = penguin_ref
	self.penguin.hspeed = 0
	self.penguin.pause = true

	self.menu_highlight = 1
end

function OutfitMenu:update(dt)
	if Input.global('confirm') then
		Penguin.main_penguin_info.hat = "top"
		self.penguin:setHat("top")
	end
end

function OutfitMenu:draw()
	Draw.rect("fill", self.penguin.x, self.penguin.y, 100, 100)
end