local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local LeftSide = {} :: ControllerTemplate.Type

function LeftSide:AfterPlayerLoaded(player: Player)

end

function LeftSide.new(frame: Frame)
    local self = setmetatable(LeftSide, {__index = ControllerTemplate})
    self._frame = frame

    return self
end

return LeftSide