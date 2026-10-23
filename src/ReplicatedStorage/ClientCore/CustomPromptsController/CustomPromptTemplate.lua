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
	end
end

--[[ Active is the only way to make the prompt tappable, but it also sinks mouse input under the crosshair; touch only, same condition as the key label ]]
local function adaptInputToDevice(controlType: string, gui: BillboardGui): boolean
	local isTouch = controlType:match("Mobile") ~= nil

	gui.Active = isTouch

	return isTouch
end

function CustomPromptTemplate:Enable(prompt: ProximityPrompt)
	local part = prompt.Parent or prompt.AncestryChanged:Wait()
	self._guiPerPrompt[prompt] = self._gui:Clone()
	self._guiPerPrompt[prompt].Parent = PromptsGui
	self._guiPerPrompt[prompt].Adornee = part

	local controlType = self._inputController:GetControlType()
	adaptButtonTextToDevice(controlType, self._guiPerPrompt[prompt])

	local isTouch = adaptInputToDevice(controlType, self._guiPerPrompt[prompt])

	if self.OnEnabled then
		self:OnEnabled(prompt, self._guiPerPrompt[prompt])
	end

	local gui = self._guiPerPrompt[prompt]

	--[[ touch only: a connected button keeps a hover task and would treat a locked center cursor as hovering ]]
	if isTouch then
		task.spawn(function()
			local button = gui:WaitForChild("Background", 1)

			if not button then return end

			button = button:WaitForChild("ActivationButton", 1)

			if not button then return end

			if self._guiPerPrompt[prompt] ~= gui then return end

			self._buttonsInteractionsConnector:ConnectButton(button, self.Use, self, prompt)
		end)
	end

	self._inputConnections[prompt] = UserInputService.InputBegan:Connect(function(input)
		--[[ guard on typing, not gameProcessed: ProximityPromptService marks the key as processed, and every E would be eaten silently ]]
		if UserInputService:GetFocusedTextBox() then return end

		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
			self:Use(prompt)
		end
	end)

	--[[ the GUI lives as long as the prompt instance: PromptHidden does not come when the object is destroyed ]]
	self._ancestryConnections = self._ancestryConnections or {}
	self._ancestryConnections[prompt] = prompt.AncestryChanged:Connect(function(_, parent)
		if parent then return end

		self:Disable(prompt)
	end)

	self._guiPerPrompt[prompt].Enabled = true
end

function CustomPromptTemplate:Disable(prompt: ProximityPrompt)
	local gui = self._guiPerPrompt[prompt]

	if gui then
		self._guiPerPrompt[prompt] = nil

		--[[ disconnect before Destroy: the connector keeps a hover task per connected button ]]
		local background = gui:FindFirstChild("Background")
		local button = background and background:FindFirstChild("ActivationButton")

		if button then
			self._buttonsInteractionsConnector:DisconnectButton(button)
		end

		gui:Destroy()
	end

	if self._inputConnections[prompt] then
		self._inputConnections[prompt]:Disconnect()
		self._inputConnections[prompt] = nil
	end

	if self._ancestryConnections and self._ancestryConnections[prompt] then
		self._ancestryConnections[prompt]:Disconnect()
		self._ancestryConnections[prompt] = nil
	end

	if self.OnDisabled then
		self:OnDisabled(prompt)
	end
end

function CustomPromptTemplate:Use(prompt: ProximityPrompt)
	if not prompt then
		warn("prompt not found while using custom prompt")

		return
	end

	self:OnUsed(prompt)

	--[[ for prompts the server may refuse: PromptShown does not repeat, and a hidden prompt would be gone until the player walks away ]]
	if self.KeepShownOnUse then return end

	self:Disable(prompt)
end

return CustomPromptTemplate
