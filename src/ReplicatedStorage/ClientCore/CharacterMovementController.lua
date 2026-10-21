local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local CharacterMovementController = {}

--[[ Шов под будущие модификаторы скорости (баффы, пассы): всё домножается здесь. ]]
local function getResultSpeed(self) : number
	return self._defaultSpeed
end

--[[
	Гуманоид текущего персонажа или nil.

	Раньше здесь стояло `self._player.Character or self._player.CharacterAdded:Wait()`:
	вызов без персонажа (между смертью и респавном) блокировал вызывающий поток
	до респавна. Ждать нечего — если персонажа нет, применять скорость не к чему.
]]
local function getHumanoid(self) : Humanoid?
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
	self._speed = 0
	self._jumpHeight = 0

	applyMovement(self)
end

function CharacterMovementController:EnableMovement()
	self._speed = getResultSpeed(self)
	self._jumpHeight = self._basicJumpHeight

	applyMovement(self)
end

function CharacterMovementController:Initialize(player: Player)
	self._player = player
	self._defaultSpeed = StarterPlayer.CharacterWalkSpeed
	self._basicJumpHeight = StarterPlayer.CharacterJumpHeight
	self._speed = getResultSpeed(self)
	self._jumpHeight = self._basicJumpHeight

	Player.CharacterAdded:Connect(function(character: Model)
		self._character = character
		self._humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?

		--[[
			Новый персонаж всегда получает движение обратно. Поля _speed и _jumpHeight
			переживают смерть, и раньше обработчик применял к свежему персонажу то,
			что в них лежало: умер с выключенным движением — воскрес с WalkSpeed = 0.
			Мини-игры у нового персонажа быть не может, поэтому сброс безусловный.
		]]
		self:EnableMovement()
	end)
end

function CharacterMovementController.new()
	return setmetatable(CharacterMovementController, {__index = ControllerTemplate})
end

return CharacterMovementController
