local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Configs = ReplicatedStorage.Configs
local DevProductsConfig = require(Configs.DevProductsConfig)
local GamepassesConfig = require(Configs.GamepassesConfig)

local Remotes = ReplicatedStorage.Remotes.Monetization
local GamepassRequested = Remotes.GamepassRequested
local DevProductRequested = Remotes.DevProductRequested

local DataStoreService = game:GetService("DataStoreService")
local PurchasesHistoryStore = DataStoreService:GetDataStore("PurchasesHistory")

local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)

local Monetization = {} :: ServiceTemplate.Type

local productFunctions = {}
local gamepassFunctions = {}

function Monetization:ProcessReciept(receiptInfo)
	local playerProductKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId
	local success, result, errorMessage
	local isPurchased = false

	success, errorMessage = pcall(function()
		isPurchased = PurchasesHistoryStore:GetAsync(playerProductKey)
	end)

	if success and isPurchased then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif not success then
		error("Data store error:" .. errorMessage)
	end

	success, result = pcall(function()
		return PurchasesHistoryStore:UpdateAsync(playerProductKey, function(isAlreadyPurchased)
			if isAlreadyPurchased then return true end

			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

			if not player then return nil end

			local rewardFunction = productFunctions[receiptInfo.ProductId]
			local success2, result2 = pcall(rewardFunction, self, player, receiptInfo)

			if not success2 or not result2 then
				error("Failed to process a product purchase for ProductId: " .. tostring(receiptInfo.ProductId) .. " Player: " .. tostring(player) .. " Error: " .. tostring(result2))

				return nil
			end

			return true
		end)
	end)

	if not success then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	elseif result == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	else
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

local function onGamepassPurchaseCompleted(self, player: Player, gamePassId: number)
	if not gamepassFunctions[gamePassId] then
		warn("Function for pass id " .. gamePassId .. " was not found!")

		return
	end

	gamepassFunctions[gamePassId](self, player, gamePassId)
end

function Monetization:PromptProduct(player: Player, productId: number)
	local canPurchaseRandomItems = player:GetAttribute("CanPurchaseRandomItems")

	if self._configs.DevelopersConfig[player.UserId] and RunService:IsStudio() == false then
		self._services.ServerMessagesSender:SendMessageToPlayer(player, "Default", "Developer purchase activated")
		productFunctions[productId](self, player, {ProductId = productId})
	else
		MarketplaceService:PromptProductPurchase(player, productId)
	end
end

function Monetization:PromptPass(player: Player, passId: number)
	if self._configs.DevelopersConfig[player.UserId] and RunService:IsStudio() == false then
		self._services.ServerMessagesSender:SendMessageToPlayer(player, "Default", "Developer purchase activated")
		gamepassFunctions[passId](self, player, passId)
	else
		MarketplaceService:PromptGamePassPurchase(player, passId)
	end
end

function Monetization:Initialize()
	local function processReceipt(receiptInfo)
		self:ProcessReciept(receiptInfo)
	end

	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, gamePassId: number, wasPurchased: boolean)
		if not wasPurchased then return end

		onGamepassPurchaseCompleted(self, player, gamePassId)
	end)

	DevProductRequested.OnServerEvent:Connect(function(player: Player, productId: number)
		self:PromptProduct(player, productId)
	end)

	GamepassRequested.OnServerEvent:Connect(function(player: Player, passId: number)
		self:PromptPass(player, passId)
	end)
end

function Monetization.new()
	local self = setmetatable(Monetization, {__index = ServiceTemplate})

	return self
end

return Monetization