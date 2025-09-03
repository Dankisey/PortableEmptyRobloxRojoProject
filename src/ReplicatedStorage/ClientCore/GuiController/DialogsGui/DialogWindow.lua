local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local DialogWindow = {}

local function createResponse(self, responsePhrase: string, responseIndex: number)
    local responseButton = self._responseTemplate:Clone()
    responseButton.Parent = self._responsesHolder
    responseButton.Label.Text = responsePhrase
    responseButton.LayoutOrder = responseIndex
    responseButton.Visible = true

    local responseButtonCallback = function()
        self._controllers.DialogSystem:ProcessResponse(responseIndex)
        self._responsesHolder.CanvasPosition = Vector2.zero
    end

    self._controllers.ButtonsInteractionsConnector:ConnectButton(responseButton, responseButtonCallback)
    table.insert(self._currentResponses, responseButton)
end

local function clearResponses(self)
    for _, response in self._currentResponses do
        response:Destroy()
    end

    table.clear(self._currentResponses)
end

local function updateText(self, dialog)
    for _, singlePhrase in dialog.Phrase do
        self._phraseLabel.Text = singlePhrase[1]
        task.wait(singlePhrase[2])
    end

    for index, responseData in pairs(dialog.Responses) do
        createResponse(self, responseData.Phrase, index)
    end
end

local function onDialogEnded(self)
    self._controllers.GuiController.DialogsGui:Disable()
    clearResponses(self)
end

local function onDialogUpdated(self, dialog)
    clearResponses(self)
    updateText(self, dialog)
end

local function onDialogStarted(self, dialog)
    self._controllers.GuiController.DialogsGui:Enable()
    updateText(self, dialog)
end

function DialogWindow:AfterPlayerLoaded()
    self._phraseLabel = self._frame.PhraseLabel
    self._responsesHolder = self._frame.ResponsesHolder
    self._responseTemplate = self._responsesHolder.ResponseTemplate

    local dialogSystem = self._controllers.DialogSystem
    dialogSystem.DialogStarted:Subscribe(self, onDialogStarted, self)
    dialogSystem.DialogEnded:Subscribe(self, onDialogEnded, self)
    dialogSystem.DialogUpdated:Subscribe(self, onDialogUpdated, self)
end

function DialogWindow.new(frame: Frame)
    local self = setmetatable(DialogWindow, {__index = ControllerTemplate})
    self._currentResponses = {}
    self._frame = frame

    return self
end

return DialogWindow