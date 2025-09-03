local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local UpperFrame = {} :: ControllerTemplate.Type

function UpperFrame:AfterPlayerLoaded(player: Player)
    
end

function UpperFrame.new(frame: Frame)
    local self = setmetatable(UpperFrame, {__index = ControllerTemplate})
    self._frame = frame

    return self
end

return UpperFrame