local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local ClientTypes = require(ReplicatedStorage.Modules.ClientTypes)

local ToolsController = {} :: ClientTypes.ToolsController

local ToolsActions = {

}

local function updateCharacterConnection(self: ClientTypes.ToolsController)
    local character = self._player.Character or self._player.CharacterAdded:Wait() :: Model

    if self._toolEquippedConnection then
        self._toolEquippedConnection:Disconnect()
        self._toolEquippedConnection = nil
    end

    if self._toolUnequippedConnection then
        self._toolUnequippedConnection:Disconnect()
        self._toolUnequippedConnection = nil
    end

    self._toolEquippedConnection = character.ChildAdded:Connect(function(child: Instance)
        if child:IsA("Tool") == false then return end

        self.ToolEquipped:Invoke(child)
    end)

    self._toolUnequippedConnection = character.ChildRemoved:Connect(function(child: Instance)
        if child:IsA("Tool") == false then return end

        self.ToolUnequipped:Invoke(child)
    end)
end

function ToolsController:ActivateTool(tool: Tool)
    local toolType = tool:GetAttribute("ToolType")

    if ToolsActions[toolType] then
        ToolsActions[toolType](self, tool)
    else
        warn('Action for tool with type "' .. tostring(toolType) .. '" is not implemented')
    end
end

function ToolsController:AfterPlayerLoaded(player: Player)
    self._player = player

    updateCharacterConnection(self)

    self._player.CharacterAdded:Connect(function(_: Model)
        updateCharacterConnection(self)
    end)
end

function ToolsController:InjectUtils(utils)
    self.ToolUnequipped = utils.Event.new()
    self.ToolEquipped = utils.Event.new()
    self._utils = utils
end

function ToolsController.new() : ClientTypes.ToolsController
    local self = setmetatable(ToolsController, {__index = ControllerTemplate})

    return self
end

return ToolsController