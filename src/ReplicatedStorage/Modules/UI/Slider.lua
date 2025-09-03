local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Slider = {}

local function changeToValue(Percent)
    local Value = math.floor(Percent * 100)
    return Value
end

function Slider:SetSetting(percent)
    self.Bar.Percentage.Value = percent
    self.Knob.Position = UDim2.new(percent / 100, 0, self.Knob.Position.Y.Scale, 0)
end

function Slider.new(frame, folder, basicVolume)
    local self = setmetatable({}, {__index = Slider})

    self._folder = folder
    self.Bar = frame
    self.Knob = self.Bar.Knob

    self.Knob.Position = UDim2.new(basicVolume, 0, self.Knob.Position.Y.Scale, 0)

    self.Dragging = false

    self.Knob.MouseButton1Down:Connect(function()
        self.Dragging = true
    end)

    UserInputService.InputChanged:Connect(function()
        if self.Dragging then
            local MousePos = UserInputService:GetMouseLocation() + Vector2.new(0, -36)
            local RelPos = MousePos - self.Bar.AbsolutePosition
            local Percent = math.clamp(RelPos.X / self.Bar.AbsoluteSize.X, 0, 1)

            self.Knob.Position = UDim2.new(Percent, 0, self.Knob.Position.Y.Scale, 0)
            local FinalValue = changeToValue(Percent)

            self.Bar.Percentage.Value = FinalValue
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = false
        end
    end)

    return self
end

return Slider