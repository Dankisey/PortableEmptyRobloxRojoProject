--[[
	RagdollController — вся механика тряпичного состояния.

	Сервер её не трогает вовсе: RagdollService только держит состояние
	(кто лежит, у кого иммунитет) и рассылает сигнал. Причина в физике —
	персонажем владеет его клиент, и только он может реально его толкнуть.
	Серверный AssemblyLinearVelocity владелец просто сбрасывает, а если
	забрать владение через SetNetworkOwner(nil), тело вообще перестаёт
	симулироваться: скорость висит в свойстве, а игрок стоит на месте.

	Сигнал приходит ВСЕМ клиентам, а не только жертве: рэгдолл, включённый
	локально, другим не реплицируется, поэтому каждый клиент собирает позу
	у себя сам. Импульс применяет только владелец персонажа.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local StateChanged = ReplicatedStorage.Remotes.Ragdoll.StateChanged

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local CollisionConfig = require(ReplicatedStorage.Configs.CollisionConfig)
local RagdollCamera = require(script.RagdollCamera)

local LocalPlayer = Players.LocalPlayer

--[[
	Группу и её правила заводит RagdollService на сервере (CollisionConfig.Groups
	и Rules). Ragdoll с самим собой не сталкивается: иначе конечности упираются
	в собственный торс и тело мелко трясёт.
]]
local RagdollCollisionGroup = CollisionConfig.Ragdoll

local RagdollController = {}

--[[========================= механика =========================]]

--[[
	Сустав Root держит HumanoidRootPart на LowerTorso, и в отличие от остальных
	суставов парного BallSocketConstraint у него НЕТ (их 14, а AnimationConstraint 15).
	Если его выключить, рутпарт отрывается от тела: летит он один, а тело
	обмякает и остаётся лежать. Поэтому Root всегда оставляем включённым.
]]
local function isRootConstraint(constraint: Constraint, rootPart: BasePart?): boolean
	if constraint.Name == "Root" then return true end
	if not rootPart then return false end

	local attachment0 = constraint.Attachment0
	local attachment1 = constraint.Attachment1

	if attachment0 and attachment0.Parent == rootPart then return true end
	if attachment1 and attachment1.Parent == rootPart then return true end

	return false
end

--[[
	Риг игрока один — новая конструктивная R15: суставы собраны на
	AnimationConstraint (держит позу) плюс BallSocketConstraint (лимиты рэгдолла).
	Рэгдолл = выключить AnimationConstraint, тогда шарниры отпускают конечности.
	Root — исключение, см. выше.

	Ветка для старых ригов на Motor6D удалена: рэгдолл применяется только
	к игрокам, а у них Motor6D нет вовсе — она не выполнялась ни разу.
]]
--[[
	В R15 тело на ногах держит один HumanoidRootPart, а руки и ноги сквозные.
	В рэгдолле это меняется местами: капсула рутпарта только мешает и трясёт
	тело, а лежать на полу должны сами конечности — иначе они провалятся сквозь него.

	Исходные значения запоминаем и возвращаем при подъёме: чужие настройки
	(аксессуары, чьи-то собственные группы) ломать нельзя.
]]
local function setLimbCollisions(self, character: Model, enabled: boolean)
	if enabled then
		--[[
			Сохраняем ровно один раз. Второе включение поверх первого — а так
			делает любая сцена, зовущая SetRagdoll напрямую, минуя защиту
			Knockdown по иммунитету — записало бы в "исходные" уже рэгдолльные значения,
			и персонаж навсегда остался бы в группе Ragdoll с бесколлизионной капсулой.
		]]
		if self._collisionRestore[character] then return end

		local saved = {}

		for _, part in character:GetChildren() do
			if not part:IsA("BasePart") then continue end

			table.insert(saved, {
				Part = part;
				CanCollide = part.CanCollide;
				CollisionGroup = part.CollisionGroup;
			})

			part.CollisionGroup = RagdollCollisionGroup
			-- рутпарт единственный, кому коллизию снимаем
			part.CanCollide = part.Name ~= "HumanoidRootPart"
		end

		self._collisionRestore[character] = saved

		return
	end

	local saved = self._collisionRestore[character]

	if not saved then return end

	for _, entry in saved do
		if entry.Part.Parent then
			entry.Part.CanCollide = entry.CanCollide
			entry.Part.CollisionGroup = entry.CollisionGroup
		end
	end

	self._collisionRestore[character] = nil
end

function RagdollController:SetRagdoll(character: Model, enabled: boolean)
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then return end

	-- без этого отключённый сустав шеи убивает персонажа
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false

	--[[
		Главная причина дребезга: машина состояний продолжает работать и каждый
		кадр пытается поставить персонажа на ноги, пока физика его роняет.
		Пока лежим — выключаем её целиком, перед подъёмом возвращаем.
	]]
	humanoid.EvaluateStateMachine = not enabled

	--[[
		Вторая причина: в лежачей позе капсула рутпарта упирается в пол и в собственные
		конечности. Перекладываем опору на части тела и разводим их по группе коллизий.
	]]
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	setLimbCollisions(self, character, enabled)

	local animate = character:FindFirstChild("Animate")

	if animate and animate:IsA("BaseScript") then
		animate.Disabled = enabled
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")

	if animator and enabled then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end

	-- главное для современного рига: без этого тело остаётся жёстким
	for _, constraint in character:GetDescendants() do
		if not constraint:IsA("AnimationConstraint") then continue end
		if isRootConstraint(constraint, rootPart :: BasePart?) then continue end

		constraint.Enabled = not enabled
	end

	humanoid.PlatformStand = enabled
	humanoid.AutoRotate = not enabled

	if enabled then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	else
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

--[[
	Суставы R15 — конструкция из констрейнтов, а не сварок: каждая часть тела
	отдельная ассамблея. Толкать один торс бесполезно — остальное тело осадит
	его через шарниры, поэтому скорость выставляем всем частям сразу.

	Ровно один раз: если удерживать её несколько кадров, конечности не успевают
	отстать, тело летит доской и потом резко разваливается — это читается как рывок.
]]
function RagdollController:ApplyImpulse(character: Model, velocity: Vector3)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and not part.Anchored then
			part.AssemblyLinearVelocity = velocity
		end
	end
end

--[[========================= реакция на сигнал =========================]]

--[[
	Для владельца рэгдолл и импульс идут в одном кадре: сначала тело обмякает,
	потом сразу получает скорость. Если сделать наоборот, игрок улетает стоя
	и обмякает уже в полёте — читается как два разных события вместо удара.
]]
local function onOwnStateChanged(self, isRagdolled: boolean)
	self.IsRagdolled = isRagdolled

	if isRagdolled then
		--[[
			Тул только блокируется, а не снимается: он остаётся в руках,
			просто перестаёт реагировать на кнопку. Если у механики есть
			что оборвать (начатое удержание, мини-игра), она подписывается
			на RagdollService.RagdollStarted и рвёт это сама.
		]]
		self._controllers.ToolsController:SetToolsBlocked(true)

		return
	end

	self._camera:Stop()

	self._controllers.ToolsController:SetToolsBlocked(false)
	self._controllers.CharacterMovementController:EnableMovement()
end

--[[
	Единая точка применения состояния: сюда заходит и сигнал сервера, и любая
	своя сцена. Нужна именно общая: поза — далеко не всё, что делает рэгдолл,
	и сцена, повторяющая только SetRagdoll, оставила бы игрока с работающим
	тулом и без камеры.
]]
function RagdollController:ApplyState(target: Player, isRagdolled: boolean, impulse: Vector3?)
	local character = target.Character

	if not character or not character.Parent then return end

	local isOwn = target == LocalPlayer

	if isOwn then
		onOwnStateChanged(self, isRagdolled)
	end

	self:SetRagdoll(character, isRagdolled)

	if not isOwn then return end

	-- импульс имеет смысл только у владельца: чужую скорость физика проигнорирует
	if isRagdolled and typeof(impulse) == "Vector3" then
		self:ApplyImpulse(character, impulse)
	end

	if isRagdolled then
		self._camera:Follow(character)
	end
end

function RagdollController:Initialize(player: Player)
	self._player = player

	StateChanged.OnClientEvent:Connect(function(target: Player, isRagdolled: boolean, impulse: Vector3?)
		if not target then return end

		self:ApplyState(target, isRagdolled == true, impulse)
	end)

	-- респавн всегда возвращает управление: иначе тул останется заблокированным
	player.CharacterAdded:Connect(function()
		if not self.IsRagdolled then return end

		onOwnStateChanged(self, false)
	end)
end

function RagdollController.new()
	local self = setmetatable(RagdollController, {__index = ControllerTemplate})

	--[[ Публичное поле: читается снаружи, поэтому без подчёркивания. ]]
	self.IsRagdolled = false
	self._camera = RagdollCamera.new()
	-- слабые ключи: старые персонажи не должны висеть в памяти после респавна
	self._collisionRestore = setmetatable({}, {__mode = "k"})

	return self
end

return RagdollController
