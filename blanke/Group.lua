local _views = {}
Group = Class{
	init = function (self)
		self.children = {}
	end,

	add = function(self, ent)
		table.insert(self.children, ent)
	end,

	remove = function(self, i)
		self.children[i] = nil
	end,

	call = function(self, func)
		for i_c, c in ipairs(self.children) do
			func(c)
		end
	end,

	-- for Entity only
	closest_point = function(self, x, y)
		local min_dist, min_ent

		for i_e, e in ipairs(self.children) do
			local dist = e:distance_point(x, y)
			if dist < min_dist then
				min_dist = dist
				min_ent = e
			end
		end

		return min_ent
	end,

	closest = function(self, ent)
		return self:closest_point(ent.x, ent.y)
	end,
}