StateManager = {
	_stack = {},
	_callbacks = {'update','draw'},

	iterateStateStack = function(func, ...)
		for s, state in ipairs(StateManager._stack) do
			if state[func] ~= nil and not state._off then
				state[func](...)
			end
		end
	end,

	clearStack = function()
		for s, state in pairs(StateManager._stack) do
			state:_leave()
			StateManager._stack[s] = nil
		end
		StateManager._stack = {}
	end,

	push = function(new_state)
		new_state = StateManager.verifyState(new_state)
		new_state._off = false
		table.insert(StateManager._stack, new_state)
		if new_state.load and not new_state._loaded then
			new_state:load()
			new_state._loaded = true
		end
		if new_state.enter then new_state:enter() end
	end,

	pop = function()
		local state = StateManager._stack[#StateManager._stack]
		state:_leave()

		table.remove(StateManager._stack)
	end,

	verifyState = function(state)
		local obj_state = state
		if type(state) == 'string' then 
			if _G[state] then obj_state = _G[state] else
				error('State \"'..state..'\" does not exist')
			end
		end
		return state
	end,

	switch = function(name)
		-- verify state name
		local new_state = StateManager.verifyState(name)

		-- add to state stack
		StateManager.clearStack()
		if new_state then
			table.insert(StateManager._stack, new_state)
			if new_state.load and not new_state._loaded then
				new_state:load()
				new_state._loaded = true
			end
			new_state:_enter()
		end
	end,

	current = function()
		return StateManager._stack[#StateManager._stack]
	end
}

State = Class{
	switch = function(name)
		StateManager.switch(name)
	end,

	current = function()
		return StateManager.current()
	end,

	_enter = function(self)
		if self.enter then self:enter() end
		self._off = false
	end,

	_leave = function(self)
		if self.leave then self:leave() end
		BlankE.clearObjects()
		self._off = true
	end
}

return State