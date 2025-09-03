local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local CharacterMovementController = {}

local function getResultSpeed(self) : number
	return self._defaultSpeed
end

local function updateCharacterSpeed(self)
    local character = self._player.Character or self._player.CharacterAdded:Wait()
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = self._speed
end

local function updateJumpPower(self)
    local character = self._player.Character or self._player.CharacterAdded:Wait()
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
    humanoid.JumpHeight = self._jumpHeight
end

function CharacterMovementController:DisableMovement()
    self._speed = 0
    self._jumpHeight = 0
    updateCharacterSpeed(self)
    updateJumpPower(self)
end

function CharacterMovementController:EnableMovement()
    self._speed = getResultSpeed(self)
    self._jumpHeight = self._basicJumpHeight
    updateCharacterSpeed(self)
    updateJumpPower(self)
end

function CharacterMovementController:Initialize(player: Player)
    self._player = player
    self._defaultSpeed = StarterPlayer.CharacterWalkSpeed
    self._speed = self._defaultSpeed
    self._basicJumpHeight = StarterPlayer.CharacterJumpHeight
    self._jumpHeight = self._basicJumpHeight

    Player.CharacterAdded:Connect(function(character: Model)
		self._character = character
		updateCharacterSpeed(self)
		self._humanoid = self._character:WaitForChild("Humanoid") :: Humanoid
	end)
end

function CharacterMovementController.new()
    return setmetatable(CharacterMovementController, {__index = ControllerTemplate})
end

return CharacterMovementController