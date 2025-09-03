local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local Dialogs = require(ReplicatedStorage.Configs.Dialogs)

local DialogSystem = {} :: ControllerTemplate.Type

local responsesActions = {
    EndDialog = function(self)
        self:EndDialog()
    end;

    Action = function(self, response)
        response.Action(self)
    end;

    ContinueDialog = function(self, response)
        if type(response.ContinuingDialog) == "string" then
            self:StartDialog(response.ContinuingDialog)
        else
            self._currentDialog = response.ContinuingDialog
            self.DialogUpdated:Invoke(self._currentDialog)
        end
    end
}

function DialogSystem:StartDialog(dialogName: string)
    if self._currentDialog then
        self:EndDialog()
    end

    if not Dialogs[dialogName] then
        return warn("Dialog with name " .. tostring(dialogName) .. " does not exist")
    end

    self._currentDialog = Dialogs[dialogName]
    self.DialogStarted:Invoke(self._currentDialog)
    self._controllers.CharacterMovementController:DisableMovement()
end

function DialogSystem:ProcessResponse(responseIndex: number)
    if not self._currentDialog then
        return warn("Trying to process response without current dialog")
    end

    if not self._currentDialog.Responses[responseIndex] then
        self:EndDialog()
        return warn("Response with index " .. tostring(responseIndex) .. " does not exist")
    end

    local response = self._currentDialog.Responses[responseIndex]

    if not responsesActions[response.Type] then
        self:EndDialog()
        return warn("Response type " .. tostring(response.Type) .. " has no implemented action")
    end

    responsesActions[response.Type](self, response)
end

function DialogSystem:EndDialog()
    self._currentDialog = nil
    self.DialogEnded:Invoke()
    self._controllers.CharacterMovementController:EnableMovement()
end

function DialogSystem:InjectUtils(utils)
    self._utils = utils
    self.DialogStarted = utils.Event.new()
    self.DialogUpdated = utils.Event.new()
    self.DialogEnded = utils.Event.new()
end

function DialogSystem.new()
    return setmetatable(DialogSystem, {__index = ControllerTemplate})
end

return DialogSystem