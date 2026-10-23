local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage.Remotes.Monetization
local GamepassRequested = Remotes.GamepassRequested
local DevProductRequested = Remotes.DevProductRequested

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)

local Monetization = {} :: ServiceTemplate.Type

local DeveloperPurchasesAttribute = "DeveloperPurchasesEnabled"
local PurchasesHistoryStoreName = "PurchasesHistory"

--[[ filled from outside through RegisterProduct: the service that grants an item owns its handler ]]
local productFunctions = {}
local gamepassFunctions = {}

local purchasesHistoryStore = nil

--[[ lazy: GetDataStore on module load fails in an unpublished place and the whole module is lost ]]
local function getPurchasesHistoryStore(): DataStore
	if not purchasesHistoryStore then
		purchasesHistoryStore = DataStoreService:GetDataStore(PurchasesHistoryStoreName)
	end

	return purchasesHistoryStore
end

local function isDeveloperPurchase(self, player: Player): boolean
	return script:GetAttribute(DeveloperPurchasesAttribute) == true and self._configs.DevelopersConfig[player.UserId] == true
end

local function onGamepassPurchaseCompleted(self, player: Player, gamePassId: number)
	if not gamepassFunctions[gamePassId] then
		warn("Function for pass id " .. gamePassId .. " was not found!")

		return
	end

	gamepassFunctions[gamePassId](self, player, gamePassId)
end

--[[ the handler runs inside an UpdateAsync transform: it must not yield and must return true, or the receipt stays queued ]]
function Monetization:RegisterProduct(productId: number, handler: (any, Player, any) -> boolean)
	if type(productId) ~= "number" or type(handler) ~= "function" then
		warn(("Monetization: invalid product registration (%s, %s)"):format(tostring(productId), type(handler)))

		return
	end

	if productFunctions[productId] then
		warn(("Monetization: a handler for ProductId %d is already registered"):format(productId))

		return
	end

	productFunctions[productId] = handler
end

--[[ the handler runs after PromptGamePassPurchaseFinished and on free developer purchases; ownership on join is read by the pass owner itself ]]
function Monetization:RegisterPass(passId: number, handler: (any, Player, number) -> ())
	if type(passId) ~= "number" or type(handler) ~= "function" then
		warn(("Monetization: invalid pass registration (%s, %s)"):format(tostring(passId), type(handler)))

		return
	end

	if gamepassFunctions[passId] then
		warn(("Monetization: a handler for pass %d is already registered"):format(passId))

		return
	end

	gamepassFunctions[passId] = handler
end

-- blocks the calling thread: reads and writes the purchases history DataStore
function Monetization:ProcessReceipt(receiptInfo)
	local store = getPurchasesHistoryStore()
	local playerProductKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId
	local success, result, errorMessage
	local isPurchased = false

	success, errorMessage = pcall(function()
		isPurchased = store:GetAsync(playerProductKey)
	end)

	if success and isPurchased then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif not success then
		error("Data store error:" .. errorMessage)
	end

	success, result = pcall(function()
		return store:UpdateAsync(playerProductKey, function(isAlreadyPurchased)
			if isAlreadyPurchased then return true end

			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

			if not player then return nil end

			local rewardFunction = productFunctions[receiptInfo.ProductId]

			--[[ nil keeps the receipt queued until a handler exists instead of burning the purchase ]]
			if type(rewardFunction) ~= "function" then
				warn("Monetization: no handler for ProductId " .. tostring(receiptInfo.ProductId))

				return nil
			end

			local isGranted, grantError = pcall(rewardFunction, self, player, receiptInfo)

			if not isGranted or not grantError then
				error("Failed to process a product purchase for ProductId: " .. tostring(receiptInfo.ProductId) .. " Player: " .. tostring(player) .. " Error: " .. tostring(grantError))
			end

			return true
		end)
	end)

	if not success or result == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Monetization:PromptProduct(player: Player, productId: number)
	if isDeveloperPurchase(self, player) and type(productFunctions[productId]) == "function" then
		self._services.ServerMessagesSender:SendMessageToPlayer(player, "Default", "Developer purchase activated")
		productFunctions[productId](self, player, {ProductId = productId})

		return
	end

	MarketplaceService:PromptProductPurchase(player, productId)
end

function Monetization:PromptPass(player: Player, passId: number)
	if isDeveloperPurchase(self, player) and type(gamepassFunctions[passId]) == "function" then
		self._services.ServerMessagesSender:SendMessageToPlayer(player, "Default", "Developer purchase activated")
		gamepassFunctions[passId](self, player, passId)

		return
	end

	MarketplaceService:PromptGamePassPurchase(player, passId)
end

function Monetization:AreDeveloperPurchasesEnabled(): boolean
	return script:GetAttribute(DeveloperPurchasesAttribute) == true
end

--[[ server wide: every developer on this server buys for free while it is on ]]
function Monetization:SetDeveloperPurchasesEnabled(isEnabled: boolean)
	script:SetAttribute(DeveloperPurchasesAttribute, isEnabled == true)
end

function Monetization:GetDeveloperPurchasesChangedSignal(): RBXScriptSignal
	return script:GetAttributeChangedSignal(DeveloperPurchasesAttribute)
end

function Monetization:Initialize()
	--[[ a nil return reads as NotProcessedYet: Robux are charged, nothing is granted, and the receipt repeats on every join ]]
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessReceipt(receiptInfo)
	end

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
	return setmetatable(Monetization, {__index = ServiceTemplate})
end

return Monetization
