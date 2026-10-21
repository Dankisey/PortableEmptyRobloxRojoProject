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

--[[
	Реестры обработчиков покупок. Заполняются СНАРУЖИ, через RegisterProduct:
	владелец товара — тот сервис, который его выдаёт, а не этот модуль.

	До этого таблицы были локальными и никто в них не писал вовсе — то есть
	монетизация была неработоспособна целиком: любая покупка получала
	NotProcessedYet и висла в очереди до появления обработчика.
]]
local productFunctions = {}
local gamepassFunctions = {}

--[[
	Привязать обработчик к дев-продукту. Зовётся из Initialize владеющего сервиса.

	handler получает (monetization, player, receiptInfo) и ОБЯЗАН вернуть true при
	успешной выдаче: любое другое значение трактуется как провал, и покупка
	останется в очереди вместо того, чтобы сгореть.

	HANDLER НЕ ИМЕЕТ ПРАВА ЙИЛДИТЬ. Он вызывается внутри трансформ-функции
	UpdateAsync ниже, а трансформ-колбэк DataStore не может йилдить вовсе:
	ни task.wait, ни WaitForChild, ни второго запроса к DataStore. Иначе —
	«Transform function error Callbacks cannot yield», и товар не выдаётся,
	а очередь запросов забивается.

	Требование это ничего не усложняет, потому что выдавать надо ровно в кэш:
	handler меняет папки игрока (и кэши сервисов-владельцев разделов сейва)
	и на этом заканчивается. На диск сейв уезжает один раз, на выходе игрока —
	SavesLoader другой записи не предоставляет вовсе.

	Цена известна и принята: падение сервера между покупкой и выходом теряет
	товар, а повторно выдать его нельзя — чек уже помечен выданным.

	Повторная регистрация одного ProductId — всегда ошибка в конфигах (один и тот
	же идентификатор у двух товаров), и молча перетирать первый обработчик нельзя.
]]
function Monetization:RegisterProduct(productId: number, handler: (any, Player, any) -> boolean)
	if type(productId) ~= "number" or type(handler) ~= "function" then
		warn(("Monetization: негодная регистрация продукта (%s, %s)")
			:format(tostring(productId), type(handler)))

		return
	end

	if productFunctions[productId] then
		warn(("Monetization: обработчик для ProductId %d уже зарегистрирован"):format(productId))

		return
	end

	productFunctions[productId] = handler
end

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

			--[[
				Обработчика нет — выдавать нечего. Возвращаем nil (NotProcessedYet):
				покупка останется в очереди и выдастся, когда обработчик появится,
				а не сгорит. Без проверки pcall просто падал на nil и давал ту же
				очередь, но без единой строки о причине.
			]]
			if type(rewardFunction) ~= "function" then
				warn("Monetization: нет обработчика для ProductId " .. tostring(receiptInfo.ProductId))

				return nil
			end

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

	local isDeveloper = self._configs.DevelopersConfig[player.UserId] and RunService:IsStudio() == false

	--[[
		Девелоперская выдача возможна, только если обработчик продукта вообще есть.
		Иначе это была индексация nil прямо в обработчике ремоута: падал весь вызов,
		и обычный промпт покупки тоже не показывался.
	]]
	if isDeveloper and type(productFunctions[productId]) == "function" then
		self._services.ServerMessagesSender:SendMessageToPlayer(player, "Default", "Developer purchase activated")
		productFunctions[productId](self, player, {ProductId = productId})

		return
	end

	MarketplaceService:PromptProductPurchase(player, productId)
end

function Monetization:PromptPass(player: Player, passId: number)
	local isDeveloper = self._configs.DevelopersConfig[player.UserId] and RunService:IsStudio() == false

	--[[ Как в PromptProduct: без обработчика это была индексация nil. ]]
	if isDeveloper and type(gamepassFunctions[passId]) == "function" then
		self._services.ServerMessagesSender:SendMessageToPlayer(player, "Default", "Developer purchase activated")
		gamepassFunctions[passId](self, player, passId)

		return
	end

	MarketplaceService:PromptGamePassPurchase(player, passId)
end

function Monetization:Initialize()
	--[[
		Возврат обязателен: nil Roblox трактует как NotProcessedYet, и покупка
		навсегда остаётся в очереди — игрока списали, товар не выдали,
		а ProcessReceipt зовётся заново при каждом его заходе на сервер.
	]]
	local function processReceipt(receiptInfo)
		return self:ProcessReciept(receiptInfo)
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