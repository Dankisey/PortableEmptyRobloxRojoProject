local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiTemplate = require(ReplicatedStorage.Modules.UI.GuiTemplate)

local DialogsGui = {}

function DialogsGui.new()
	local self = setmetatable(DialogsGui, {__index = GuiTemplate})

	self:CreateChildren(script.Name, script:GetChildren())
	-- local hotbar = self.Gui.Parent:WaitForChild("NeoHotbar")

	-- self.Gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	-- 	hotbar.Enabled = not self.Gui.Enabled
	-- end)

	return self
end

return DialogsGui