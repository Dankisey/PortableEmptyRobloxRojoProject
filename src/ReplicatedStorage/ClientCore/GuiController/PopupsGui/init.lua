local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiTemplate = require(ReplicatedStorage.Modules.UI.GuiTemplate)

local PopupsGui = {}

function PopupsGui:FirePopup(statName: string, data: any)
	self.Popups:FirePopup(statName, data)
end

function PopupsGui.new()
	local self = setmetatable(PopupsGui, {__index = GuiTemplate})

	self:CreateChildren(script.Name, script:GetChildren())

	return self
end

return PopupsGui