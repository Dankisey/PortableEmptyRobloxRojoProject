--[[
	CameraController — камера и видимость персонажа.

	Режим камеры задаётся СВОЙСТВОМ StarterPlayer.CameraMode, а не кодом:
	переключать его на ходу незачем, а плейсы с разным режимом — это разные
	плейсы со своим StarterPlayer.

	Включил LockFirstPerson — включи и CameraConfig.FirstPersonVisibility,
	иначе штатный контроллер прозрачности погасит вместе с персонажем и тул
	в его руках (см. секцию "видимость в первом лице"). В третьем лице флаг
	обязан оставаться выключенным.

	Твины, фиксации и тряска не зовёт никто — они лежат готовым инструментом
	под катсцены.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local CameraConfig = require(ReplicatedStorage.Configs.CameraConfig)

local CameraController = {}

--[[ Отдельное имя бинда: PivotCamera ставит свой на тот же приоритет. ]]
local FirstPersonBind = "FirstPersonVisibility"

local function createAttachment(root: Part, offset: CFrame) : Attachment
	local attachment = Instance.new("Attachment") :: Attachment
	attachment.Name = "CameraAttachment"
	attachment.Parent = root
	attachment.CFrame = offset

	return attachment
end

function CameraController:TweenTo(target: CFrame, time: number, start: CFrame?) : RBXScriptSignal
	start = start or self._camera:GetPivot()
	self._camera.CameraType = Enum.CameraType.Scriptable
	self._camera:PivotTo(start)

	local tween = TweenService:Create(self._camera, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = target})
	tween:Play()

	return tween.Completed
end

function CameraController:ShakeWithoutPivoting(humanoid: Humanoid, shakeIntencity: number, duration: number, frequency: number)
	if self._isShaking then return end

	local originalOffset = humanoid.CameraOffset
	local leftTime = duration
	self._isShaking = true

	task.spawn(function()
		while true do
			local progress = (duration - leftTime) / duration
			local fadeIntensity = shakeIntencity * (1 - progress)

			if progress >= 1 then
				self._isShaking = false

				break
			end

			local offset = Vector3.new(
				self._random:NextNumber(-shakeIntencity, shakeIntencity) * fadeIntensity,
				self._random:NextNumber(-shakeIntencity, shakeIntencity) * fadeIntensity,
				self._random:NextNumber(-shakeIntencity, shakeIntencity) * fadeIntensity
			)

			local tween = TweenService:Create(humanoid, TweenInfo.new(frequency), {CameraOffset = originalOffset + offset})
			leftTime -= frequency
			tween:Play()
			tween.Completed:Wait()
		end

		humanoid.CameraOffset = originalOffset
	end)
end

function CameraController:PivotCamera(character: Model, offsetCframe: CFrame)
	self._currentAttachment = createAttachment(character.HumanoidRootPart, offsetCframe)
	self._camera.CameraType = Enum.CameraType.Scriptable

	if self._renderBind then
		RunService:UnbindFromRenderStep(self._renderBind)
		self._renderBind = nil
	end

	self._renderBind = "CameraUpdate"
	self._camera:PivotTo(self._currentAttachment.WorldCFrame * self._shakingOffset)

	RunService:BindToRenderStep(self._renderBind, Enum.RenderPriority.Camera.Value + 1, function()
		self._camera:PivotTo(self._currentAttachment.WorldCFrame * self._shakingOffset)
	end)
end

function CameraController:FreezeCamera(character: Model)
	local cameraFrame = self._camera:GetPivot()
	local offset = character:GetPivot():ToObjectSpace(cameraFrame)
	self:PivotCamera(character, offset)
end

function CameraController:FixThirdPerson(character: Model)
	self:PivotCamera(character, CameraConfig.ThirdPersonOffset)
end

function CameraController:ResetCamera()
	if self._currentAttachment then
		self._currentAttachment:Destroy()
	end

	if self._renderBind then
		RunService:UnbindFromRenderStep(self._renderBind)
		self._renderBind = nil
	end

	self._camera.CameraType = Enum.CameraType.Custom
end

--[[========================= видимость в первом лице =========================]]

--[[
	Части персонажа, которые видно от первого лица (CameraConfig).
	Руки показаны намеренно: без них предмет в руках висит в воздухе сам
	по себе, и непонятно, чем игрок его держит.

	ПЛЕЧИ (UpperArm) в список не входят: они крепятся к торсу вплотную
	к камере и в первом лице лезут прямо в кадр.
]]
local VisibleCharacterParts = CameraConfig.VisibleCharacterParts

--[[
	Видным остаётся любой Tool в руках плюс сами руки. Всё остальное
	в персонаже — торс, голова, ноги, аксессуары — прячется: в первом лице
	оно стоит ровно перед камерой.
]]
local function isVisibleRoot(instance: Instance): boolean
	return instance:IsA("Tool") or VisibleCharacterParts[instance.Name] == true
end

--[[ LocalTransparencyModifier есть и у Decal — глаза рыбы, лицо, наклейки на удочке. ]]
local function isRenderable(instance: Instance): boolean
	return instance:IsA("BasePart") or instance:IsA("Decal")
end

local function collectParts(self)
	table.clear(self._visibleParts)
	table.clear(self._hiddenParts)

	local character = self._player and self._player.Character

	if not character then return end

	for _, child in character:GetChildren() do
		local target = if isVisibleRoot(child) then self._visibleParts else self._hiddenParts

		if isRenderable(child) then
			table.insert(target, child)
		end

		for _, descendant in child:GetDescendants() do
			if isRenderable(descendant) then
				table.insert(target, descendant)
			end
		end
	end
end

local function watchCharacter(self, character: Model)
	for _, connection in self._characterConnections do
		connection:Disconnect()
	end

	table.clear(self._characterConnections)

	--[[
		Пересборка по флагу, а не прямо в обработчике: и удочка, и модель
		рыбы приезжают целым деревом, то есть десятком событий подряд.
	]]
	local function markDirty()
		self._visiblePartsDirty = true
	end

	table.insert(self._characterConnections, character.DescendantAdded:Connect(markDirty))
	table.insert(self._characterConnections, character.DescendantRemoving:Connect(markDirty))

	markDirty()
end

--[[
	Прозрачность персонажа считаем САМИ, а не правим штатную. Причины две,
	и вторая важнее первой.

	1. Штатный TransparencyController в первом лице гасит ВЕСЬ персонаж целиком,
	включая тул в руках: Tool живёт внутри персонажа, то есть предмет игры
	пропадает вместе с ним.

	2. Он вообще выключается, как только CameraSubject перестаёт быть Humanoid:
	TransparencyController:SetSubject на любом другом субъекте делает TearDown
	и возвращает всем частям ноль. А именно это делает RagdollCamera — она подсовывает
	заанкеренный якорь-парт. Без собственного счёта игрок каждый рэгдолл
	смотрел бы в изнанку собственного торса.

	Приоритет обязательно ПОЗЖЕ камеры: штатный контроллер работает внутри бинда
	Enum.RenderPriority.Camera, и на равном приоритете он перетрёт нас в том же кадре.

	Цена решения: персонаж скрыт БЕЗУСЛОВНО, пока бинд стоит. Появится сцена
	от третьего лица — бинд надо гасить на её время.
]]
local function startVisibilityKeeper(self)
	RunService:BindToRenderStep(FirstPersonBind, Enum.RenderPriority.Camera.Value + 1, function()
		if self._visiblePartsDirty then
			collectParts(self)
			self._visiblePartsDirty = false
		end

		for _, part in self._hiddenParts do
			part.LocalTransparencyModifier = 1
		end

		for _, part in self._visibleParts do
			part.LocalTransparencyModifier = 0
		end
	end)
end

function CameraController:Initialize(player: Player)
	self._player = player
	self._random = Random.new(os.time())
	self._camera = workspace.CurrentCamera
	self._shakingOffset = CFrame.fromOrientation(0, 0, 0)

	if player.Character then
		watchCharacter(self, player.Character)
	end

	player.CharacterAdded:Connect(function(character: Model)
		watchCharacter(self, character)
	end)

	--[[
		В третьем лице считать прозрачность не надо вовсе: там штатный
		контроллер ничего не гасит, а наш бинд спрятал бы персонаж целиком.
	]]
	if CameraConfig.FirstPersonVisibility then
		startVisibilityKeeper(self)
	end
end

function CameraController.new()
	local self = setmetatable(CameraController, {__index = ControllerTemplate})

	self._visibleParts = {}
	self._hiddenParts = {}
	self._visiblePartsDirty = true
	self._characterConnections = {}

	return self
end

return CameraController