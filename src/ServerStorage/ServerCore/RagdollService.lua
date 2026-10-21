--[[
	RagdollService — состояние тряпичного режима и сигналы клиентам.

	Самой механики здесь нет: её целиком делает RagdollController. Сервер
	персонажем не владеет, поэтому ни поза, ни импульс, выставленные отсюда,
	не сработают — владелец их сбросит. Сервис отвечает за то, что должно
	быть авторитетным: кто сейчас лежит, у кого иммунитет и когда поднимать.

	Механике, которую рэгдолл обязан оборвать (начатое удержание кнопки,
	мини-игра), надо подписаться на RagdollStarted и оборвать себя самой:
	сервис о ней не знает.

	Сигнал уходит всем клиентам: рэгдолл, включённый локально, не реплицируется,
	поэтому позу собирает у себя каждый клиент.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local StateChanged = ReplicatedStorage.Remotes.Ragdoll.StateChanged

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
local CollisionConfig = require(ReplicatedStorage.Configs.CollisionConfig)
local CharacterUtils = require(ReplicatedStorage.Modules.Utils.CharacterUtils)

local RagdollService = {} :: ServiceTemplate.Type

--[[========================= состояние =========================]]

function RagdollService:IsRagdolled(player: Player): boolean
	return self._active[player] ~= nil
end

--[[
	Иммунитет от повторного сбивания и от выбора целью. Спрашивают его часто,
	поэтому храним просто момент времени, а не таймеры.
]]
function RagdollService:IsImmune(player: Player): boolean
	if self._active[player] then return true end

	local until_ = self._immuneUntil[player]

	return until_ ~= nil and os.clock() < until_
end

function RagdollService:GrantImmunity(player: Player, duration: number)
	local until_ = os.clock() + math.max(0, tonumber(duration) or 0)

	if (self._immuneUntil[player] or 0) < until_ then
		self._immuneUntil[player] = until_
	end
end

--[[========================= сигналы =========================]]

--[[
	Голое переключение позы без таймеров и иммунитета: нужно сценам,
	которые сами решают, когда поднять игрока (катсцены, свои состояния).

	impulse — стартовая скорость, применяется клиентом в том же кадре,
	что и сам рэгдолл.
]]
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

--[[
	Сбивает игрока с ног на duration секунд.

	options — таблица или просто число (тогда это длительность):
		Duration: number?   — сколько лежать
		Immunity: number?   — сколько держится иммунитет ПОСЛЕ вставания
		Impulse: Vector3?   — стартовый толчок

	Возвращает false, если сбить не вышло (нет персонажа, уже лежит, иммунитет).
]]
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

	--[[
		Событие поднимаем ДО сигнала клиентам: подписчики рвут своё начатое
		действие, и к моменту, когда игрок обмякнет, оборванная механика уже
		не пришлёт результат как успешный.
	]]
	self.RagdollStarted:Invoke(player, duration)
	self:SetRagdoll(player, true, impulse)

	task.delay(duration, function()
		finishKnockdown(self, player, session)
	end)

	return true
end

-- Досрочно поднять игрока (респавн, смена сцены и прочее)
function RagdollService:Cancel(player: Player)
	local state = self._active[player]

	if not state then return end

	finishKnockdown(self, player, state.Session)
end

--[[
	SetNetworkOwner здесь НЕ НУЖЕН и был удалён намеренно: отбор владения
	не ускоряет тело, а останавливает его совсем — скорость висит в свойстве,
	а игрок стоит на месте. Всё, что двигает персонажа физически, обязано
	жить на клиенте. Возвращать не надо.
]]

--[[
	Персонаж уходит в свою коллизионную группу — из неё игра настраивает,
	сквозь что он проходит. Ставит СЕРВЕР: группа это физическое свойство,
	и остальные клиенты обязаны видеть то же самое.

	DescendantAdded обязателен, а не «на всякий случай»: аксессуары приезжают
	в персонажа позже него самого, а тулы вообще создаются на уже живом.

	Рэгдоллу это не мешает: RagdollController запоминает прежнюю группу парта
	и возвращает её при подъёме — он вернёт Character, а не Default.
]]
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

--[[
	Завести группы и матрицу из CollisionConfig.

	Кодом, а не редактором: шаблон разворачивается в пустой плейс, а
	присваивание НЕЗАРЕГИСТРИРОВАННОЙ группы падает с ошибкой — то есть
	первый же CharacterAdded уронил бы этот сервис целиком.

	Повторная регистрация существующей группы безопасна, но обёрнута
	в pcall: имя может быть занято группой из редактора.
]]
local function registerCollisionGroups()
	for _, groupName in CollisionConfig.Groups do
		if PhysicsService:IsCollisionGroupRegistered(groupName) then continue end

		local success, err = pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, groupName)

		if not success then
			warn(("RagdollService: не удалось завести группу %s: %s"):format(groupName, tostring(err)))
		end
	end

	for _, rule in CollisionConfig.Rules do
		local success, err = pcall(PhysicsService.CollisionGroupSetCollidable, PhysicsService, rule[1], rule[2], rule[3])

		if not success then
			warn(("RagdollService: не удалось задать правило %s↔%s: %s"):format(rule[1], rule[2], tostring(err)))
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

			--[[
				Новый персонаж всегда целый: старое состояние надо снять,
				иначе клиент останется с заблокированными инструментами.

				Через finishKnockdown, а не напрямую: он же поднимает RagdollEnded
				и выдаёт иммунитет. Без этого игрок, умерший сбитым с ног,
				становился валидной целью в тот же тик, в котором появился.
			]]
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

	self._active = {}       -- [Player] = {Session, Immunity, StartedAt}
	self._immuneUntil = {}  -- [Player] = os.clock()
	self._session = 0

	return self
end

return RagdollService
