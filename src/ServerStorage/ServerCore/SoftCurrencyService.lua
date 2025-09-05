--local MarketplaceService = game:GetService("MarketplaceService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local SoundRequested = Remotes.SoundRequested

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
local SoftCurrencyService = {} :: ServiceTemplate.Type

--[[
local function promptCoinsProduct(self, player: Player, missingCoinsAmount: number)
	local currentVirtualCoinsValue = 0
	local coinsProductId = nil

	for productId, cashAmount in pairs(self._configs.DevProductsConfig.Coins) do
		local currentDifference = currentVirtualCoinsValue - missingCoinsAmount
		local difference = cashAmount - missingCoinsAmount

		if math.abs(difference) <= math.abs(currentDifference) or (currentDifference < 0 and difference > 0) then
			if currentDifference > 0 and difference < 0 then
				continue
			end

			currentVirtualCoinsValue = cashAmount
			coinsProductId = productId
		end
	end

	MarketplaceService:PromptProductPurchase(player, coinsProductId)
end
]]

function SoftCurrencyService:TrySpentCurrency(player: Player, currencyName: string, spentAmount: number, transactionType: Enum.AnalyticsEconomyTransactionType, itemSku: string?) : boolean
	local currencyObject: IntValue = player.Currencies[currencyName]

	if spentAmount > currencyObject.Value then
		SoundRequested:FireClient(player, self._configs.SoundNames.Error)
		self._services.ServerMessagesSender:SendMessageToPlayer(player, "Error", string.format("Not enough %s for purchase", currencyName))

		return false
	end

	currencyObject.Value -= spentAmount
	--self._services.Analytics:LogCurrencySpending(player, currencyName, spentAmount, transactionType, itemSku)

	return true
end

function SoftCurrencyService.new()
	local self = setmetatable(SoftCurrencyService, {__index = ServiceTemplate})

	return self
end

return SoftCurrencyService