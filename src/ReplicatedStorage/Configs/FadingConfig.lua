local FadingConfig = {}

FadingConfig.FadeIn = {
    Goal = {
        Position = UDim2.fromScale(0.5, 0.5)
    };
    TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out);
}

FadingConfig.FadeOut = {
    Goal = {
        Position = UDim2.fromScale(0.5, -0.5)
    };
    TweenInfo = TweenInfo.new(.6, Enum.EasingStyle.Quart, Enum.EasingDirection.In);
}

return FadingConfig