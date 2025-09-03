local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiTemplate = require(ReplicatedStorage.Modules.UI.GuiTemplate)

local ConfirmationPromptGui = {}

function ConfirmationPromptGui:ShowPrompt(promptText: string, confirmCallback, declineCallback)
	self.Prompt:SetInfo(promptText, confirmCallback, declineCallback)
	self:Enable(true)
end

function ConfirmationPromptGui.new()
	local self = setmetatable(ConfirmationPromptGui, {__index = GuiTemplate})

	self:CreateChildren(script.Name, script:GetChildren())

	return self
end

return ConfirmationPromptGui