local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Gamepasses = require(ReplicatedStorage.Configs.GamepassesConfig)

local TextChatService = game:GetService("TextChatService")

local Players = game:GetService("Players")

local ChatController = {}

function ChatController:Initialize()
     local rainbowColors = {
        "#FF0000", -- Red
        "#FF7F00", -- Orange
        "#FFFF00", -- Yellow
        "#00FF00", -- Green
        "#0000FF", -- Blue
        "#4B0082", -- Indigo
        "#9400D3"  -- Violet
    }

    TextChatService.OnIncomingMessage = function(message: TextChatMessage)
        local props = Instance.new("TextChatMessageProperties")

        if message.TextSource then
            local player = Players:GetPlayerByUserId(message.TextSource.UserId)

            if player:GetAttribute(Gamepasses.Attributes.VIP.AttributeName) then
                local playerName = player.DisplayName or player.Name
                local rainbowName = ""

                for i = 1, #playerName do
                    local char = playerName:sub(i, i)
                    local colorIndex = ((i-1) % #rainbowColors) + 1
                    rainbowName = rainbowName .. string.format("<font color='%s'>%s</font>", rainbowColors[colorIndex], char)
                end

                props.PrefixText = string.format(
                    '<font color="#FFFFFF">[</font><font color="#F5CD30">👑</font><font color="#FFFFFF">] </font>%s',
                    rainbowName
                )

                props.Text = message.Text
            end
        end

        return props
    end
end

function ChatController.new()
	local self = setmetatable({}, {__index = ChatController})

	return self
end

return ChatController