local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local TestingConfig = require(ReplicatedStorage.Configs.TestingConfig)

--[[
	Gizmos — отладочная рисовалка на 478 строк, нужная только при IsTesting.
	Лежит вне Modules.Utils, иначе фреймворк реквайрит её на каждом старте —
	а на сервере она падает на клиентском BindToRenderStep и даёт ложный
	"Module Gizmos was not loaded", который маскирует настоящие поломки.
]]
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

	if self._controllType == "Mobile" then
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
	if self._controllType == "Mobile" then
		return UserInputService:GetMouseLocation()
	elseif self._controllType == "Desktop" then
		return UserInputService:GetMouseLocation()
	else
		return self._camera.ViewportSize / 2
	end
end

function InputController:GetControllType()
	if GuiService:IsTenFootInterface() then
		return "Console"
	elseif UserInputService.TouchEnabled and (not UserInputService.MouseEnabled) then
		return "Mobile"
	else
		return "Desktop"
	end
end

--[[ в первом лице мышь залочена по центру и кликать ей не по чему; в третьем курсор нужен для интерфейса ]]
local function updateMouseIcon(player: Player)
	UserInputService.MouseIconEnabled = player.CameraMode ~= Enum.CameraMode.LockFirstPerson
end

--[[
	Активации тула по клику здесь больше нет. За использование отвечает
	ToolsController: там же живут клавиши использования тула.
	Тап в любую точку экрана — тоже там, под флагом ControlsConfig.Use.TapAnywhere.
]]
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
	self._controllType = self:GetControllType()

	return self
end

return InputController