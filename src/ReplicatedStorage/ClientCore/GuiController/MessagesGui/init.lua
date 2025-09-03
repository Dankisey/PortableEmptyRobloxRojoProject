local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiTemplate = require(ReplicatedStorage.Modules.UI.GuiTemplate)

local MessagesGui = {}

function MessagesGui.new()
	local self = setmetatable(MessagesGui, {__index = GuiTemplate})

	self:CreateChildren(script.Name, script:GetChildren())

	return self
end

return MessagesGui