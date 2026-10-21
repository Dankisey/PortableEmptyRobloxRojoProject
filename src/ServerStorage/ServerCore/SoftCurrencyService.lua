local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)

local SoftCurrencyService = {} :: ServiceTemplate.Type

SoftCurrencyService.SaveSection = "Currencies"

-- имя валюты — оно же имя атрибута игрока с балансом
local Currencies = {"Cash"}

local function isValidAmount(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value >= 0
end

local function readAmount(source: any, name: string): number
	local value = type(source) == "table" and source[name]

	return if isValidAmount(value) then value else 0
end

--[[========================= сейв =========================]]

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

-- nil значит «сейв не читался»: SavesLoader такой раздел не трогает
function SoftCurrencyService:GetSave(player: Player): any
	local data = self._data[player]

	if not data then return nil end

	return {Balances = table.clone(data.Balances), Earned = table.clone(data.Earned)}
end

function SoftCurrencyService:UnloadSave(player: Player)
	self._data[player] = nil
end

--[[========================= баланс =========================]]

function SoftCurrencyService:GetCurrency(player: Player, currencyName: string): number?
	local data = self._data[player]

	return data and data.Balances[currencyName]
end

-- false значит «сейв не загружен», валюты нет или сумма не годится
function SoftCurrencyService:AddCurrency(player: Player, currencyName: string, amount: number): boolean
	local data = self._data[player]

	if not data or data.Balances[currencyName] == nil or not isValidAmount(amount) then return false end

	data.Balances[currencyName] += amount
	data.Earned[currencyName] += amount
	player:SetAttribute(currencyName, data.Balances[currencyName])

	return true
end

function SoftCurrencyService:TrySpentCurrency(player: Player, currencyName: string, spentAmount: number, transactionType: Enum.AnalyticsEconomyTransactionType, itemSku: string?): boolean
	local data = self._data[player]
	local balance = data and data.Balances[currencyName]

	if balance == nil or not isValidAmount(spentAmount) then return false end

	if spentAmount > balance then
		self._services.ServerMessagesSender:SendMessageToPlayer(player, "Error", string.format("Not enough %s for purchase", currencyName))

		return false
	end

	data.Balances[currencyName] -= spentAmount
	player:SetAttribute(currencyName, data.Balances[currencyName])
	--self._services.Analytics:LogCurrencySpending(player, currencyName, spentAmount, transactionType, itemSku)

	return true
end

function SoftCurrencyService.new()
	local self = setmetatable(SoftCurrencyService, {__index = ServiceTemplate})

	self._data = {}  -- [Player] = {Balances = {[currency] = n}, Earned = {[currency] = n}}

	return self
end

return SoftCurrencyService
