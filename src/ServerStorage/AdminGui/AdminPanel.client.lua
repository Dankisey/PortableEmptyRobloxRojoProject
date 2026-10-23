local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gui = script.Parent
local CommandRequested = Gui.CommandRequested
local Panel = Gui.Panel
local Amount = Panel:FindFirstChild("Amount", true)

--[[ the live ClientCore singleton: the server gives the panel only after IsClientInitialized ]]
local ButtonsInteractionsConnector = require(ReplicatedStorage.ClientCore.ButtonsInteractionsConnector)
local AdminConfig = require(Gui.AdminConfig)

local confirmDeadlines = {} -- [TextButton] = os.clock() until which the second press counts

local function getLabel(button: GuiButton): TextLabel
	return button.Fill.Label
end

--[[ the server checks the number and answers garbage with an error ]]
local function send(name: string, command)
	if not command.NeedsAmount then return CommandRequested:FireServer(name) end

	local cleanText = Amount.Text:gsub("[%s,_]", "")

	CommandRequested:FireServer(name, tonumber(cleanText))
end

local function askConfirm(button: GuiButton, text: string)
	local deadline = os.clock() + AdminConfig.ConfirmWindow
	local label = getLabel(button)

	confirmDeadlines[button] = deadline
	label.Text = AdminConfig.ConfirmText

	task.delay(AdminConfig.ConfirmWindow, function()
		if confirmDeadlines[button] ~= deadline then return end

		confirmDeadlines[button] = nil
		label.Text = text
	end)
end

local function connectCommand(name: string, command)
	local button = Panel:FindFirstChild(name, true)

	if not button then return warn("AdminPanel: no button " .. name) end

	local text = getLabel(button).Text

	ButtonsInteractionsConnector:ConnectButton(button, function()
		local isWaitingConfirm = os.clock() <= (confirmDeadlines[button] or 0)

		if command.NeedsConfirm and not isWaitingConfirm then
			askConfirm(button, text)

			return
		end

		confirmDeadlines[button] = nil
		getLabel(button).Text = text
		send(name, command)
	end)
end

local function renderFreePurchases()
	local button = Panel:FindFirstChild("FreePurchases", true)

	if not button then return end

	local isEnabled = Gui:GetAttribute(AdminConfig.DeveloperPurchasesAttribute) == true
	local state = if isEnabled then "On" else "Off"

	getLabel(button).Text = AdminConfig.FreePurchasesText[state]
	button.Fill.BackgroundColor3 = AdminConfig.FreePurchasesColor[state]
	button.Shadow.BackgroundColor3 = AdminConfig.FreePurchasesColor[state]:Lerp(Color3.new(), .38)
end

local function setPanelVisible(isVisible: boolean)
	Panel.Visible = isVisible
end

Amount.Text = tostring(AdminConfig.DefaultAmount)

ButtonsInteractionsConnector:ConnectButton(Gui.Toggle, function()
	setPanelVisible(not Panel.Visible)
end)

ButtonsInteractionsConnector:ConnectButton(Panel.Close, function()
	setPanelVisible(false)
end)

for name, command in AdminConfig.Commands do
	connectCommand(name, command)
end

renderFreePurchases()
Gui:GetAttributeChangedSignal(AdminConfig.DeveloperPurchasesAttribute):Connect(renderFreePurchases)
