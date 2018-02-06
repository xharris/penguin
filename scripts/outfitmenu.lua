BlankE.addClassType("OutfitMenu", "Entity")

function OutfitMenu:init(penguin_ref)
	self.x = penguin_ref.x
	self.y = penguin_ref.y + 16

	self.penguin = penguin_ref
	self.penguin.hspeed = 0
	self.penguin.pause = true

	self.old_hat = Penguin.main_penguin_info.hat
	self.old_color = Penguin.main_penguin_info.color

	self.show_menu = true
end

function OutfitMenu:draw()
	if self.show_menu then
		UI.window("label", self.x - 50, self.y + 20, 100, 100)
		local status_hat, new_hat = UI.spinbox("hat", Penguin.hats, Penguin.main_penguin_info.hat)
		if status_hat then 
			Penguin.main_penguin_info.hat = new_hat
			self.penguin:setHat(new_hat)
		end
		UI.spinbox("color", {"blue", "red"}, "blue")
		if UI.button("OK") then
			self.show_menu = false
			self.penguin.pause = false
			self:destroy()
		end
	end
end