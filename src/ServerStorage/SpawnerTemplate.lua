--[[ lives next to ServiceTemplate, not in ServerCore: the framework turns every ServerCore child into a service ]]
local SpawnerTemplate = {}

--[[========================= methods copied onto the service =========================]]

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

-- a flat list, safe to iterate while the registry changes
function Methods:GetAll(): {any}
	local entries = {}

	for _, entry in self._entries do
		table.insert(entries, entry)
	end

	return entries
end

--[[ the limit is checked before removal: that is when the slot frees up and the respawn pause starts ]]
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

--[[ nil _nextSpawnClock means the timer is not running, not "spawn now": it resets at the limit so the countdown restarts after a slot frees ]]
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

--[[ the service update runs first: it may remove entries and free a slot ]]
local function tick(self)
	local spawner = self._spawner

	if spawner.OnUpdate then
		spawner.OnUpdate(self)
	end

	updateSpawning(self)
end

function Methods:StartSpawner()
	local spawner = self._spawner

	task.spawn(function()
		while true do
			task.wait(spawner.Config.UpdateInterval)

			local success, err = pcall(tick, self)

			if not success then
				warn(spawner.Name .. ": update loop error: " .. tostring(err))
			end
		end
	end)
end

--[[========================= setup =========================]]

--[[
	params: Name, Config (SpawnInterval, RespawnInterval, SpawnRetryInterval, UpdateInterval and the limit field),
	LimitKey, TrySpawn(self) -> boolean, OnRemove(self, entry, ...)?, ShouldSpawn(self) -> boolean?, OnUpdate(self)?
]]
function SpawnerTemplate.InitSpawner(self, params)
	assert(params.Config, "SpawnerTemplate: Config is missing")
	assert(params.LimitKey, "SpawnerTemplate: LimitKey is missing")
	assert(params.TrySpawn, "SpawnerTemplate: TrySpawn is missing")
	assert(params.Config[params.LimitKey], "SpawnerTemplate: config has no field " .. params.LimitKey)

	self._spawner = params
	self._entries = {}
	self._nextSpawnClock = nil
	self._nextId = 0

	--[[ copied directly: the service is a singleton on the module table and its __index is already taken by ServiceTemplate ]]
	for name, method in Methods do
		self[name] = method
	end

	return self
end

return SpawnerTemplate
