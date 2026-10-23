local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local TestingConfig = require(ReplicatedStorage.Configs.TestingConfig)

--[[ outside Modules.Utils: the framework would require it on every start, and on the server it fails with a false "Module Gizmos was not loaded" ]]
local Gizmos = TestingConfig.IsTesting and require(ReplicatedStorage.Modules.Gizmos) or nil

local InputController = {}

function InputController:GetClickScreenRay() : Ray
	local cursorPosition = self:GetCursorPosition() :: Vector2
	cursorPosition -= GuiService:GetGuiInset()
	local screenRay = self._camera:ScreenPointToRay(cursorPosition.X, cursorPosition.Y) :: Ray

	if Gizmos then
		Gizmos:DrawRay(screenRay.Origin, screenRay.Direction * self._configs.InputConfig.RayLength)
	end

	return Ray.new(screenRay.Origin, screenRay.Direction * self._configs.InputConfig.RayLength)
end

function InputController:GetScreenRay() : Ray
	local rayOrigin, rayDirection

	if self._controlType == "Mobile" then
		local camera = workspace.CurrentCamera
		local viewportSize = camera.ViewportSize
		local centerX = viewportSize.X / 2
		local centerY = (viewportSize.Y / 2) * 0.9

		local screenRay = camera:ViewportPointToRay(centerX, centerY)
		rayOrigin = screenRay.Origin
		rayDirection = screenRay.Direction
	else
		local cursorPosition = self:GetCursorPosition() :: Vector2
		cursorPosition -= GuiService:GetGuiInset()
		local screenRay = self._camera:ScreenPointToRay(cursorPosition.X, cursorPosition.Y) :: Ray
		rayOrigin = screenRay.Origin
		rayDirection = screenRay.Direction
	end

	if Gizmos then
		Gizmos:DrawRay(rayOrigin, rayDirection * self._configs.InputConfig.RayLength)
	end

	return Ray.new(rayOrigin, rayDirection * self._configs.InputConfig.RayLength)
end

function InputController:GetCursorPosition() : Vector2
	if self._controlType == "Mobile" then
		return UserInputService:GetMouseLocation()
	elseif self._controlType == "Desktop" then
		return UserInputService:GetMouseLocation()
	else
		return self._camera.ViewportSize / 2
	end
end

function InputController:GetControlType()
	if GuiService:IsTenFootInterface() then
		return "Console"
	elseif UserInputService.TouchEnabled and (not UserInputService.MouseEnabled) then
		return "Mobile"
	else
		return "Desktop"
	end
end

--[[ in first person the mouse is locked to the center; in third person the cursor is needed for the interface ]]
local function updateMouseIcon(player: Player)
	UserInputService.MouseIconEnabled = player.CameraMode ~= Enum.CameraMode.LockFirstPerson
end

function InputController:AfterPlayerLoaded(player)
	self._player = player

	updateMouseIcon(player)
	player:GetPropertyChangedSignal("CameraMode"):Connect(function()
		updateMouseIcon(player)
	end)
end

function InputController:Initialize()
	if not Gizmos then return end

	Gizmos:SetColor(TestingConfig.GizmosColor)
end

function InputController:InjectUtils(utils)
	self._utils = utils
end

function InputController.new()
	local self = setmetatable(InputController, {__index = ControllerTemplate})
	self._camera = workspace.CurrentCamera :: Camera
	self._controlType = self:GetControlType()

	return self
end

return InputController