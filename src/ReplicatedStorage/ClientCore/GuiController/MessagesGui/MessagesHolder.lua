local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local MessageSent = ReplicatedStorage.Remotes.UI.ServerMessageSent

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local Config = require(ReplicatedStorage.Configs.MessagesConfig)

local MessagesHolder = {}

local function showMessage(self, message: string)
	self._controllers.SoundPlayer:PlaySound(self._configs.SoundNames.Message)

	local messageLabel: TextLabel = self._messageTemplate:Clone()
	messageLabel.Text = message
	messageLabel.Visible = true
	messageLabel.Parent = self._messagesHolder

	for _, label: TextLabel in pairs(self._messages) do
		label.LayoutOrder += 1
	end

	table.insert(self._messages, messageLabel)

	task.spawn(function()
		task.wait(Config.LifeTime)

		local strokeTween = TweenService:Create(messageLabel.Stroke, self._tweenInfo, self._strokeTweenGoal)
		local tween = TweenService:Create(messageLabel, self._tweenInfo, self._tweenGoal)
		strokeTween:Play()
		tween:Play()
		tween.Completed:Wait()

		--[[ the label may already be removed, and table.remove with nil throws ]]
		local index = table.find(self._messages, messageLabel)

		if index then
			table.remove(self._messages, index)
		end

		messageLabel:Destroy()
	end)
end

function MessagesHolder:Initialize()
	self._controllers.ClientMessagesSender.MessageSent:Subscribe(self, function(message: string)
		showMessage(self, message)
	end)
end

function MessagesHolder.new(frame: Frame)
	local self = setmetatable(MessagesHolder, {__index = ControllerTemplate})

	self._messages = {} :: {TextLabel}
	self._messagesHolder = frame :: Frame
	self._messageTemplate = frame.Template :: TextLabel
	self._tweenInfo = TweenInfo.new(Config.DisappearingTime, Enum.EasingStyle.Linear)
	self._tweenGoal = {TextTransparency = 1}
	self._strokeTweenGoal = {Transparency = 1}

	MessageSent.OnClientEvent:Connect(function(message: string)
		showMessage(self, message)
	end)

	return self
end

return MessagesHolder
