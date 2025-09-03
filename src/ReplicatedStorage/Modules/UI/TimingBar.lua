local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Configs.TimingBarConfig)

local TimingBar = {}

local function initialize(self)
    self._pointer = self._frame.Pointer

    local strongArea = self._frame.StrongArea
    strongArea.Size = UDim2.fromScale(Config.Zones.Strong.FillAmount, 1)

    local standartArea = self._frame.StandartArea
    standartArea.Size = UDim2.fromScale(Config.Zones.Strong.FillAmount + Config.Zones.Standart.FillAmount, 1)

    self._areaToHalfPositionRange = {
        {
            Name = "Weak";
            MaxBorder = (1 - (Config.Zones.Strong.FillAmount + Config.Zones.Standart.FillAmount)) / 2
        };
        {
            Name = "Standart";
            MaxBorder = (1 - Config.Zones.Strong.FillAmount) / 2
        };
        {
            Name = "Strong";
            MaxBorder = .5;
        };
    }
end

function TimingBar:Stop() : string
    if self._heartbeatConnection then
        self._heartbeatConnection:Disconnect()
        self._heartbeatConnection = nil
    end

    local position = self._pointer.Position.X.Scale
    local halfPosition = if position <= .5 then position else 1 - position

    for i = 1, #self._areaToHalfPositionRange do
        if halfPosition <= self._areaToHalfPositionRange[i].MaxBorder then
            return self._areaToHalfPositionRange[i].Name
        end

        if i == #self._areaToHalfPositionRange then
            return self._areaToHalfPositionRange[i].Name
        end
    end
end

function TimingBar:Start()
    if self._heartbeatConnection then
        self._heartbeatConnection:Disconnect()
        self._heartbeatConnection = nil
    end

    self._pointer.Position = UDim2.fromScale(Config.SidesOffset, .5)
    local sign = 1

    self._heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        local newPositionX = self._pointer.Position.X.Scale + Config.PointerSpeed * deltaTime * sign

        if newPositionX <= Config.SidesOffset or newPositionX >= 1 - Config.SidesOffset then
            newPositionX = math.clamp(newPositionX, Config.SidesOffset, 1 - Config.SidesOffset)
            sign *= -1
        end

        self._pointer.Position = UDim2.fromScale(newPositionX, .5)
    end)
end

function TimingBar.new(frame: Frame)
    local self = setmetatable({}, {__index = TimingBar})
    self._frame = frame
    initialize(self)

    return self
end

return TimingBar