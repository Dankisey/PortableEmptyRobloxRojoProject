local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)

local SoftCurrencyService = {} :: ServiceTemplate.Type

SoftCurrencyService.SaveSection = "Currencies"

local Currencies = {"Cash"} -- currency name = name of the player attribute with its balance

local function isValidAmount(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value >= 0
end

local function readAmount(source: any, name: string): number
	local value = type(source) == "table" and source[name]

	return if isValidAmount(value) then value else 0
end

--[[========================= save =========================]]

function SoftCurrencyService:LoadSave(player: Player, data: any)
	data = type(data) == "table" and data or {}

	local balances, earned = {}, {}

	for _, name in Currencies do
		balances[name] = readAmount(data.Balances, name)
		earned[name] = readAmount(data.Earned, name)
		player:SetAttribute(name, balances[name])
	end

	self._data[player] = {Balances = balances, Earned = earned}
end

-- nil = the save was never read: SavesLoader leaves the section untouched
function SoftCurrencyService:GetSave(player: Player): any
	local data = self._data[player]

	if not data then return nil end

	return {Balances = table.clone(data.Balances), Earned = table.clone(data.Earned)}
end

function SoftCurrencyService:UnloadSave(player: Player)
	self._data[player] = nil
end

--[[========================= balance =========================]]

function SoftCurrencyService:GetCurrency(player: Player, currencyName: string): number?
	local data = self._data[player]

	return data and data.Balances[currencyName]
end

-- false = save not loaded, unknown currency or invalid amount
function SoftCurrencyService:AddCurrency(player: Player, currencyName: string, amount: number): boolean
	local data = self._data[player]

	if not data or data.Balances[currencyName] == nil or not isValidAmount(amount) then return false end

	data.Balances[currencyName] += amount
	data.Earned[currencyName] += amount
	player:SetAttribute(currencyName, data.Balances[currencyName])

	return true
end

function SoftCurrencyService:TrySpendCurrency(player: Player, currencyName: string, spentAmount: number, transactionType: Enum.AnalyticsEconomyTransactionType, itemSku: string?): boolean
	local data = self._data[player]
	local balance = data and data.Balances[currencyName]

	if balance == nil or not isValidAmount(spentAmount) then return false end

	if spentAmount > balance then
		self._services.ServerMessagesSender:SendMessageToPlayer(player, "Error", string.format("Not enough %s for purchase", currencyName))

		return false
	end

	data.Balances[currencyName] -= spentAmount
	player:SetAttribute(currencyName, data.Balances[currencyName])

	return true
end

function SoftCurrencyService.new()
	local self = setmetatable(SoftCurrencyService, {__index = ServiceTemplate})

	self._data = {} -- [Player] = {Balances = {[currency] = n}, Earned = {[currency] = n}}

	return self
end

return SoftCurrencyService
