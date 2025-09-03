local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local Prompt = {}

local function disableUI(self)
    self._confirmAction = nil
    self._declineAction = nil
    self._controllers.GuiController.ConfirmationPromptGui:Disable()
end

local function onConfirmButtonPressed(self)
    self._confirmAction()
    disableUI(self)
end

local function onDeclineButtonPressed(self)
    self._declineAction()
    disableUI(self)
end

function Prompt:SetInfo(promptText: string, confirmCallback, declineCallback)
    self._descriptionLabel.Text = promptText
    self._confirmAction = confirmCallback
    self._declineAction = declineCallback
end

function Prompt:Initialize()
    local confirmButton = self._frame.ConfirmButton
    self._controllers.ButtonsInteractionsConnector:ConnectButton(confirmButton, onConfirmButtonPressed, self)

    local declineButton = self._frame.DeclineButton
    self._controllers.ButtonsInteractionsConnector:ConnectButton(declineButton, onDeclineButtonPressed, self)

    self._descriptionLabel = self._frame.DescriptionLabel
end

function Prompt.new(frame: Frame)
    local self = setmetatable(Prompt, {__index = ControllerTemplate})
    self._frame = frame

    return self
end

return Prompt