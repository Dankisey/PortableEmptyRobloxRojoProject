local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiTemplate = require(ReplicatedStorage.Modules.UI.GuiTemplate)
local Config = require(ReplicatedStorage.Configs.FadingConfig)

local TweenService = game:GetService("TweenService")

local FadingGui = {}

local function startTween(self, config)
    if self._currentTween then
        task.cancel(self._destroyingTask)
        self._currentTween:Cancel()
    end

    self._currentTween = TweenService:Create(self._blackScreen, config.TweenInfo, config.Goal)
    self._currentTween:Play()

    self._destroyingTask = task.spawn(function()
        self._currentTween.Completed:Wait()
        self._currentTween = nil
    end)
end

function FadingGui:FadeOut() : RBXScriptSignal
    if self._isFadingOn == false then return end

    self._isFadingOn = false
    startTween(self, Config.FadeOut)

    return self._currentTween.Completed
end

function FadingGui:FadeIn() : RBXScriptSignal
    if self._isFadingOn then return end

    self._isFadingOn = true
    startTween(self, Config.FadeIn)

    if not self._currentTween then
        warn("FadeIn: Current tween is nil!")
    end

    return self._currentTween.Completed
end

function FadingGui:Initialize()
    self._blackScreen = self.Gui:WaitForChild("BlackScreen") :: Frame
    self._blackScreen.Position = Config.FadeOut.Goal.Position
end

function FadingGui.new()
	local self = setmetatable(FadingGui, {__index = GuiTemplate})
    self._isFadingOn = false

	self:CreateChildren(script.Name, script:GetChildren())

	return self
end

return FadingGui