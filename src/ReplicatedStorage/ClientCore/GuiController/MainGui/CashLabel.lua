local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local CashLabel = {} :: ControllerTemplate.Type

--[[ заглушка, а не ноль: пока сейв не прочитан, «$ 0» игрок прочтёт как потерянный прогресс ]]
local CashPlaceholder = "$ ..."
local CashAttribute = "Cash" -- валюта SoftCurrencyService

--[[ атрибут может доехать позже IsLoaded: порядок репликации не гарантирован, поэтому слушаем, а не ждём ]]
function CashLabel:AfterPlayerLoaded(player: Player)
	local function render()
		local value = player:GetAttribute(CashAttribute)

		self._frame.Text = if value == nil then CashPlaceholder else "$ " .. self._utils.FormatNumber(math.floor(value))
	end

	render()
	player:GetAttributeChangedSignal(CashAttribute):Connect(render)
end

function CashLabel.new(frame: TextLabel)
	local self = setmetatable(CashLabel, {__index = ControllerTemplate})
	self._frame = frame
	self._frame.Text = CashPlaceholder

	return self
end

return CashLabel
