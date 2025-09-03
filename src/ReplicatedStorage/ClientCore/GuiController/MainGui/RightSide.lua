local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local RightSide = {} :: ControllerTemplate.Type

function RightSide:AfterPlayerLoaded(player: Player)

end

function RightSide.new(frame: Frame)
    local self = setmetatable(RightSide, {__index = ControllerTemplate})
    self._frame = frame

    return self
end

return RightSide