local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local ClientMessagesSender = {} :: ControllerTemplate.Type

function ClientMessagesSender:SendMessage(...)
    local resultMessage = self._configs.MessagesConfig.FormatMessage(...)
    self.MessageSent:Invoke(resultMessage)
end

function ClientMessagesSender:InjectUtils(utils)
    self.MessageSent = utils.Event.new()
    self._utils = utils
end

function ClientMessagesSender.new()
    return setmetatable(ClientMessagesSender, {__index = ControllerTemplate})
end

return ClientMessagesSender