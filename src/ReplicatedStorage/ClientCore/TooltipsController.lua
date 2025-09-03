local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local TooltipsController = {}

local function getGuiParent(uiObject: GuiObject) : ScreenGui
    local parent = uiObject

    repeat
        parent = parent.Parent
    until parent:IsA("ScreenGui") or parent == game

    if parent == game then
        return nil
    end

    return parent
end

function TooltipsController:RegisterDefaultTooltip(activationObject: GuiObject, tooltipText: string)
    local gui = getGuiParent(activationObject)

    if not gui then
        return warn("Tooltip activation object is not descendant of ScreenGui")
    end

    if self._registeredTooltips[activationObject] then
        for _, connection in pairs(self._registeredTooltips[activationObject]) do
            connection:Disconnect()
        end

        table.clear(self._registeredTooltips[activationObject])
    else
        self._registeredTooltips[activationObject] = {}
    end

    table.insert(self._registeredTooltips[activationObject], activationObject.MouseEnter:Connect(function()
        if gui.Enabled == false then return end

        if typeof(tooltipText) == "string" then
            self.DefaultTooltipActivated:Invoke(activationObject, tooltipText)
        else
            self.DefaultTooltipActivated:Invoke(activationObject, tooltipText())
        end
    end))

    table.insert(self._registeredTooltips[activationObject], activationObject.MouseLeave:Connect(function()
        self.DefaultTooltipDisabled:Invoke(activationObject)
    end))

    table.insert(self._registeredTooltips[activationObject], gui:GetPropertyChangedSignal("Enabled"):Connect(function()
        if gui.Enabled == false then
            self.DefaultTooltipDisabled:Invoke(activationObject)
        end
    end))
end

function TooltipsController:RegisterTooltip(activationObject: GuiObject, info: {Type: string})
    self:RegisterDefaultTooltip(activationObject, info.Text)
end

function TooltipsController:InjectUtils(utils)
    self._utils = utils
    self.DefaultTooltipActivated = utils.Event.new()
    self.DefaultTooltipDisabled = utils.Event.new()
end

function TooltipsController.new()
    local self = setmetatable(TooltipsController, {__index = ControllerTemplate})
    self._registeredTooltips = {}

    return self
end

return TooltipsController