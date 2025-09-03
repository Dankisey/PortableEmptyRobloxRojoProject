local DataStoreService = game:GetService("DataStoreService")
local SavesDataStore = DataStoreService:GetDataStore("PlayersSavesData")

local ServerStorage = game:GetService("ServerStorage")
local PlayerData = ServerStorage.PlayerData

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KickRequested = ReplicatedStorage.Remotes.KickRequested

local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
local isUsingEmptySave = script:GetAttribute("UseEmptySave") and RunService:IsStudio()

local SavesLoader = {} :: ServiceTemplate.Type

local playersUsedCodes = {}

local function onPlayerAdded(self: ServiceTemplate.Type, player: Player)
	local success, value = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)

	if success == false then return player:Kick("Failed to load policy info") end

	local canPurchaseRandomItems = not value.ArePaidRandomItemsRestricted

	player:SetAttribute("CanPurchaseRandomItems", canPurchaseRandomItems)
	player:SetAttribute("OwnsPremium", player.MembershipType == Enum.MembershipType.Premium)
	player:SetAttribute("JoinTime", os.time())

	success, value = pcall(SavesDataStore.GetAsync, SavesDataStore, player.UserId)

	if success == false then return player:Kick("Save failed to load") end

	for _, attributePass in pairs(self._configs.GamepassesConfig.Attributes) do
		local result
		success, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, attributePass.GamepassId)

		if not success then
			warn("Error occured while MarketplaceService.UserOwnsGamePassAsync request. Error: " .. tostring(result))
			player:SetAttribute(attributePass.AttributeName, false)

			continue
		end

		player:SetAttribute(attributePass.AttributeName, result)
	end

	if isUsingEmptySave then
		value = nil
	end

	local data = value or {}

	for _, folder in pairs(PlayerData:GetChildren()) do
		local subData = data[folder.Name] or {}
		local clone = folder:Clone()

		for _, child in clone:GetChildren() do
			child.Value = subData[child.Name] or child.Value
		end

		clone.Parent = player
	end

	if player.FirstJoin.Time.Value == 0 then
		player.FirstJoin.Time.Value = os.time()
	end

	local usedCodes = data.UsedCodes or {}
	playersUsedCodes[player] = usedCodes

	self._services.Analytics:AddPlayer(player)
	self._services.ZonesService:RegisterPlayer(player)
	self._services.LeaderboardService:UpdateTotals(player)

	player:SetAttribute("IsLoaded", true)
	self._loadedPlayers[player.Name] = true
end

local function onPlayerRemoving(self: ServiceTemplate.Type, player: Player)
	if not self._loadedPlayers[player.Name] then return end

	self._services.Analytics:RemovePlayer(player)
	self._services.ZonesService:RemovePlayer(player)

	local data = {}

	for _, folder in pairs(PlayerData:GetChildren()) do
		local subData = {}

		for _, child in player[folder.Name]:GetChildren() do
			subData[child.Name] = child.Value
		end

		data[folder.Name] = subData
		player[folder.Name]:Destroy()
	end

	data.UsedCodes = playersUsedCodes[player]
	playersUsedCodes[player] = nil

	local joinTime = player:GetAttribute("JoinTime") or os.time()
	local playedTime = os.time() - joinTime
	data.TotalStats.TotalPlaytime += playedTime

	self._services.LeaderboardService:UpdateTotals(player)

	if not isUsingEmptySave then
		local success, value = pcall(SavesDataStore.SetAsync, SavesDataStore, player.UserId, data)

		if not success then
			warn("Saving progress was failed, reason: " .. tostring(value))
		end
	end

	self._loadedPlayers[player.Name] = nil
end

function SavesLoader:GetUsedCodes(player: Player)
	if playersUsedCodes[player] then
		return playersUsedCodes[player]
	end
end

function SavesLoader:AddUsedCode(player: Player, code: string)
	if not playersUsedCodes[player] then
		return
	end

	if table.find(playersUsedCodes[player], code) then
		return
	end

	table.insert(playersUsedCodes[player], code)
end

function SavesLoader:Initialize()
	for _, player: Player in pairs(Players:GetChildren()) do
		onPlayerAdded(self, player)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		onPlayerAdded(self, player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		onPlayerRemoving(self, player)
	end)

	KickRequested.OnServerEvent:Connect(function(player: Player, reason: string)
		player:Kick(reason)
	end)
end

function SavesLoader.new()
	local self = setmetatable(SavesLoader, {__index = ServiceTemplate})
	self._loadedPlayers = {}

	game:BindToClose(function()
		while next(self._loadedPlayers) ~= nil do
			task.wait()
		end
	end)

	return self
end

return SavesLoader