local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local CameraConfig = require(ReplicatedStorage.Configs.CameraConfig)

--[[ the camera mode is the StarterPlayer.CameraMode property; LockFirstPerson also needs CameraConfig.FirstPersonVisibility ]]
local CameraController = {}

--[[ a separate bind name: PivotCamera binds its own at the same priority ]]
local FirstPersonBind = "FirstPersonVisibility"

local function createAttachment(root: Part, offset: CFrame): Attachment
	local attachment = Instance.new("Attachment") :: Attachment
	attachment.Name = "CameraAttachment"
	attachment.Parent = root
	attachment.CFrame = offset

	return attachment
end

function CameraController:TweenTo(target: CFrame, time: number, start: CFrame?): RBXScriptSignal
	start = start or self._camera:GetPivot()
	self._camera.CameraType = Enum.CameraType.Scriptable
	self._camera:PivotTo(start)

	local tween = TweenService:Create(self._camera, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = target})
	tween:Play()

	return tween.Completed
end

function CameraController:ShakeWithoutPivoting(humanoid: Humanoid, shakeIntensity: number, duration: number, frequency: number)
	if self._isShaking then return end

	local originalOffset = humanoid.CameraOffset
	local leftTime = duration
	self._isShaking = true

	task.spawn(function()
		while true do
			local progress = (duration - leftTime) / duration
			local fadeIntensity = shakeIntensity * (1 - progress)

			if progress >= 1 then
				self._isShaking = false

				break
			end

			local offset = Vector3.new(
				self._random:NextNumber(-shakeIntensity, shakeIntensity) * fadeIntensity,
				self._random:NextNumber(-shakeIntensity, shakeIntensity) * fadeIntensity,
				self._random:NextNumber(-shakeIntensity, shakeIntensity) * fadeIntensity
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

--[[========================= first person visibility =========================]]

local VisibleCharacterParts = CameraConfig.VisibleCharacterParts

--[[ the held tool and the arms stay visible: without arms the item floats in the air ]]
local function isVisibleRoot(instance: Instance): boolean
	return instance:IsA("Tool") or VisibleCharacterParts[instance.Name] == true
end

--[[ Decal has LocalTransparencyModifier too: faces and stickers ]]
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

	--[[ rebuilt by flag, not in the handler: a tool or model arrives as a whole tree, a dozen events in a row ]]
	local function markDirty()
		self._visiblePartsDirty = true
	end

	table.insert(self._characterConnections, character.DescendantAdded:Connect(markDirty))
	table.insert(self._characterConnections, character.DescendantRemoving:Connect(markDirty))

	markDirty()
end

--[[
	own transparency instead of the default TransparencyController: it hides the held tool with the character,
	and it turns off when CameraSubject is not a Humanoid (RagdollCamera). Priority after Camera, or it overwrites us
	in the same frame. The character stays hidden while the bind exists: a third person scene must unbind it
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

	--[[ never in third person: the bind would hide the whole character ]]
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
