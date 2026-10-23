local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local AdminGui = ServerStorage.AdminGui

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
local AdminConfig = require(AdminGui.AdminConfig)

local AdminService = {} :: ServiceTemplate.Type

local function isAdmin(self, player: Player): boolean
	return self._configs.DevelopersConfig[player.UserId] == true
end

local function readAmount(value: any): number?
	if type(value) ~= "number" or value ~= value or value > AdminConfig.MaxAmount then return nil end

	value = math.floor(value)

	return if value >= 1 then value else nil
end

local function isRequestAllowed(self, player: Player): boolean
	local now = os.clock()

	if now - (self._lastRequest[player] or -math.huge) < AdminConfig.RequestCooldown then return false end

	self._lastRequest[player] = now

	return true
end

local function mirrorDeveloperPurchases(self)
	local isEnabled = self._services.Monetization:AreDeveloperPurchasesEnabled()

	for _, gui in self._guis do
		gui:SetAttribute(AdminConfig.DeveloperPurchasesAttribute, isEnabled)
	end
end

--[[========================= commands =========================]]

-- each returns a success message, "" when the service reports itself, or nil when the service refused
local commands = {
	AddCash = function(self, player: Player, amount: number): string?
		local isAdded = self._services.SoftCurrencyService:AddCurrency(player, AdminConfig.Currency, amount)

		return if isAdded then "+" .. self._utils.FormatNumber(amount) .. " " .. AdminConfig.Currency else nil
	end;

	Reset = function(self, player: Player): string?
		return if self._services.SavesLoader:WipeSave(player) then "" else nil
	end;

	FreePurchases = function(self): string?
		local monetization = self._services.Monetization
		local isEnabled = not monetization:AreDeveloperPurchasesEnabled()

		monetization:SetDeveloperPurchasesEnabled(isEnabled)

		return if isEnabled then AdminConfig.FreePurchasesText.On else AdminConfig.FreePurchasesText.Off
	end;
}

local function runCommand(self, player: Player, name: any, value: any)
	local command = type(name) == "string" and AdminConfig.Commands[name]

	if not command or not commands[name] or not isRequestAllowed(self, player) then return end

	local amount = readAmount(value)
	local messages = self._services.ServerMessagesSender

	if command.NeedsAmount and not amount then
		return messages:SendMessageToPlayer(player, "Error", "Enter a whole number from 1 to " .. self._utils.FormatNumber(AdminConfig.MaxAmount))
	end

	local result = commands[name](self, player, amount)

	if result == nil then
		messages:SendMessageToPlayer(player, "Error", name .. " failed: save is not loaded")
	elseif result ~= "" then
		messages:SendMessageToPlayer(player, "Success", result)
	end
end

--[[========================= panel delivery =========================]]

--[[ only the owner sees a remote inside a PlayerGui clone, but the protection is the sender check, not secrecy ]]
local function giveGui(self, player: Player)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")

	if not playerGui or playerGui:FindFirstChild(AdminGui.Name) then return end

	local gui = AdminGui:Clone()

	gui:SetAttribute(AdminConfig.DeveloperPurchasesAttribute, self._services.Monetization:AreDeveloperPurchasesEnabled())

	gui.CommandRequested.OnServerEvent:Connect(function(sender: Player, name: any, value: any)
		if sender ~= player or not isAdmin(self, sender) then return end

		runCommand(self, sender, name, value)
	end)

	self._guis[player] = gui
	gui.Parent = playerGui
end

local function giveWhenClientReady(self, player: Player)
	if not isAdmin(self, player) then return end

	if player:GetAttribute(AdminConfig.ClientReadyAttribute) then return giveGui(self, player) end

	local connection
	connection = player:GetAttributeChangedSignal(AdminConfig.ClientReadyAttribute):Connect(function()
		if not player:GetAttribute(AdminConfig.ClientReadyAttribute) then return end

		connection:Disconnect()
		giveGui(self, player)
	end)
end

function AdminService:Initialize()
	self._services.Monetization:GetDeveloperPurchasesChangedSignal():Connect(function()
		mirrorDeveloperPurchases(self)
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		giveWhenClientReady(self, player)
	end)

	for _, player in Players:GetPlayers() do
		giveWhenClientReady(self, player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		self._lastRequest[player] = nil
		self._guis[player] = nil
	end)
end

function AdminService.new()
	local self = setmetatable(AdminService, {__index = ServiceTemplate})

	self._lastRequest = {} -- [Player] = os.clock() of the last command
	self._guis = {} -- [Player] = AdminGui clone

	return self
end

return AdminService
