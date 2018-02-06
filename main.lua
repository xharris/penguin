-- engine
BlankE = require('blanke.Blanke')

function love.load()
	Asset.add('assets/image/')
	Asset.add('assets/hats/','hat')
	Asset.add('assets/levels/')
	Asset.add('scripts/')

	Input.setGlobal('confirm', 'e')
	Input.global_keys['confirm'].can_repeat = false

	UI.color('window_bg', Draw.baby_blue)
	UI.color('window_outline', Draw.blue)
	UI.color('element_bg', Draw.dark_blue)

    BlankE.init('menuState')
end