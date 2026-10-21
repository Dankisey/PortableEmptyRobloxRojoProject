local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Gamepasses = require(ReplicatedStorage.Configs.GamepassesConfig)

local TextChatService = game:GetService("TextChatService")

local Players = game:GetService("Players")

local ChatController = {}

--[[
	Цветное имя выдаётся владельцу геймпасса VIP.

	Гвард на саму секцию конфига обязателен: в пустом GamepassesConfig.Attributes
	нет ключа VIP, и обращение к .AttributeName падает ВНУТРИ OnIncomingMessage —
	а ошибка там ломает чат сразу для всех и на каждом сообщении.
]]
local function getVipAttributeName(): string?
	local vip = Gamepasses.Attributes and Gamepasses.Attributes.VIP

	return vip and vip.AttributeName or nil
end

function ChatController:Initialize()
	local vipAttribute = getVipAttributeName()
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
			--[[
				Автор мог выйти между отправкой и обработкой — тогда здесь nil.
				Ошибка в OnIncomingMessage ломает чат сразу для всех, поэтому гвард.
			]]
			local player = Players:GetPlayerByUserId(message.TextSource.UserId)

			if player and vipAttribute and player:GetAttribute(vipAttribute) then
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