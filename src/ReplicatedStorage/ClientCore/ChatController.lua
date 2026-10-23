local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

local Gamepasses = require(ReplicatedStorage.Configs.GamepassesConfig)

local ChatController = {}

local RainbowColors = {"#FF0000", "#FF7F00", "#FFFF00", "#00FF00", "#0000FF", "#4B0082", "#9400D3"}

--[[ the section guard is required: an error inside OnIncomingMessage breaks chat for everyone on every message ]]
local function getVipAttributeName(): string?
	local vip = Gamepasses.Attributes and Gamepasses.Attributes.VIP

	return vip and vip.AttributeName or nil
end

local function makeRainbowName(name: string): string
	local rainbowName = ""

	for index = 1, #name do
		local letter = name:sub(index, index)
		local color = RainbowColors[((index - 1) % #RainbowColors) + 1]

		rainbowName ..= string.format("<font color='%s'>%s</font>", color, letter)
	end

	return rainbowName
end

function ChatController:Initialize()
	local vipAttribute = getVipAttributeName()

	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local properties = Instance.new("TextChatMessageProperties")

		if not message.TextSource then return properties end

		--[[ the author may have left between sending and processing ]]
		local player = Players:GetPlayerByUserId(message.TextSource.UserId)
		local isVip = player and vipAttribute and player:GetAttribute(vipAttribute)

		if not isVip then return properties end

		properties.PrefixText = string.format(
			'<font color="#FFFFFF">[</font><font color="#F5CD30">👑</font><font color="#FFFFFF">] </font>%s',
			makeRainbowName(player.DisplayName or player.Name)
		)
		properties.Text = message.Text

		return properties
	end
end

function ChatController.new()
	return setmetatable({}, {__index = ChatController})
end

return ChatController
