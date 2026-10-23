local TweenService = game:GetService("TweenService")

--[[ a popup name = a template in Assets.UI.Popups; every popup needs an entry in SpawningArea, AppearingParameters and DisappearingParameters ]]
local PopUpsConfig = {}

-- popups that fly as a burst of several icons for one amount; the rest fly as one icon
PopUpsConfig.BurstPopups = {
	Cash = true;
}

PopUpsConfig.SpawningArea = {
	Cash = {
		CornerA = Vector2.new(0.4, 0.6);
		CornerB = Vector2.new(0.5, 0.6);
	};
}

PopUpsConfig.BurstParameters = {
	TargetAmountPerVisual = 5; -- amount carried by one icon
	AppearingRate = 0.03; -- seconds between icons
	VisualsLimit = 5;
}

PopUpsConfig.AppearingParameters = {
	Cash = {
		EasingStyle = Enum.EasingStyle.Back;
		GrowingTime = 0.2; -- seconds
		StartSize = 0.1;
		Goal = {Scale = 1};
	};
}

PopUpsConfig.DisappearingParameters = {
	Cash = {
		TargetPosition = UDim2.fromScale(0.056, 0.73);
		EasingStyle = Enum.EasingStyle.Quad;
		Speed = .5; -- screen shares per second
	};
}

function PopUpsConfig.GetAppearingTween(popup: GuiObject): Tween
	local parameters = PopUpsConfig.AppearingParameters[popup.Name]
	local tweenInfo = TweenInfo.new(parameters.GrowingTime, parameters.EasingStyle)

	return TweenService:Create(popup.UIScale, tweenInfo, parameters.Goal)
end

function PopUpsConfig.GetDisappearingTween(popup: GuiObject): Tween
	local parameters = PopUpsConfig.DisappearingParameters[popup.Name]
	local currentPosition = Vector2.new(popup.Position.X.Scale, popup.Position.Y.Scale)
	local targetPosition = Vector2.new(parameters.TargetPosition.X.Scale, parameters.TargetPosition.Y.Scale)
	local distance = (targetPosition - currentPosition).Magnitude
	local tweenInfo = TweenInfo.new(distance / parameters.Speed, parameters.EasingStyle)

	return TweenService:Create(popup, tweenInfo, {Position = parameters.TargetPosition})
end

return PopUpsConfig
