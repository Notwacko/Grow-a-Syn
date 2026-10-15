local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ handlers = {} }, Signal)
end

function Signal:connect(callback)
	local handler = { callback = callback }
	table.insert(self.handlers, handler)
	return function()
		local index = table.find(self.handlers, handler)
		if index then
			table.remove(self.handlers, index)
		end
	end
end

function Signal:fire(...)
	for _, handler in table.clone(self.handlers) do
		task.spawn(handler.callback, ...)
	end
end

return Signal
