local TweenService = game:GetService("TweenService")
local GuiTemplate = require(script.Parent.GuiTemplate)

local AnimatedGuiTemplate = setmetatable({}, {__index = GuiTemplate})
AnimatedGuiTemplate.__index = AnimatedGuiTemplate

function AnimatedGuiTemplate:Enable(isForced)
    self:CancelAnimations()

    self.MainFrame.Size = UDim2.new(0, 0, 0, 0)
    GuiTemplate.Enable(self, isForced)

	local tweenInfo = TweenInfo.new(
		0.25,
		Enum.EasingStyle.Back, -- Back easing style (for a bit of a bounce effect)
		Enum.EasingDirection.Out -- Ease out for a smooth finish
	)

	local goal = { Size = self.InitialSize }

	local openTween = TweenService:Create(self.MainFrame, tweenInfo, goal)

    table.insert(self._animationTweens, openTween)

    openTween.Completed:Connect(function()
        self:RemoveTween(openTween)
    end)

    openTween:Play()
end

function AnimatedGuiTemplate:Disable()
    self:CancelAnimations()

	local tweenInfo = TweenInfo.new(
		0.1,
		Enum.EasingStyle.Back, -- Back easing style (optional for smooth effect)
		Enum.EasingDirection.In -- Ease in to make it shrink smoothly
	)

	local goal = { Size = UDim2.new(0, 0, 0, 0) }

	local closeTween  = TweenService:Create(self.MainFrame, tweenInfo, goal)

    table.insert(self._animationTweens, closeTween)

    closeTween.Completed:Connect(function()
        self.Gui.Enabled = false
        self.Disabled:Invoke()

        self:RemoveTween(closeTween)
    end)

    closeTween:Play()
end

function AnimatedGuiTemplate:CancelAnimations()
    if not self._animationTweens then return end

    for _, tween in ipairs(self._animationTweens) do
        tween:Cancel()
    end

    self._animationTweens = {}
end

function AnimatedGuiTemplate:RemoveTween(tween)
    if not self._animationTweens then return end

    for i, existingTween in ipairs(self._animationTweens) do
        if existingTween == tween then
            table.remove(self._animationTweens, i)
            break
        end
    end
end

function AnimatedGuiTemplate:Initialize(player: Player)
    GuiTemplate.Initialize(self, player)

    self.MainFrame = self.Gui:FindFirstChildOfClass("Frame")

    if not self.MainFrame then
        warn("No Frame found in GUI", self.Gui)
        return
    end

    self.InitialSize = self.MainFrame.Size
    self._animationTweens = {}
end

return AnimatedGuiTemplate