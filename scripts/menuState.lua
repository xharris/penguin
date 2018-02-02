BlankE.addClassType("menuState", "State")

ent_igloo = nil
main_penguin = nil

k_pause = nil

function menuState:enter(previous)
	k_pause = Input('p')

	self.background_color = Draw.black
	ent_igloo = Igloo(previous == 'playState')
end

function menuState:update(dt)
	if k_pause() and not BlankE.pause then
		BlankE.pause = true
	end	
end

function menuState:draw()
	ent_igloo:draw()

	Debug.draw()
end