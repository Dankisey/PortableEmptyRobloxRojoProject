local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local StateChanged = ReplicatedStorage.Remotes.Ragdoll.StateChanged

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local CollisionConfig = require(ReplicatedStorage.Configs.CollisionConfig)
local RagdollCamera = require(script.RagdollCamera)

local LocalPlayer = Players.LocalPlayer

--[[ the server registers the group; Ragdoll does not collide with itself, or limbs push against the torso and the body jitters ]]
local RagdollCollisionGroup = CollisionConfig.Ragdoll

--[[ the whole mechanic lives here: the client owns its character, a server velocity is reset and SetNetworkOwner(nil) freezes the body ]]
local RagdollController = {}

--[[========================= mechanic =========================]]

--[[ Root has no paired BallSocketConstraint: disabling it detaches the root part, which flies alone while the body stays behind ]]
local function isRootConstraint(constraint: Constraint, rootPart: BasePart?): boolean
	if constraint.Name == "Root" then return true end

	if not rootPart then return false end

	local attachment0 = constraint.Attachment0
	local attachment1 = constraint.Attachment1

	if attachment0 and attachment0.Parent == rootPart then return true end

	if attachment1 and attachment1.Parent == rootPart then return true end

	return false
end

--[[ lying down, the root capsule only shakes the body and the limbs must rest on the floor; original values are restored on stand up ]]
local function setLimbCollisions(self, character: Model, enabled: boolean)
	if enabled then
		--[[ saved once: a second SetRagdoll on top would store ragdoll values as the originals and leave the character in Ragdoll forever ]]
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

	--[[ a disabled neck joint kills the character otherwise ]]
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false

	--[[ the state machine tries to stand the character up every frame while physics drops it: the main jitter source ]]
	humanoid.EvaluateStateMachine = not enabled

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

--[[ every part is its own assembly, so all get the velocity; exactly once, or the body flies like a board and then snaps apart ]]
function RagdollController:ApplyImpulse(character: Model, velocity: Vector3)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and not part.Anchored then
			part.AssemblyLinearVelocity = velocity
		end
	end
end

--[[========================= signal reaction =========================]]

local function onOwnStateChanged(self, isRagdolled: boolean)
	self.IsRagdolled = isRagdolled

	if isRagdolled then
		--[[ the tool is blocked, not unequipped; a mechanic with something to abort subscribes to RagdollService.RagdollStarted itself ]]
		self._controllers.ToolsController:SetToolsBlocked(true)

		return
	end

	self._camera:Stop()

	self._controllers.ToolsController:SetToolsBlocked(false)
	self._controllers.CharacterMovementController:EnableMovement()
end

--[[ the single entry point for the server signal and any scene: the pose alone would leave a working tool and no camera ]]
function RagdollController:ApplyState(target: Player, isRagdolled: boolean, impulse: Vector3?)
	local character = target.Character

	if not character or not character.Parent then return end

	local isOwn = target == LocalPlayer

	if isOwn then
		onOwnStateChanged(self, isRagdolled)
	end

	--[[ ragdoll first, impulse in the same frame: the other way round the player flies standing and goes limp mid-air ]]
	self:SetRagdoll(character, isRagdolled)

	if not isOwn then return end

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

	--[[ a respawn always returns control, or the tool stays blocked ]]
	player.CharacterAdded:Connect(function()
		if not self.IsRagdolled then return end

		onOwnStateChanged(self, false)
	end)
end

function RagdollController.new()
	local self = setmetatable(RagdollController, {__index = ControllerTemplate})

	self.IsRagdolled = false
	self._camera = RagdollCamera.new()
	self._collisionRestore = setmetatable({}, {__mode = "k"}) -- weak keys: old characters must not stay in memory after respawn

	return self
end

return RagdollController
