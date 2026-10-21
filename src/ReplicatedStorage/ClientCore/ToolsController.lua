--[[
	ToolsController — что у игрока в руках и что происходит по кнопке использования.

	Правило одно: в руках всегда самый приоритетный тул из рук и рюкзака.
	КАКИЕ тулы у игрока есть, решает сервер; этот контроллер только приводит
	руки в соответствие.

	Штатной активации нет вовсе: у тулов ставится ManualActivationOnly = true,
	Tool.Activated не слушает никто. Использование идёт только через
	UseEquippedTool — его зовут клавиши из ControlsConfig.Use, тап в любую точку
	экрана (ControlsConfig.Use.TapAnywhere) и экранная кнопка, если игра её заведёт.

	Своей кнопки в каркасе нет намеренно: её вид и место зависят от игры.
	Что она должна показывать для каждого типа тула, описано в ToolsConfig.Actions,
	а подпись клавиши на ней ставит Modules.UI.KeyBadge.

	Что делает конкретный тип тула, каркас не знает: игра регистрирует
	действие сама через RegisterAction в своём Initialize.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local ClientTypes = require(ReplicatedStorage.Modules.ClientTypes)
local ControlsConfig = require(ReplicatedStorage.Configs.ControlsConfig)
local ToolsConfig = require(ReplicatedStorage.Configs.ToolsConfig)

local ToolsController = {} :: ClientTypes.ToolsController

--[[
	Стандартный инвентарь Роблокса выключен: тул всегда в руках, и выбирает
	его игра, а не игрок цифрами. Выключение Backpack заодно освобождает
	цифровые клавиши и не даёт снять тул кликом по слоту.
]]
local function hideBackpackGui()
	local success, err = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)

	if not success then
		warn("Failed to disable Backpack CoreGui: " .. tostring(err))
	end
end

local function getToolType(instance: Instance): string?
	if not instance:IsA("Tool") then return nil end

	local toolType = instance:GetAttribute(ToolsConfig.ToolTypeAttribute)

	return if type(toolType) == "string" then toolType else nil
end

--[[ свайп камеры тоже начинается касанием: тап отличается от него только после отпускания ]]
local function isTap(start: {Position: Vector3, Time: number}, input: InputObject): boolean
	local moved = Vector2.new(input.Position.X - start.Position.X, input.Position.Y - start.Position.Y).Magnitude

	return moved <= ControlsConfig.Use.TapMaxMove and os.clock() - start.Time <= ControlsConfig.Use.TapMaxDuration
end

local function getPriority(instance: Instance): number
	local toolType = getToolType(instance)

	return toolType and ToolsConfig.Priority[toolType] or 0
end

--[[ Самый приоритетный тул из рук и рюкзака сразу. ]]
local function getPreferredTool(self: ClientTypes.ToolsController): Tool?
	local best, bestPriority = nil, 0

	for _, container in {self._player.Character, self._player:FindFirstChild("Backpack")} do
		if not container then continue end

		for _, child in container:GetChildren() do
			local priority = getPriority(child)

			if priority > bestPriority then
				best, bestPriority = child, priority
			end
		end
	end

	return best
end

--[[
	Взять в руки то, что должно быть в руках.

	НАМЕРЕННО НЕ CharacterUtils.GetAlive: тот требует HumanoidRootPart, а на
	респавне его ещё нет в том кадре, куда task.defer приводит экипировку —
	замерено на живом персонаже (humanoid = есть, root = нет). Гвард проваливался
	молча, и повторить было некому: на респавне Roblox сносит старый Backpack
	и создаёт новый УЖЕ С СОДЕРЖИМЫМ, за миллисекунду до CharacterAdded, поэтому
	backpack.ChildAdded по нему не срабатывает вовсе. Итог: после смерти игрок
	оставался без тула до конца сессии.

	Для EquipTool рутпарт не нужен, нужен живой Humanoid — его и ждём.
]]
local function syncEquippedTool(self: ClientTypes.ToolsController)
	local character = self._player and self._player.Character

	if not character then return end

	local preferred = getPreferredTool(self)

	if not preferred then return end
	if preferred.Parent == character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
		or character:WaitForChild("Humanoid", 5)

	-- пока ждали Humanoid, персонаж мог смениться ещё раз
	if self._player.Character ~= character then return end

	if not humanoid or humanoid.Health <= 0 then return end
	if not preferred.Parent or preferred.Parent == character then return end

	humanoid:EquipTool(preferred)
end

--[[
	Подписки на оба контейнера сразу: тул приезжает то в рюкзак (сервер выдал),
	то в персонажа (Roblox надел). Обе стороны ведут к одной проверке.

	Перебор уже существующих детей обязателен: на респавне Backpack приезжает
	готовым, и ChildAdded по его содержимому не сработает ни разу.
]]
local function watchContainers(self: ClientTypes.ToolsController)
	for _, connection in self._containerConnections do
		connection:Disconnect()
	end

	table.clear(self._containerConnections)

	--[[
		Сброс блокировки обязан быть снаружи гварда: при первом спавне
		соединений ещё нет, и тул оставался бы заблокированным после
		респавна в рэгдолле.
	]]
	self._toolsBlocked = false

	local character = self._player.Character

	if character then
		table.insert(self._containerConnections, character.ChildAdded:Connect(function(child: Instance)
			if not child:IsA("Tool") then return end

			self.ToolEquipped:Invoke(child)
		end))

		table.insert(self._containerConnections, character.ChildRemoved:Connect(function(child: Instance)
			if not child:IsA("Tool") then return end

			self.ToolUnequipped:Invoke(child)
			task.defer(syncEquippedTool, self)
		end))
	end

	-- при респавне Backpack пересоздаётся, поэтому ищем его заново каждый раз
	local backpack = self._player:FindFirstChild("Backpack") or self._player:WaitForChild("Backpack", 10)

	if backpack then
		table.insert(self._containerConnections, backpack.ChildAdded:Connect(function(child: Instance)
			if not child:IsA("Tool") then return end

			task.defer(syncEquippedTool, self)
		end))
	end

	task.defer(syncEquippedTool, self)
end

--[[
	Привязать поведение к типу тула. Зовётся из Initialize того контроллера,
	которому этот тул принадлежит.

	onUse     — нажатие кнопки использования
	onRelease — её отпускание; нужен только тулам, которые УДЕРЖИВАЮТ
	            (замах, зарядка). Без него отпускание просто не делает ничего.
]]
function ToolsController:RegisterAction(toolType: string, onUse: (Tool) -> (), onRelease: ((Tool) -> ())?)
	self._useActions[toolType] = onUse
	self._releaseActions[toolType] = onRelease
end

--[[
	Блокировка использования. Тул остаётся в руках — просто перестаёт
	реагировать на кнопку (рэгдолл и прочие состояния).
]]
function ToolsController:SetToolsBlocked(isBlocked: boolean)
	self._toolsBlocked = isBlocked == true
end

function ToolsController:AreToolsBlocked(): boolean
	return self._toolsBlocked == true
end

--[[ Тул в руках. Их всегда не больше одного: Roblox держит в персонаже ровно один. ]]
function ToolsController:GetEquippedTool(): Tool?
	local character = self._player and self._player.Character

	if not character then return nil end

	return character:FindFirstChildOfClass("Tool")
end

function ToolsController:GetEquippedToolType(): string?
	local tool = self:GetEquippedTool()

	return tool and getToolType(tool) or nil
end

function ToolsController:ActivateTool(tool: Tool)
	if self._toolsBlocked then return end

	local toolType = getToolType(tool)
	local action = toolType and self._useActions[toolType]

	if not action then
		warn('Action for tool with type "' .. tostring(toolType) .. '" is not registered')

		return
	end

	action(tool)
end

--[[ Единственная точка входа кнопки и её клавиш-двойников. ]]
function ToolsController:UseEquippedTool()
	local tool = self:GetEquippedTool()

	if not tool then return end

	self:ActivateTool(tool)
end

--[[
	Отпускание той же кнопки.

	Гварда по _toolsBlocked здесь НЕТ нарочно. Блокировка могла включиться
	между нажатием и отпусканием (рэгдолл посреди замаха), и съеденное
	отпускание оставило бы игрока в замахе навсегда. Отпускание без начатого
	удержания и так не делает ничего — это решает сам владелец действия.
]]
function ToolsController:ReleaseEquippedTool()
	local tool = self:GetEquippedTool()

	if not tool then return end

	local toolType = getToolType(tool)
	local action = toolType and self._releaseActions[toolType]

	if not action then return end

	action(tool)
end

function ToolsController:AfterPlayerLoaded(player: Player)
	self._player = player

	hideBackpackGui()
	watchContainers(self)

	self._player.CharacterAdded:Connect(function(_: Model)
		watchContainers(self)
	end)

	--[[
		Клавиши-двойники кнопки. Гвард по gameProcessed здесь уместен: своей
		engine-овой механики за ЛКМ и правым курком нет, а вот клик по интерфейсу
		использованием тула быть не должен.
	]]
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.Touch then
			if ControlsConfig.Use.TapAnywhere then
				self._touchStarts[input] = {Position = input.Position; Time = os.clock()}
			end

			return
		end

		local isUse = input.UserInputType == ControlsConfig.Use.MouseButton
			or input.KeyCode == ControlsConfig.Use.GamepadKeyCode

		if not isUse then return end

		self:UseEquippedTool()
	end)

	--[[
		Отпускание. Гварда по gameProcessed здесь нет: начатое удержание обязано
		закончиться, где бы курсор ни оказался к этому моменту.

		Касание здесь не отпускает: палец, ушедший со стика, тоже касание и оборвал
		бы удержание экранной кнопки. Кнопка сама ловит конец своего касания
		(ButtonsInteractionsConnector:ConnectHoldButton).
	]]
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			local start = self._touchStarts[input]
			self._touchStarts[input] = nil

			if start and isTap(start, input) then
				self:UseEquippedTool()
			end
		end

		local isUse = input.UserInputType == ControlsConfig.Use.MouseButton
			or input.KeyCode == ControlsConfig.Use.GamepadKeyCode

		if not isUse then return end

		self:ReleaseEquippedTool()
	end)

	--[[
		Ушёл фокус окна — отпускания мы уже не увидим вовсе, а начатое удержание
		блокирует следующее нажатие.
	]]
	UserInputService.WindowFocusReleased:Connect(function()
		self:ReleaseEquippedTool()
	end)
end

function ToolsController:InjectUtils(utils)
	self.ToolUnequipped = utils.Event.new()
	self.ToolEquipped = utils.Event.new()
	self._utils = utils
end

function ToolsController.new() : ClientTypes.ToolsController
	local self = setmetatable(ToolsController, {__index = ControllerTemplate})

	self._containerConnections = {}
	self._useActions = {}
	self._releaseActions = {}
	self._touchStarts = {}  -- [InputObject] = {Position, Time} касания вне интерфейса
	self._toolsBlocked = false

	return self
end

return ToolsController
