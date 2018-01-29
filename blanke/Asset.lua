Asset = Class{
	image_ext = {'tif','tiff','gif','jpeg','jpg','jif','jiff','jp2','jpx','j2k','j2c','fpx','png','pcd','pdf'},
	audio_ext = {'pcm','wav','aiff','mp3','aac','ogg','wma','flac','alac','wma'},
	info = {},

	loadScripts = function()
		for a, asset in pairs(Asset.info['script']) do
			if asset.category == 'script' then
				result, chunk = pcall(asset.object)
				if not result then
					error(chunk)
				end
			end
		end
	end,

	add = function(path)
		local asset_ext = extname(path)
		local asset_name = ''
		if asset_ext then 
			asset_name = basename(path):gsub('.'..asset_ext,'')
		else
			asset_name = basename(path)
		end

		-- FOLDER
		if path:ends('/') then
			local files = love.filesystem.getDirectoryItems(path:sub(0,-1))
			for f, file in ipairs(files) do
				Asset.add(path..file)
			end
			return
		end

		-- SCRIPT
		if path:ends('.lua') then
			Asset.info['script'] = ifndef(Asset.info['script'], {})

			local result, chunk
			result, chunk = pcall(love.filesystem.load, path)
			Asset.info['script'][asset_name] = {
				path = path,
				category = 'script',
				object = chunk
			}
			return Asset.get(asset_name)
		end
		-- IMAGE
		if table.hasValue(Asset.image_ext, asset_ext) then
			Asset.info['image'] = ifndef(Asset.info['image'], {})
			
			local image = love.graphics.newImage(path)
			if image then
				Asset.info['image'][asset_name] = {
					path = path,
					category = 'image',
					object = image
				}
				return Asset.get(asset_name)
			end
		end
		-- JSON (scene)
		if path:ends('.json') then
			Asset.info['file'] = ifndef(Asset.info['file'], {})
			
			Asset.info['file'][asset_name] = {
				path = path,
				category = 'file',
				object = love.filesystem.read(path)
			}
			return Asset.get(asset_name)
		end
	end,

	has = function(category, name)
		if Asset.info[category] then
			return (Asset.info[category][name] ~= nil)
		else
			return false
		end
	end,

	getInfo = function(category, name)
		if Asset.has(name) then
			return Asset.info[category][name]
		end
	end,

	get = function(category, name)
		if Asset.has(category, name) then
			return Asset.info[category][name].object
		end
	end,

	image = function(name) return Asset.get('image', name) end,
	script = function(name) return Asset.get('script', name) end,
	file = function(name) return Asset.get('file', name) end
}

return Asset