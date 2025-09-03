local FormatNumber = require(game.ReplicatedStorage.Modules.Utils.FormatNumber)

local Counter = {}

local function updateValue(self)
	self._label.Text = "$" .. FormatNumber(self._curentAmount)
end

function Counter.new(frame: Frame, intValue: IntValue)
    local self = setmetatable({}, {__index = Counter})
    self._floatingLabel = frame.CurrencyFloaters
    self._curentAmount = intValue.Value
    self._label = frame.CounterLabel
    self._valueObject = intValue
    self._displayTimer = nil
    self._pendingAmount = 0

    updateValue(self)

    local lastAmount = intValue.Value

    intValue.Changed:Connect(function(value)
        self._curentAmount = value
        updateValue(self)
    end)

    return self
end

return Counter