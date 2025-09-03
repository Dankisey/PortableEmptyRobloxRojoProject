local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FormatNumber = require(ReplicatedStorage.Modules.Utils.FormatNumber)

local ProgressBar = {}

function ProgressBar:SetCustomText(text: string)
	if not self._isupdatingText then return end

	self._progressLabel.Text = text
end

function ProgressBar:SetValue(newValue: number)
	newValue = math.clamp(newValue, 0, self.MaxValue)
	self._bar.Size = UDim2.fromScale(newValue / self.MaxValue, 1)
	
	if self._isupdatingText then
		self._progressLabel.Text = `{FormatNumber(newValue)}/{FormatNumber(self.MaxValue)}`
	end
end

function ProgressBar.new(frame: Frame, maxValue: number, useText: boolean?)
	local self = setmetatable({}, {__index = ProgressBar})
	self._bar = frame.Bar
	self.MaxValue = maxValue
	self._base = frame
	
	if useText == nil then
		useText = false
	end
	
	self._isupdatingText = useText
	
	if useText then
		self._progressLabel = frame:FindFirstChildOfClass("TextLabel")
	end
	
	self:SetValue(0)
	
	return self
end

return ProgressBar