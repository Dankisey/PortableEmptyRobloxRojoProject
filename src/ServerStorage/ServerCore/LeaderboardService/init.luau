local LeaderboardClass = require(script:WaitForChild("Leaderboard"))
local DummyClass = require(script:WaitForChild("Dummy"))

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
local LeaderboardService = {}

local updatingTime = 60

local function startUpdating(self)
	while true do
		for statName: string, dataStore in pairs(self._dataStores) do
			local success, value = pcall(function()
				return dataStore:GetSortedAsync(false, 100)
			end)

			if not success then
				task.wait(updatingTime)

				continue
			end

			local page = value:GetCurrentPage()

			for _, leaderboard in pairs(self._physicalLeaderboards[statName]) do
				leaderboard:Update(page)
			end

			if not page[1] then continue end

			local leaderUserId = tonumber(page[1].key)

			for _, dummy in pairs(self._leaderboardDummies[statName]) do
				dummy:SetPlayer(leaderUserId)
			end
		end

		task.wait(updatingTime)
	end
end

local function addLeaderboard(self, leaderboardModel: Model)
	if not leaderboardModel:GetAttribute("Stat") then
		leaderboardModel:GetAttributeChangedSignal("Stat"):Wait()
	end

	local statName = leaderboardModel:GetAttribute("Stat")

	if not self._dataStores[statName] then
		return warn("There is no datastore with name", statName)
	end

	if not self._physicalLeaderboards[statName] then
		self._physicalLeaderboards[statName] = {}
	end

	table.insert(self._physicalLeaderboards[statName], LeaderboardClass.new(leaderboardModel))
end

local function addDummy(self, dummyModel: Model)
	if not dummyModel:GetAttribute("Stat") then
		dummyModel:GetAttributeChangedSignal("Stat"):Wait()
	end

	local statName = dummyModel:GetAttribute("Stat")

	if not self._dataStores[statName] then
		return warn("There is no datastore with name", statName)
	end

	if not self._leaderboardDummies[statName] then
		self._leaderboardDummies[statName] = {}
	end

	table.insert(self._leaderboardDummies[statName], DummyClass.new(dummyModel))
end


function LeaderboardService:UpdateTotals(player: Player)
	for statName, dataStore in pairs(self._dataStores) do
		if not player:FindFirstChild("TotalStats") then break end

		local valueObject = player.TotalStats:FindFirstChild(statName)

		if not valueObject then continue end

		local value = valueObject.Value

		pcall(dataStore.SetAsync, dataStore, player.UserId, value)
	end
end

function LeaderboardService.new()
	local self = setmetatable(LeaderboardService, {__index = ServiceTemplate})
	self._physicalLeaderboards = {}
	self._leaderboardDummies = {}
	self._dataStores = {}

	for _, leaderboard: Model in pairs(CollectionService:GetTagged("Leaderboard")) do
		addLeaderboard(self, leaderboard)
	end

	CollectionService:GetInstanceAddedSignal("Leaderboard"):Connect(function(object)
		addLeaderboard(self, object)
	end)

	for _, dummyModel: Model in pairs(CollectionService:GetTagged("LeaderboardDummy")) do
		addDummy(self, dummyModel)
	end

	CollectionService:GetInstanceAddedSignal("LeaderboardDummy"):Connect(function(object)
		addDummy(self, object)
	end)

	task.spawn(startUpdating, self)

	return self
end

return LeaderboardService