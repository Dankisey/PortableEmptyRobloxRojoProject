local TweenService = game:GetService("TweenService")

local CooldownMask = {}

function CooldownMask:Activate(cooldownTime: number?)
	self._tween:Cancel()
	self._cooldownMask.Size = UDim2.fromScale(1, 1)
	
	if cooldownTime and cooldownTime ~= self._cooldownTime then
		self._tweenInfo = TweenInfo.new(cooldownTime, Enum.EasingStyle.Linear)
		self._tween = TweenService:Create(self._cooldownMask, self._tweenInfo, self._goals)
	end
	
	self._tween:Play()
end

function CooldownMask.new(cooldownFrame: Frame, cooldownTime: number)
	local self = setmetatable({}, {__index = CooldownMask})
	
	self._cooldownTime = cooldownTime
	self._cooldownMask = cooldownFrame
	self._goals = {Size = UDim2.fromScale(1, 0)}
	self._tweenInfo = TweenInfo.new(cooldownTime, Enum.EasingStyle.Linear)
	self._tween = TweenService:Create(self._cooldownMask, self._tweenInfo, self._goals)
	
	return self
end

return CooldownMask