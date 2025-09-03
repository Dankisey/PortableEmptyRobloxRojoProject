local TweenService = game:GetService("TweenService")

local PopUpsConfig = {}

PopUpsConfig.EquipmentPopUpLifetime = 10
PopUpsConfig.EquipmentPopUpDelay = .5

PopUpsConfig.SpawningArea = {
    Cash = {
        CornerA = Vector2.new(0.4, 0.6);
        CornerB = Vector2.new(0.5, 0.6);
    };
}

PopUpsConfig.BurstParameters = {
    TargetAmountPerVisual = 5;
    AppearingRate = 0.03;
    VisualsLimit = 5;
}

PopUpsConfig.AppearingParameters = {
    Cash = {
        EasingStyle = Enum.EasingStyle.Back;
        GrowingTime = 0.2;
        StartSize = 0.1;
        Goal = { Scale = 1 };
    };
}

PopUpsConfig.DisappearingParameters = {
    Cash = {
        TargetPosition = UDim2.fromScale(0.056, 0.73);
        EasingStyle = Enum.EasingStyle.Quad;
        Speed = .5;
    };
}

PopUpsConfig.GetAppearingTween = function(popup: ImageLabel) : Tween
    local tweenInfo = TweenInfo.new(PopUpsConfig.AppearingParameters[popup.Name].GrowingTime, PopUpsConfig.AppearingParameters[popup.Name].EasingStyle)

    return TweenService:Create(popup.UIScale, tweenInfo, PopUpsConfig.AppearingParameters[popup.Name].Goal)
end

PopUpsConfig.GetDisappearingTween = function(popup: ImageLabel) : Tween
    local goal, tweenInfo

    goal = { Position = PopUpsConfig.DisappearingParameters[popup.Name].TargetPosition }

    local currentPosition = Vector2.new(popup.Position.X.Scale, popup.Position.Y.Scale)
    local targetPosition = Vector2.new(goal.Position.X.Scale, goal.Position.Y.Scale)
    local distance = (targetPosition - currentPosition).Magnitude
    local time = distance / PopUpsConfig.DisappearingParameters[popup.Name].Speed

    tweenInfo = TweenInfo.new(time, PopUpsConfig.DisappearingParameters[popup.Name].EasingStyle)

    return TweenService:Create(popup, tweenInfo, goal)
end

return PopUpsConfig