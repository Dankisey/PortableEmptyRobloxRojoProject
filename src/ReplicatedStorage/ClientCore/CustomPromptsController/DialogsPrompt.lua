local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Template = require(script.Parent.CustomPromptTemplate)

local DialogsPrompt = {}

function DialogsPrompt:OnUsed(prompt: ProximityPrompt)
    local dialogName = prompt:GetAttribute("DialogName")

	if dialogName == "KeepBuilding" or dialogName == "MaxHeight" or dialogName == "HeightBuying" then
		local balloons = self._zoneController:GetBalloons()
		local promptsBalloon = prompt.Parent.Parent.Parent
		local isOwnZone = false

		for _, balloon in balloons:GetChildren() do
			if promptsBalloon == balloon then
				isOwnZone = true
				break
			end
		end

		if not isOwnZone then return end
	end

	self._dialogSystem:StartDialog(dialogName)
end

function DialogsPrompt.new(controllers)
	local self = setmetatable(DialogsPrompt, {__index = Template})
	self._gui = ReplicatedStorage.Assets.UI.Prompts[script.Name]
	self._buttonsInteractionsConnector = controllers.ButtonsInteractionsConnector
	self._zoneController = controllers.ZoneController
	self._inputController = controllers.InputController
	self._guiController = controllers.GuiController
    self._dialogSystem = controllers.DialogSystem
	self._inputConnections = {}
	self._guiPerPrompt = {}

	return self
end

return DialogsPrompt