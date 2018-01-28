Timer = Class{
	init = function(self, duration)
		self._before = {}					-- when Timer.start is called
		self._every = {}					-- every x seconds while timer is running
		self._after = {}					-- when the timer is over 
		self.time = 0						-- seconds
		self.duration = ifndef(duration,0)	-- seconds
		self.disable_on_all_called = true	-- disable the timer when all functions are called (before, after)

		self._running = false
		self._start_time = 0

		_addGameObject('timer', self)
		return self
	end,

	-- BEFORE, EVERY, AFTER: add functions
	before = function(self, func, delay)
		table.insert(self._before,{
			func=func,
			delay=ifndef(delay,0),
			decimal_places=decimal_places(ifndef(delay,0)),
			called=false,
		})
		return self
	end,

	every = function(self, func, interval)
		table.insert(self._every,{
			func=func,
			interval=ifndef(interval,1),
			decimal_places=decimal_places(ifndef(interval,0)),
			last_time_ran=0
		})
		return self
	end,

	after = function(self, func, delay)
		table.insert(self._after,{
			func=func,
			delay=ifndef(delay,0),
			decimal_places=decimal_places(ifndef(delay,0)),
			called=false
		})
		return self
	end,
	-- END add functions

	update = function(self, dt)
		local all_called = true
		if self._running then
			-- call BEFORE
			for b, before in ipairs(self._before) do
				if not before.called then all_called = false end
				if not before.called and self.time >= before.delay then
					before.func()
					before.called = true
				end
			end

			self.time = love.timer.getTime() - self._start_time

			-- call EVERY
			if self.duration == 0 or self.time <= self.duration then
				for e, every in ipairs(self._every) do
					local fl_time = math.round(self.time, every.decimal_places)
					if fl_time ~= 0 and fl_time % every.interval == 0 and every.last_time_ran ~= fl_time then
						every.func()
						every.last_time_ran = fl_time
					end
					all_called = false
				end
			end

			if #self._after > 0 and self.duration ~= 0 and self.time >= self.duration and self._running then
				-- call AFTER
				local calls_left = #self._after
				for a, after in ipairs(self._after) do
					if not after.called then all_called = false end
					if not after.called and self.time >= self.duration+after.delay then
						after.func()
						after.called = true
					end
					if after.called then
						calls_left = calls_left - 1
					end
				end

				if calls_left == 0 then
					self._running = false
				end
			end	

			if all_called and self.disable_on_all_called then
				self._running = false
			end
		end
		return self
	end,

	start = function(self)
		if not self._running then
			self._running = true
			self._start_time = love.timer.getTime()
		end
		return self
	end,
}

return Timer