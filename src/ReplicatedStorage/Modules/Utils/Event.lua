local Event = {}

function Event:Invoke(...)
	for _, callback: (any) -> () in pairs(self._callbacks) do
		if callback.Args then
			task.spawn(callback.Action, table.unpack(callback.Args) , ...)
		else
			task.spawn(callback.Action, ...)
		end
	end
end

function Event:Unsubscribe(key: any)
	if self._callbacks[key] then
		self._callbacks[key].Action = nil
		self._callbacks[key].Args = nil
		self._callbacks[key] = nil
	end
end

function Event:Subscribe(key: any, callback: (any) -> (), ...: any)
	if self._callbacks[key] then
		warn("Event already has a callback with key: " .. tostring(key))
		
		return
	end
	
	local args = table.pack(...)

	if #args == 0 then
		args = nil
	end 

	self._callbacks[key] = {}
	self._callbacks[key].Action = callback
	self._callbacks[key].Args = args
end

function Event:Desctroy()
	table.clear(self._callbacks)
end

function Event.new()
	local self = setmetatable({}, {__index = Event})
	
	self._callbacks = {}
	
	return self
end

return Event