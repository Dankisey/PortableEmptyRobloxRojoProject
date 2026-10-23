local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local StateChanged = ReplicatedStorage.Remotes.Ragdoll.StateChanged

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
local CharacterUtils = require(ReplicatedStorage.Modules.Utils.CharacterUtils)
local CollisionConfig = require(ReplicatedStorage.Configs.CollisionConfig)

--[[ state and signals only: the server does not own the character, so RagdollController builds the pose and impulse on every client ]]
local RagdollService = {} :: ServiceTemplate.Type

--[[========================= state =========================]]

function RagdollService:IsRagdolled(player: Player): boolean
	return self._active[player] ~= nil
end

function RagdollService:IsImmune(player: Player): boolean
	if self._active[player] then return true end

	local immuneUntil = self._immuneUntil[player]

	return immuneUntil ~= nil and os.clock() < immuneUntil
end

function RagdollService:GrantImmunity(player: Player, duration: number)
	local immuneUntil = os.clock() + math.max(0, tonumber(duration) or 0)

	if (self._immuneUntil[player] or 0) < immuneUntil then
		self._immuneUntil[player] = immuneUntil
	end
end

--[[========================= signals =========================]]

--[[ raw pose switch without timers or immunity, for scenes that decide when to stand up themselves ]]
function RagdollService:SetRagdoll(player: Player, enabled: boolean, impulse: Vector3?)
	if not player or not player.Parent then return end

	StateChanged:FireAllClients(player, enabled, impulse)
end

local function finishKnockdown(self, player: Player, session: number)
	local state = self._active[player]

	if not state or state.Session ~= session then return end

	self._active[player] = nil

	self:SetRagdoll(player, false)
	self:GrantImmunity(player, state.Immunity)

	self.RagdollEnded:Invoke(player)
end

-- options: duration number or {Duration, Immunity (after standing up), Impulse}; false = no character, already down or immune
function RagdollService:Knockdown(player: Player, options: ({[string]: any} | number)?): boolean
	if not player or not player.Parent then return false end

	if self:IsImmune(player) then return false end

	local character = CharacterUtils.GetAlive(player)

	if not character then return false end

	if type(options) == "number" then
		options = {Duration = options}
	end

	options = options or {}

	local duration = tonumber(options.Duration) or 3
	local immunity = tonumber(options.Immunity) or 0
	local impulse = if typeof(options.Impulse) == "Vector3" then options.Impulse else nil

	self._session += 1

	local session = self._session

	self._active[player] = {
		Session = session;
		Immunity = immunity;
		StartedAt = os.clock();
	}

	--[[ the event fires before the client signal: subscribers abort their action before the player goes limp, so it cannot report success ]]
	self.RagdollStarted:Invoke(player, duration)
	self:SetRagdoll(player, true, impulse)

	task.delay(duration, function()
		finishKnockdown(self, player, session)
	end)

	return true
end

function RagdollService:Cancel(player: Player)
	local state = self._active[player]

	if not state then return end

	finishKnockdown(self, player, state.Session)
end

--[[ no SetNetworkOwner: taking ownership does not push the body, it freezes it with the velocity left in the property ]]

--[[ DescendantAdded is required: accessories arrive after the character and tools are created on a live one ]]
local function applyCharacterGroup(character: Model)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = CollisionConfig.Character
		end
	end

	character.DescendantAdded:Connect(function(descendant: Instance)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = CollisionConfig.Character
		end
	end)
end

--[[ in code, not the editor: assigning an unregistered group throws, and the first CharacterAdded would kill this service ]]
local function registerCollisionGroups()
	for _, groupName in CollisionConfig.Groups do
		if PhysicsService:IsCollisionGroupRegistered(groupName) then continue end

		local success, err = pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, groupName)

		if not success then
			warn(("RagdollService: could not register group %s: %s"):format(groupName, tostring(err)))
		end
	end

	for _, rule in CollisionConfig.Rules do
		local success, err = pcall(PhysicsService.CollisionGroupSetCollidable, PhysicsService, rule[1], rule[2], rule[3])

		if not success then
			warn(("RagdollService: could not set rule %s-%s: %s"):format(rule[1], rule[2], tostring(err)))
		end
	end
end

function RagdollService:Initialize()
	registerCollisionGroups()

	local function onPlayerAdded(player: Player)
		if player.Character then
			applyCharacterGroup(player.Character)
		end

		player.CharacterAdded:Connect(function(character: Model)
			applyCharacterGroup(character)

			--[[ through finishKnockdown: it fires RagdollEnded and grants immunity, otherwise a player who died knocked down is a valid target on spawn ]]
			local state = self._active[player]

			if not state then return end

			finishKnockdown(self, player, state.Session)
		end)
	end

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)

	Players.PlayerRemoving:Connect(function(player: Player)
		self._immuneUntil[player] = nil
		self._active[player] = nil
	end)
end

function RagdollService:InjectUtils(utils)
	self.RagdollStarted = utils.Event.new()
	self.RagdollEnded = utils.Event.new()
	self._utils = utils
end

function RagdollService.new()
	local self = setmetatable(RagdollService, {__index = ServiceTemplate})

	self._active = {} -- [Player] = {Session, Immunity, StartedAt}
	self._immuneUntil = {} -- [Player] = os.clock()
	self._session = 0

	return self
end

return RagdollService
