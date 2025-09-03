local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local InputController = {}

function InputController:GetClickScreenRay() : Ray
    local cursorPosition = self:GetCursorPosition() :: Vector2
    cursorPosition -= GuiService:GetGuiInset()
    local screenRay = self._camera:ScreenPointToRay(cursorPosition.X, cursorPosition.Y) :: Ray

    if self._configs.TestingConfig.IsTesting then
        self._utils.Gizmos:DrawRay(screenRay.Origin, screenRay.Direction * self._configs.InputConfig.RayLength)
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

    if self._configs.TestingConfig.IsTesting then
        self._utils.Gizmos:DrawRay(rayOrigin, rayDirection * self._configs.InputConfig.RayLength)
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

function InputController:AfterPlayerLoaded(player)
    self._player = player

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local tool = self._player.Character:FindFirstChildOfClass("Tool")

            if tool then
                self._controllers.ToolsController:ActivateTool(tool)
            end
		end
	end)
end

function InputController:Initialize()
    self._utils.Gizmos:SetColor(self._configs.TestingConfig.GizmosColor)
end

function InputController:InjectUtils(utils)
    self._utils = utils
    self.ObjectClicked = utils.Event.new()
end

function InputController.new()
    local self = setmetatable(InputController, {__index = ControllerTemplate})
    self._camera = workspace.CurrentCamera :: Camera
    self._controllType = self:GetControllType()

    return self
end

return InputController