local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PolicyService = game:GetService("PolicyService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local KickRequested = ReplicatedStorage.Remotes.KickRequested

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
local ProfileStore = require(ServerStorage.ProfileStore)
local SavesConfig = require(ReplicatedStorage.Configs.SavesConfig)

local SavesLoader = {} :: ServiceTemplate.Type

--[[ служебная статистика — собственный раздел загрузчика, на клиент не уходит ]]
SavesLoader.SaveSection = "Stats"

--[[ флаг работает только в Studio: забытый включённым, он не уедет на прод ]]
local isUsingEmptySave = SavesConfig.UseEmptySave and RunService:IsStudio()

ProfileStore.SetConstant("AUTO_SAVE_PERIOD", SavesConfig.AutoSavePeriod)

--[[ схемы здесь нет: раздел и его значения по умолчанию принадлежат сервису-владельцу ]]
local Store = ProfileStore.New(SavesConfig.DataStoreName, {})

--[[ Mock — отдельный фальшивый стор: из него в DataStore не уезжает ничего ]]
local SessionStore = if isUsingEmptySave then Store.Mock else Store

local function readNumber(value: any): number?
	return if type(value) == "number" and value == value then value else nil
end

--[[========================= владельцы разделов =========================]]

--[[ считается каждый раз заново: дёшево и не зависит от порядка Initialize ]]
local function getSectionOwners(self): {[string]: any}
	local owners = {}

	for _, service in self._services do
		local section = type(service) == "table" and rawget(service, "SaveSection")

		if type(section) ~= "string" then continue end

		if type(service.LoadSave) ~= "function" or type(service.GetSave) ~= "function" then
			warn(("SavesLoader: раздел %s объявлен, но LoadSave/GetSave нет"):format(section))

			continue
		end

		owners[section] = service
	end

	return owners
end

--[[ НЕ ЙИЛДИТ: зовётся из Profile.OnSave прямо перед каждой записью, включая автосейв ]]
local function syncToProfile(self, player: Player)
	local profile = self._profiles[player]

	if not profile or not profile:IsActive() then return end
	-- после /wipe кэши сервисов ещё полны, а профиль уже пуст: их запись вернула бы стёртое
	if self._wiped[player] then return end

	for section, service in getSectionOwners(self) do
		local sectionData = service:GetSave(player)

		--[[ nil — «сейв не читался»: запись пустоты стёрла бы прогресс, которого мы не видели ]]
		if sectionData ~= nil then
			profile.Data[section] = sectionData
		end
	end
end

--[[========================= свой раздел: статистика =========================]]

function SavesLoader:LoadSave(player: Player, data: any)
	data = type(data) == "table" and data or {}

	self._stats[player] = {
		FirstJoin = readNumber(data.FirstJoin) or os.time();
		TotalPlaytime = readNumber(data.TotalPlaytime) or 0;
	}
end

--[[ время игры считается от базы на входе, а не приращением: запись идёт много раз за сессию ]]
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

--[[========================= вход =========================]]

--[[ провал политики — не повод кикать: ограничение считаем включённым ]]
local function applyAttributes(self, player: Player)
	local success, policy = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)

	player:SetAttribute("CanPurchaseRandomItems", success and not policy.ArePaidRandomItemsRestricted or false)
	player:SetAttribute("OwnsPremium", player.MembershipType == Enum.MembershipType.Premium)
	player:SetAttribute("JoinTime", os.time())

	for _, attributePass in self._configs.GamepassesConfig.Attributes do
		local owns
		success, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, attributePass.GamepassId)

		if not success then
			warn("SavesLoader: не удалось проверить геймпасс: " .. tostring(owns))
		end

		player:SetAttribute(attributePass.AttributeName, success and owns or false)
	end
end

-- блокирует вызывающий поток: ждёт, пока прошлый сервер отпустит лок сессии
local function startSession(self, player: Player)
	--[[ без Cancel ушедший во время ожидания игрок держал бы и поток, и ключ ]]
	local profile = SessionStore:StartSessionAsync(SavesConfig.GetProfileKey(player), {
		Cancel = function()
			return player.Parent ~= Players
		end;
	})

	if not profile then return nil end

	profile:AddUserId(player.UserId)

	--[[ сессию угнал другой сервер: писать больше нечем, играть дальше нельзя ]]
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

		--[[ без сейва атрибутов прогресса нет, и счётчики честно остаются в «...» ]]
		warn(("SavesLoader: игрок %s играет без сейва"):format(player.Name))
		player:SetAttribute("IsLoaded", true)

		return
	end

	--[[ разделы раздаются строго ДО IsLoaded: клиент читает их в AfterPlayerLoaded ]]
	for section, service in getSectionOwners(self) do
		service:LoadSave(player, profile.Data[section])
	end

	--[[ IsLoaded значит «загрузка закончилась», а не «удачно»: без него клиент висел бы на старте ]]
	player:SetAttribute("IsLoaded", true)
end

--[[========================= выход =========================]]

--[[ синк ДО EndSession: после конца сессии правки profile.Data не гарантированы ]]
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

--[[========================= запись =========================]]

-- НЕ ЙИЛДИТ; false значит «сессии нет, писать некуда», а не «запись не удалась»
function SavesLoader:Save(player: Player): boolean
	local profile = self._profiles[player]

	if not profile or not profile:IsActive() then return false end

	syncToProfile(self, player)
	profile:Save()

	return true
end

--[[ НИКОГДА НЕ ЙИЛДИТ: единственный допустимый вариант внутри обработчика покупки ]]
function SavesLoader:RequestSave(player: Player)
	local profile = self._profiles[player]

	if not profile or not profile:IsActive() then return end

	syncToProfile(self, player)

	-- запись уже запланирована: она увезёт и это изменение
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

-- стирает сейв целиком и кикает; false = сессии нет, стирать нечего
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

local function createWipeCommand(self)
	local command = Instance.new("TextChatCommand")
	command.Name = "WipeCommand"
	command.PrimaryAlias = SavesConfig.WipeCommandAlias
	command.Parent = TextChatService

	command.Triggered:Connect(function(textSource: TextSource)
		local player = Players:GetPlayerByUserId(textSource.UserId)

		if not player or not self._configs.DevelopersConfig[player.UserId] then return end

		self:WipeSave(player)
	end)
end

--[[ BindToClose не нужен: ProfileStore ставит свой и сам закрывает все сессии ]]
function SavesLoader:Initialize()
	--[[ Connect ДО обхода: onPlayerAdded йилдит, и вошедший во время обхода иначе не получил бы IsLoaded ]]
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

	createWipeCommand(self)
end

function SavesLoader.new()
	local self = setmetatable(SavesLoader, {__index = ServiceTemplate})

	self._profiles = {}   -- [Player] = Profile
	self._lastSave = {}   -- [Player] = os.clock() последней форсированной записи
	self._saveTasks = {}  -- [Player] = отложенная запись
	self._stats = {}      -- [Player] = {FirstJoin, TotalPlaytime на момент входа}
	self._wiped = {}      -- [Player] = true после /wipe: кэши сервисов в профиль больше не пишутся

	return self
end

return SavesLoader
