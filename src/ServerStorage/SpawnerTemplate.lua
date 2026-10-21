--[[
	SpawnerTemplate — общая машина популяции для сервисов, которые держат
	на карте ограниченный набор однотипных объектов: врагов, точек интереса,
	собираемых предметов.

	Общего у всех таких сервисов ровно это:
		• реестр по возрастающему id и подсчёт населения
		• лимит из конфига, при котором таймер спавна НЕ идёт вовсе
		• пауза RespawnInterval после того, как место освободилось
		• SpawnRetryInterval, если попытка спавна не удалась
		• цикл обновления с шагом UpdateInterval под pcall

	Различия (где спавнить, чем убирать, какие гейты) остаются у сервиса и приходят
	коллбэками в InitSpawner.

	Лежит рядом с ServiceTemplate, а НЕ в ServerCore: всё, что лежит в ServerCore,
	фреймворк превращает в сервис.

	Сервисы — синглтоны на самой таблице модуля и уже заняли свой __index под
	ServiceTemplate, поэтому методы копируются на сервис напрямую, а не через
	вторую метатаблицу.
]]

local SpawnerTemplate = {}

--[[========================= методы, которые получает сервис =========================]]

local Methods = {}

function Methods:NextId(): number
	self._nextId += 1

	return self._nextId
end

function Methods:AddEntry(id: number, entry: any)
	self._entries[id] = entry
end

function Methods:GetEntry(id: number): any
	return self._entries[id]
end

function Methods:Count(): number
	local count = 0

	for _ in self._entries do
		count += 1
	end

	return count
end

--[[ Плоский список — безопасно обходить, пока реестр меняется. ]]
function Methods:GetAll(): {any}
	local entries = {}

	for _, entry in self._entries do
		table.insert(entries, entry)
	end

	return entries
end

--[[
	Снять объект с учёта. Всё, что сверх учёта (убить модель, снести парт),
	делает OnRemove сервиса — туда же уходят дополнительные аргументы.

	Проверка лимита считается ДО удаления: именно тогда место считается
	освободившимся и включается пауза респавна.
]]
function Methods:Remove(id: number, ...)
	local entry = self._entries[id]

	if not entry then return end

	local spawner = self._spawner
	local wasAtLimit = self:Count() >= spawner.Config[spawner.LimitKey]

	self._entries[id] = nil

	if spawner.OnRemove then
		spawner.OnRemove(self, entry, ...)
	end

	if wasAtLimit then
		self._nextSpawnClock = os.clock() + spawner.Config.RespawnInterval
	end
end

function Methods:DespawnAll()
	for _, entry in self:GetAll() do
		self:Remove(entry.Id)
	end

	self._nextSpawnClock = nil
end

--[[
	Хвост тика: гейт → лимит → таймер → попытка спавна.

	Нулевой _nextSpawnClock означает «таймер сейчас не идёт», а не «пора спавнить»:
	при лимите он сбрасывается, чтобы отсчёт начался заново после освобождения места.
]]
local function updateSpawning(self)
	local spawner = self._spawner
	local config = spawner.Config
	local now = os.clock()

	if spawner.ShouldSpawn and not spawner.ShouldSpawn(self) then return end

	if self:Count() >= config[spawner.LimitKey] then
		self._nextSpawnClock = nil

		return
	end

	if self._nextSpawnClock == nil then
		self._nextSpawnClock = now + config.SpawnInterval

		return
	end

	if now < self._nextSpawnClock then return end

	if spawner.TrySpawn(self) then
		self._nextSpawnClock = nil
	else
		self._nextSpawnClock = now + config.SpawnRetryInterval
	end
end

local function tick(self)
	local spawner = self._spawner

	--[[ Своя часть тика идёт первой: она может снять объекты и освободить место. ]]
	if spawner.OnUpdate then
		spawner.OnUpdate(self)
	end

	updateSpawning(self)
end

--[[ Зовётся из Initialize сервиса. ]]
function Methods:StartSpawner()
	local spawner = self._spawner

	task.spawn(function()
		while true do
			task.wait(spawner.Config.UpdateInterval)

			local success, err = pcall(tick, self)

			if not success then
				warn(spawner.Name .. ": ошибка в цикле обновления: " .. tostring(err))
			end
		end
	end)
end

--[[========================= подключение =========================]]

--[[
	params:
		Name        : string   — имя сервиса для сообщений об ошибках
		Config      : table    — нужны SpawnInterval, RespawnInterval,
		                         SpawnRetryInterval, UpdateInterval и поле лимита
		LimitKey    : string   — имя поля лимита в конфиге (например "MaxSpots")
		TrySpawn    : (self) -> boolean        — true, если получилось
		OnRemove    : (self, entry, ...) -> () — убрать то, что сверх учёта
		ShouldSpawn : (self) -> boolean        — гейт перед спавном
		OnUpdate    : (self) -> ()             — своя часть тика
]]
function SpawnerTemplate.InitSpawner(self, params)
	assert(params.Config, "SpawnerTemplate: не передан Config")
	assert(params.LimitKey, "SpawnerTemplate: не передан LimitKey")
	assert(params.TrySpawn, "SpawnerTemplate: не передан TrySpawn")
	assert(params.Config[params.LimitKey], "SpawnerTemplate: в конфиге нет поля " .. params.LimitKey)

	self._spawner = params
	self._entries = {}
	self._nextSpawnClock = nil -- nil означает, что таймер сейчас не идёт
	self._nextId = 0

	for name, method in Methods do
		self[name] = method
	end

	return self
end

return SpawnerTemplate
