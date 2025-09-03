local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessageEvent = ReplicatedStorage.Remotes.UI.ServerMessageSent

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)

local ServerMessagesSender = {}

function ServerMessagesSender:SendMessageToPlayer(reciever: Player, ...)
    local resultMessage = self._configs.MessagesConfig.FormatMessage(...)
    MessageEvent:FireClient(reciever, resultMessage)
end

function ServerMessagesSender:SendMessage(...)
    local resultMessage = self._configs.MessagesConfig.FormatMessage(...)
    MessageEvent:FireAllClients(resultMessage)
end

function ServerMessagesSender.new()
    return setmetatable(ServerMessagesSender, {__index = ServiceTemplate})
end

return ServerMessagesSender