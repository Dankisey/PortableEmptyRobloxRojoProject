local InfoPin = {}

function InfoPin:IsEnabled()
	return self._pin.Visible
end

function InfoPin:TurnOn()
	self._pin.Visible = true
end

function InfoPin:TurnOff()
	self._pin.Visible = false
end

function InfoPin.new(pin: Frame)
	local self = setmetatable({}, {__index = InfoPin})
	self._pin = pin
	self:TurnOff()

	return self
end

return InfoPin