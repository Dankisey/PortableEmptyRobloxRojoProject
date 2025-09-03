local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiTemplate = require(ReplicatedStorage.Modules.UI.GuiTemplate)

local TooltipsGui = {}

function TooltipsGui.new()
	local self = setmetatable(TooltipsGui, {__index = GuiTemplate})

	self:CreateChildren(script.Name, script:GetChildren())

	return self
end

return TooltipsGui