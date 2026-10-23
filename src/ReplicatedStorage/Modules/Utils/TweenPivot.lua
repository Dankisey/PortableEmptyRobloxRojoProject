local TweenService = game:GetService("TweenService")

-- returns a playing Tween; PivotTo cannot be tweened, so a temporary CFrameValue drives the model
local function TweenPivot(
	model: Model | BasePart,
	targetCFrame: CFrame,
	duration: number,
	easingStyle: Enum.EasingStyle?,
	easingDirection: Enum.EasingDirection?
): Tween
	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()

	local tween = TweenService:Create(
		value,
		TweenInfo.new(
			duration,
			easingStyle or Enum.EasingStyle.Quad,
			easingDirection or Enum.EasingDirection.Out
		),
		{Value = targetCFrame}
	)

	local connection = value.Changed:Connect(function(newValue: CFrame)
		if model.Parent then
			model:PivotTo(newValue)
		end
	end)

	--[[ Cancel also fires Completed, so the cleanup is never lost ]]
	tween.Completed:Once(function()
		connection:Disconnect()
		value:Destroy()
	end)

	tween:Play()

	return tween
end

return TweenPivot
