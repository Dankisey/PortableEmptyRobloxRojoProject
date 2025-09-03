local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DevProductRequested = ReplicatedStorage.Remotes.Monetization.DevProductRequested
local Template = require(script.Parent.CustomPromptTemplate)

local DevProductPrompt = {}

function DevProductPrompt:OnUsed(prompt: ProximityPrompt)
    local productId = prompt:GetAttribute("ProductId")

    if not productId then
        return warn("ProductId attribute was not found on prompt")
    end

	DevProductRequested:FireServer(productId)
end

function DevProductPrompt.new(controllers)
	local self = setmetatable(DevProductPrompt, {__index = Template})
	self._gui = ReplicatedStorage.Assets.UI.Prompts[script.Name]
	self._buttonsInteractionsConnector = controllers.ButtonsInteractionsConnector
	self._inputController = controllers.InputController
	self._guiController = controllers.GuiController
	self._inputConnections = {}
	self._guiPerPrompt = {}

	return self
end

return DevProductPrompt