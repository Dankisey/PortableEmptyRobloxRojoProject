local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local Tooltip = {}

local borderOffset = 10

function Tooltip:Initialize()
    self._controllers.TooltipsController.DefaultTooltipActivated:Subscribe(self, function(activationObject: GuiObject, tooltipText: string)
        self._currentObject = activationObject
        self._textLabel.Text = tooltipText
        self._frame.Visible = true
    end)

    self._controllers.TooltipsController.DefaultTooltipDisabled:Subscribe(self, function(activationObject: GuiObject)
        if self._currentObject ~= activationObject then return end

        self._frame.Visible = false
        self._currentObject = nil
    end)

    RunService.Heartbeat:Connect(function()
        if not self._currentObject then return end

        local mousePosition = UserInputService:GetMouseLocation()
        local framePosition = Vector2.new(mousePosition.X / self._gui.AbsoluteSize.X, mousePosition.Y / self._gui.AbsoluteSize.Y)
        framePosition = UDim2.fromScale(framePosition.X, framePosition.Y)

        local xAnchorPoint, yAnchorPoint
        xAnchorPoint = if mousePosition.X >= self._gui.AbsoluteSize.X * .5 then 1 else 0
        yAnchorPoint = if mousePosition.Y - self._frameSize.Y - borderOffset >= 0 then 1 else 0

        self._frame.AnchorPoint = Vector2.new(xAnchorPoint, yAnchorPoint)
        self._frame.Position = framePosition
    end)
end

function Tooltip.new(frame: Frame)
    local self = setmetatable(Tooltip, {__index = ControllerTemplate})
    self._frameSize = frame.AbsoluteSize
    self._textLabel = frame.TextLabel
    self._currentObject = nil
    self._gui = frame.Parent
    self._frame = frame

    return self
end

return Tooltip