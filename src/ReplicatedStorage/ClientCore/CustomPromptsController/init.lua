local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local CustomPromptsController = {}

function CustomPromptsController:Initialize(player: Player)
    self.CustomPrompts = {}

    for _, promptClass in pairs(script:GetChildren()) do
        if promptClass.Name == "CustomPromptTemplate" or promptClass.Name == "EggPromptTemplate" then continue end

        self.CustomPrompts[promptClass.Name] = require(promptClass).new(self._controllers)
    end

    ProximityPromptService.PromptShown:Connect(function(prompt)
		if prompt.Style == Enum.ProximityPromptStyle.Default then return end

        if prompt:GetAttribute("TargetPlayer") and player.Name ~= prompt:GetAttribute("TargetPlayer") then return end

        local promptType = prompt:GetAttribute("PromptType")

        if not self.CustomPrompts[promptType] then
            return warn("Custom prompt with type " .. tostring(type) .. " is not implemented")
        end

        if promptType == "EggPrompt" then
            if not self.CustomPrompts[promptType][prompt] then 
                self.CustomPrompts[promptType][prompt] = {}
            end

            self.CustomPrompts[promptType][prompt].PlayerInRange = true
        end

		self.CustomPrompts[promptType]:Enable(prompt)
	end)

	ProximityPromptService.PromptHidden:Connect(function(prompt)
		if prompt.Style == Enum.ProximityPromptStyle.Default then return end

        if prompt:GetAttribute("TargetPlayer") and player.Name ~= prompt:GetAttribute("TargetPlayer") then return end

        local type = prompt:GetAttribute("PromptType")

        if not self.CustomPrompts[type] then
            return warn("Custom prompt with type " .. tostring(type) .. " is not implemented")
        end

        if type == "EggPrompt" then
            if not self.CustomPrompts[type][prompt] then 
                self.CustomPrompts[type][prompt] = {}
            end

            self.CustomPrompts[type][prompt].PlayerInRange = false
        end

		self.CustomPrompts[type]:Disable(prompt)
	end)
end

function CustomPromptsController.new()
    local self = setmetatable(CustomPromptsController, {__index = ControllerTemplate})

    return self
end

return CustomPromptsController