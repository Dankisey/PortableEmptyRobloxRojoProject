local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local Player = Players.LocalPlayer

local CharacterMovementController = {}

--[[ the seam for future speed modifiers: everything multiplies here, and a recalculation calls RefreshSpeed ]]
local function getResultSpeed(self): number
	return self._defaultSpeed
end

--[[ never waits for CharacterAdded: without a character there is nothing to apply ]]
local function getHumanoid(self): Humanoid?
	local character = self._player.Character

	if not character then return nil end

	return character:FindFirstChildOfClass("Humanoid")
end

local function applyMovement(self)
	local humanoid = getHumanoid(self)

	if not humanoid then return end

	humanoid.WalkSpeed = self._speed
	humanoid.JumpHeight = self._jumpHeight
end

function CharacterMovementController:DisableMovement()
	self._isEnabled = false
	self._speed = 0
	self._jumpHeight = 0

	applyMovement(self)
end

function CharacterMovementController:EnableMovement()
	self._isEnabled = true
	self._speed = getResultSpeed(self)
	self._jumpHeight = self._basicJumpHeight

	applyMovement(self)
end

--[[ a modifier change must not turn on movement that a ragdoll or a scene turned off ]]
function CharacterMovementController:RefreshSpeed()
	if not self._isEnabled then return end

	self._speed = getResultSpeed(self)

	applyMovement(self)
end

function CharacterMovementController:Initialize(player: Player)
	self._player = player
	self._defaultSpeed = StarterPlayer.CharacterWalkSpeed
	self._basicJumpHeight = StarterPlayer.CharacterJumpHeight
	self._isEnabled = true
	self._speed = getResultSpeed(self)
	self._jumpHeight = self._basicJumpHeight

	Player.CharacterAdded:Connect(function(character: Model)
		self._character = character
		self._humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?

		--[[ a new character always gets movement back: the fields survive death, and dying with movement off meant spawning with zero speed ]]
		self:EnableMovement()
	end)
end

function CharacterMovementController.new()
	return setmetatable(CharacterMovementController, {__index = ControllerTemplate})
end

return CharacterMovementController
