local TweenService = game:GetService("TweenService")

--[[
	Твин модели целиком. Сам PivotTo твинить нельзя, поэтому крутим CFrameValue
	и переносим его значение на модель на каждом изменении.

	Возвращает уже запущенный Tween: вызывающий сам решает, ждать его
	через Completed:Wait() или просто держать ссылку, чтобы потом отменить.
	После завершения или отмены временный CFrameValue убирается сам.
]]
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

	--[[ Cancel() тоже вызывает Completed, так что уборка не теряется. ]]
	tween.Completed:Once(function()
		connection:Disconnect()
		value:Destroy()
	end)

	tween:Play()

	return tween
end

return TweenPivot
