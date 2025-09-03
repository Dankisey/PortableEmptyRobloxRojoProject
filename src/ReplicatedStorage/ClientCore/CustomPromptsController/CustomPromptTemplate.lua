local UserInputService = game:GetService("UserInputService")
local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui
local PromptsGui = PlayerGui:WaitForChild("CustomPrompts")

local CustomPromptTemplate = {}

local function adaptButtonTextToDevice(controlType: string, gui: UIBase)
	local frame = gui:WaitForChild("Background", 2)

	if not frame then return end

	if controlType == "Desktop" then
		frame.ActivationButton.InputIcon.Visible = false
		frame.ActivationButton.InputText.Visible = true
		frame.ActivationButton.InputText.Text = "E"
		frame.ActivationButton.InputText.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif controlType:match("Mobile") then
		frame.ActivationButton.InputText.Visible = false
		frame.ActivationButton.InputIcon.Visible = true
	else
		frame.ActivationButton.InputIcon.Visible = false
		frame.ActivationButton.InputText.Visible = true

		frame.ActivationButton.InputText.Text = "X"
		frame.ActivationButton.InputText.TextColor3 = Color3.fromRGB(92, 135, 255)

		--[[
		frame.ActivationButton.InputText.Text = "□"
		frame.ActivationButton.InputText.TextColor3 = Color3.fromRGB(255, 107, 255)
		]]
	end
end

function CustomPromptTemplate:Enable(prompt: ProximityPrompt)
	local part = prompt.Parent or prompt.AncestryChanged:Wait()
	self._guiPerPrompt[prompt] = self._gui:Clone()
	self._guiPerPrompt[prompt].Parent = PromptsGui
	self._guiPerPrompt[prompt].Adornee = part

	local controlType = self._inputController:GetControllType()
	adaptButtonTextToDevice(controlType, self._guiPerPrompt[prompt])

    if self.OnEnabled then
        self:OnEnabled(prompt, self._guiPerPrompt[prompt])
    end

	task.spawn(function()
		local button = self._guiPerPrompt[prompt]:WaitForChild("Background", 1)

		if not button then return end

		button = button:WaitForChild("ActivationButton", 1)

		if not button then return end

		self._buttonsInteractionsConnector:ConnectButton(button, self.Use, self, prompt)
	end)

	self._inputConnections[prompt] = UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
			self:Use(prompt)
		end
	end)

	self._guiPerPrompt[prompt].Enabled = true
end

function CustomPromptTemplate:Disable(prompt: ProximityPrompt)
	if self._guiPerPrompt[prompt] then
		self._guiPerPrompt[prompt]:Destroy()
	end

	if self._inputConnections[prompt] then
		self._inputConnections[prompt]:Disconnect()
		self._inputConnections[prompt] = nil
	end

	if self.OnDisabled then
    	self:OnDisabled(prompt)
    end
end

function CustomPromptTemplate:Use(prompt: ProximityPrompt)
	if not prompt then
		warn("prompt not found while using custom prompt")
	end

    self:OnUsed(prompt)
	self:Disable(prompt)
end

return CustomPromptTemplate