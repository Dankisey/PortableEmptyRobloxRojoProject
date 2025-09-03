local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
local Analytics = {} :: ServiceTemplate.Type

-------------------------------------------------------
-------------------------------------------------------
--[[
	Keep in mind that sku in economies has a limit of 100 unique names,
	so spend it wisely. For example, instead of naming each decoration,
	you can generalize sku to “decoration” and use custom event with more
	detailed information to separate it
]]
-------------------------------------------------------
-------------------------------------------------------

local function validateEconomyInfo(player, currencyName: string, transactionType: Enum.AnalyticsEconomyTransactionType | string, itemSku: string?) : boolean
	local isSuccess, endingBalance = pcall(function()
		return player.Currencies[currencyName].Value
	end)

	if not isSuccess then
		warn(player.Name "'s " .. currencyName .. " value object was not found")

		return false
	end

	itemSku = itemSku or ""

	if typeof(transactionType) ~= "string" then
		transactionType = transactionType.Name
	end

	return true, endingBalance, itemSku, transactionType
end

function Analytics:LogCurrencySpending(player: Player, currencyName: string, amount: number, ...)
	local isValid, endingBalance, itemSku, transactionType = validateEconomyInfo(player, currencyName, ...)

	if not isValid then return end

	AnalyticsService:LogEconomyEvent(
		player,
		Enum.AnalyticsEconomyFlowType.Sink,
		currencyName,
		amount,
		endingBalance,
		transactionType,
		itemSku
	)
end

function Analytics:LogCurrencyIncome(player: Player, currencyName: string, amount: number, ...)
	local isValid, endingBalance, itemSku, transactionType = validateEconomyInfo(player, currencyName, ...)

	if not isValid then return end

	AnalyticsService:LogEconomyEvent(
		player,
		Enum.AnalyticsEconomyFlowType.Source,
		currencyName,
		amount,
		endingBalance,
		transactionType,
		itemSku
	)
end

function Analytics:RemovePlayer(player: Player)
	self._playersAnalyticsInfo[player] = nil
end

function Analytics:AddPlayer(player: Player)
	self._playersAnalyticsInfo[player] = {}
	self._playersAnalyticsInfo[player].SessionId = HttpService:GenerateGUID(false)
end

function Analytics.new()
	local self = setmetatable(Analytics, {__index = ServiceTemplate})
	self._playersAnalyticsInfo = {}

	return self
end

return Analytics