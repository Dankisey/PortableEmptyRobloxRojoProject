local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FormatTime = require(ReplicatedStorage.Modules.Utils.FormatTime)

local Widget = {}

local function initialize(self)
    self.Frame.Icon.Image = self._imageId

    if self.Timer then
        self.Frame.TimerLabel.Text = FormatTime(self.Timer:GetLeftTime(), 2)

        self.Timer.Updated:Subscribe(self, function(leftTime: number)
            self.Frame.TimerLabel.Text = FormatTime(leftTime, 2)
        end)
    else
        self.Frame.TimerLabel.Visible = false
    end
end

function Widget:SetText(text: string)
    self.Frame.TimerLabel.Text = text
    self.Frame.TimerLabel.Visible = true
end

function Widget:Destroy()
    if self.Timer then
        self.Timer.Updated:Unsubscribe(self)
    end

    self.Frame:Destroy()
    table.clear(self)
end

function Widget.new(frame: Frame, imageId: string, timer: {any}?)
    local self = setmetatable({}, {__index = Widget})
    self._imageId= imageId
    self.Frame = frame
    self.Timer = timer
    initialize(self)

    return self
end

return Widget