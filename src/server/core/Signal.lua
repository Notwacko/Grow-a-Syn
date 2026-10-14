local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ handlers = {} }, Signal)
end

function Signal:Connect(callback)
	local handler = { callback = callback }
	table.insert(self.handlers, handler)
	local handlers = self.handlers
	return {
		Disconnect = function()
			local index = table.find(handlers, handler)
			if index then
				table.remove(handlers, index)
			end
		end,
	}
end

function Signal:Fire(...)
	for _, handler in table.clone(self.handlers) do
		task.spawn(handler.callback, ...)
	end
end

return Signal
