local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PolicyService = game:GetService("PolicyService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local KickRequested = ReplicatedStorage.Remotes.KickRequested

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
local ProfileStore = require(ServerStorage.ProfileStore)
local SavesConfig = require(ReplicatedStorage.Configs.SavesConfig)

local SavesLoader = {} :: ServiceTemplate.Type

SavesLoader.SaveSection = "Stats"

--[[ Studio only: a flag left on by mistake must not reach the live game ]]
local isUsingEmptySave = SavesConfig.UseEmptySave and RunService:IsStudio()

ProfileStore.SetConstant("AUTO_SAVE_PERIOD", SavesConfig.AutoSavePeriod)

--[[ no schema here: each section and its defaults belong to the owning service ]]
local Store = ProfileStore.New(SavesConfig.DataStoreName, {})

--[[ Mock is a separate fake store: nothing from it reaches the DataStore ]]
local SessionStore = if isUsingEmptySave then Store.Mock else Store

local function readNumber(value: any): number?
	return if type(value) == "number" and value == value then value else nil
end

--[[========================= section owners =========================]]

--[[ rebuilt on every call: cheap and independent of Initialize order ]]
local function getSectionOwners(self): {[string]: any}
	local owners = {}

	for _, service in self._services do
		local section = type(service) == "table" and rawget(service, "SaveSection")

		if type(section) ~= "string" then continue end

		if type(service.LoadSave) ~= "function" or type(service.GetSave) ~= "function" then
			warn(("SavesLoader: section %s is declared without LoadSave/GetSave"):format(section))

			continue
		end

		owners[section] = service
	end

	return owners
end

--[[ must not yield: Profile.OnSave calls it right before every write, autosave included ]]
local function syncToProfile(self, player: Player)
	local profile = self._profiles[player]

	if not profile or not profile:IsActive() then return end

	--[[ after a wipe the service caches are still full while the profile is empty: writing them back would restore the wiped data ]]
	if self._wiped[player] then return end

	for section, service in getSectionOwners(self) do
		local sectionData = service:GetSave(player)

		--[[ nil means the save was never read: writing it would erase progress this server has not seen ]]
		if sectionData ~= nil then
			profile.Data[section] = sectionData
		end
	end
end

--[[========================= own section: stats =========================]]

function SavesLoader:LoadSave(player: Player, data: any)
	data = type(data) == "table" and data or {}

	self._stats[player] = {
		FirstJoin = readNumber(data.FirstJoin) or os.time();
		TotalPlaytime = readNumber(data.TotalPlaytime) or 0;
	}
end

--[[ playtime is counted from the join base, not incrementally: the profile is written many times per session ]]
function SavesLoader:GetSave(player: Player): any
	local stats = self._stats[player]

	if not stats then return nil end

	local now = os.time()

	return {
		FirstJoin = stats.FirstJoin;
		LastExit = now;
		TotalPlaytime = stats.TotalPlaytime + (now - (player:GetAttribute("JoinTime") or now));
	}
end

function SavesLoader:UnloadSave(player: Player)
	self._stats[player] = nil
end

--[[========================= join =========================]]

--[[ a failed policy request is no reason to kick: treat the restriction as active ]]
local function applyAttributes(self, player: Player)
	local success, policy = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)

	player:SetAttribute("CanPurchaseRandomItems", success and not policy.ArePaidRandomItemsRestricted or false)
	player:SetAttribute("OwnsPremium", player.MembershipType == Enum.MembershipType.Premium)
	player:SetAttribute("JoinTime", os.time())

	for _, attributePass in self._configs.GamepassesConfig.Attributes do
		local owns
		success, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, attributePass.GamepassId)

		if not success then
			warn("SavesLoader: could not check game pass: " .. tostring(owns))
		end

		player:SetAttribute(attributePass.AttributeName, success and owns or false)
	end
end

-- blocks the calling thread: waits until the previous server releases the session lock
local function startSession(self, player: Player)
	--[[ without Cancel a player who left while waiting would keep both the thread and the key ]]
	local profile = SessionStore:StartSessionAsync(SavesConfig.GetProfileKey(player), {
		Cancel = function()
			return player.Parent ~= Players
		end;
	})

	if not profile then return nil end

	profile:AddUserId(player.UserId)

	profile.OnSessionEnd:Connect(function()
		self._profiles[player] = nil

		if player.Parent == Players and not self._wiped[player] then
			player:Kick(SavesConfig.SessionEndedMessage)
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession()

		return nil
	end

	self._profiles[player] = profile

	profile.OnSave:Connect(function()
		syncToProfile(self, player)
	end)

	return profile
end

local function onPlayerAdded(self, player: Player)
	applyAttributes(self, player)

	local profile = startSession(self, player)

	if not profile then
		if SavesConfig.KickOnLoadFail and player.Parent == Players then
			return player:Kick(SavesConfig.KickMessage)
		end

		warn(("SavesLoader: player %s plays without a save"):format(player.Name))
		player:SetAttribute("IsLoaded", true)

		return
	end

	--[[ sections are handed out strictly before IsLoaded: the client reads them in AfterPlayerLoaded ]]
	for section, service in getSectionOwners(self) do
		service:LoadSave(player, profile.Data[section])
	end

	--[[ IsLoaded means "loading finished", not "succeeded": without it the client would hang on start ]]
	player:SetAttribute("IsLoaded", true)
end

--[[========================= leave =========================]]

--[[ sync before EndSession: profile.Data edits are not guaranteed after the session ends ]]
local function onPlayerRemoving(self, player: Player)
	local profile = self._profiles[player]
	local scheduled = self._saveTasks[player]

	if scheduled then
		task.cancel(scheduled)
		self._saveTasks[player] = nil
	end

	if profile then
		syncToProfile(self, player)
		profile:EndSession()
	end

	self._profiles[player] = nil
	self._lastSave[player] = nil
	self._wiped[player] = nil

	for _, service in getSectionOwners(self) do
		if type(service.UnloadSave) == "function" then
			service:UnloadSave(player)
		end
	end
end

--[[========================= write =========================]]

-- does not yield; false = no session to write to, not a failed write
function SavesLoader:Save(player: Player): boolean
	local profile = self._profiles[player]

	if not profile or not profile:IsActive() then return false end

	syncToProfile(self, player)
	profile:Save()

	return true
end

--[[ never yields: the only save call allowed inside a purchase handler ]]
function SavesLoader:RequestSave(player: Player)
	local profile = self._profiles[player]

	if not profile or not profile:IsActive() then return end

	syncToProfile(self, player)

	if self._saveTasks[player] then return end

	local lastSave = self._lastSave[player]
	local delay = lastSave and math.max(0, SavesConfig.SaveInterval - (os.clock() - lastSave)) or 0

	self._saveTasks[player] = task.delay(delay, function()
		self._saveTasks[player] = nil
		self._lastSave[player] = os.clock()

		self:Save(player)
	end)
end

function SavesLoader:IsLoaded(player: Player): boolean
	return self._profiles[player] ~= nil
end

-- false = no session, nothing to wipe
function SavesLoader:WipeSave(player: Player): boolean
	local profile = self._profiles[player]

	if not profile or not profile:IsActive() then return false end

	local scheduled = self._saveTasks[player]

	if scheduled then
		task.cancel(scheduled)
		self._saveTasks[player] = nil
	end

	self._wiped[player] = true
	table.clear(profile.Data)
	profile:EndSession()
	player:Kick(SavesConfig.WipeMessage)

	return true
end

--[[ no BindToClose: ProfileStore binds its own and closes every session ]]
function SavesLoader:Initialize()
	--[[ connect before the loop: onPlayerAdded yields, and a player joining during the loop would never get IsLoaded ]]
	Players.PlayerAdded:Connect(function(player: Player)
		onPlayerAdded(self, player)
	end)

	for _, player: Player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, self, player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		onPlayerRemoving(self, player)
	end)

	KickRequested.OnServerEvent:Connect(function(player: Player, reason: string)
		player:Kick(reason)
	end)
end

function SavesLoader.new()
	local self = setmetatable(SavesLoader, {__index = ServiceTemplate})

	self._profiles = {} -- [Player] = Profile
	self._lastSave = {} -- [Player] = os.clock() of the last forced write
	self._saveTasks = {} -- [Player] = scheduled write
	self._stats = {} -- [Player] = {FirstJoin, TotalPlaytime at join}
	self._wiped = {} -- [Player] = true after a wipe: service caches are no longer written to the profile

	return self
end

return SavesLoader
