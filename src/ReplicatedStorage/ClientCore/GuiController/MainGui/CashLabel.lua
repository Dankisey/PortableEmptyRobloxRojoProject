local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local CashLabel = {} :: ControllerTemplate.Type

--[[ a placeholder, not zero: before the save is read, "$ 0" reads as lost progress ]]
local CashPlaceholder = "$ ..."
local CashAttribute = "Cash"

--[[ the attribute may replicate after IsLoaded, so it is listened to, not waited for ]]
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
