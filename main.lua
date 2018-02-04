-- engine
BlankE = require('blanke.Blanke')

function love.load()
	Asset.add('assets/image/')
	Asset.add('assets/hats/','hat')
	Asset.add('assets/levels/')
	Asset.add('scripts/')

    BlankE.init('menuState')
end