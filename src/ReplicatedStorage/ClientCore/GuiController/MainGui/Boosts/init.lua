local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local ClientTypes = require(ReplicatedStorage.Modules.ClientTypes)

local Timer = require(ReplicatedStorage.Modules.Utils.Timer)
local Widget = require(script.Widget)

local Boosts = {} :: ClientTypes.BoostsFrame

local function destroyWidget(self: ClientTypes.BoostsFrame, key: string)
    self._widgets[key]:Destroy()
    self._widgets[key] = nil
end

--[[
local function updateWidgets(self: ClientTypes.BoostsFrame, boosts)
    if not boosts then return end

    if boosts.TemporaryBoosts then
        for sourceName, boostInfo in pairs(boosts.TemporaryBoosts) do
            if not ConsumablesConfig.UiInfo[sourceName] then continue end

            if self._widgets[sourceName] then
                self:TryUpdateBoostTimer(sourceName, boostInfo.Duration)
            else
                local timer = Timer.new()
                self:TryAddBoostWidget(sourceName, ConsumablesConfig.UiInfo[sourceName].Icon, ConsumablesConfig.UiInfo[sourceName].TooltipInfo, timer)
                self._widgets[sourceName].Frame.LayoutOrder = ConsumablesConfig.UiInfo[sourceName].WidgetOrder
                timer:Start(boostInfo.Duration)
            end
        end
    end

    if boosts.PermanentBoosts then
        for boostName, _ in pairs(boosts.PermanentBoosts) do
            if not PermanentBoostsConfig.UiInfo[boostName] then continue end

            self:TryAddBoostWidget(boostName, PermanentBoostsConfig.UiInfo[boostName].Icon, PermanentBoostsConfig.UiInfo[boostName].TooltipInfo)
            self._widgets[boostName].Frame.LayoutOrder = PermanentBoostsConfig.UiInfo[boostName].WidgetOrder
        end
    end
end


function Boosts:TryRemoveWidget(key: string)
    if not self._widgets[key] then return false end

    destroyWidget(self, key)

    return true
end

function Boosts:TryAddBoostWidget(key: string, imageId: string, tooltipInfo: {any} | (number) -> {any}, timer: any?)
    if self._widgets[key] then
        if PermanentBoostsConfig.Boosts[key] and PermanentBoostsConfig.Boosts[key].IsLevelBased then
            local level = self._controllers.BoostsController:GetBoostLevel(key)

            if not level then return end

            self._controllers.TooltipsController:RegisterTooltip(self._widgets[key].Frame.Icon, tooltipInfo(level))
        end

        return
    end

    local frame = self._boostTemplate:Clone()
    frame.Parent = self._frame
    frame.Visible = true
    frame.Name = key

    self._widgets[key] = Widget.new(frame, imageId, timer)

    if PermanentBoostsConfig.Boosts[key] and PermanentBoostsConfig.Boosts[key].IsLevelBased then
        local level = self._controllers.BoostsController:GetBoostLevel(key)

        if level then
            self._controllers.TooltipsController:RegisterTooltip(frame.Icon, tooltipInfo(level))
        end
    else

        self._controllers.TooltipsController:RegisterTooltip(frame.Icon, tooltipInfo)
    end

    if timer then
        timer.Finished:Subscribe(self, function()
            timer.Finished:Unsubscribe(self)
            destroyWidget(self, key)
        end)
    end

    return self._widgets[key]
end

function Boosts:TryUpdateBoostTimer(key: string, countTime: number)
    if not self._widgets[key] then return false end

    if not self._widgets[key].Timer then
        warn("Widget with key [", key, "] has no timer")

        return false
    end

    self._widgets[key].Timer:Start(countTime)

    return true
end

function Boosts:AfterPlayerLoaded()
    updateWidgets(self, self._controllers.BoostsController:GetBoosts())

    self._controllers.BoostsController.BoostsUpdated:Subscribe(self, function(boosts)
        updateWidgets(self, boosts)
    end)
end
]]

function Boosts.new(frame: Frame)
    local self = setmetatable(Boosts, {__index = ControllerTemplate})
    self._boostTemplate = frame:WaitForChild("BoostTemplate")
    self._frame = frame
    self._widgets = {}

    return self
end

return Boosts