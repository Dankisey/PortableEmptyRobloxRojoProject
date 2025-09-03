local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local ZonesFolder = workspace.PlayersZones

local ZoneController = {}

local function updateGuiVisibility(self)
    if not self._player.Character then return end

    local playerPosition = self._player.Character:GetPivot().Position :: Vector3
    playerPosition = Vector2.new(playerPosition.X, playerPosition.Z) :: Vector2
    local zonePosition = self._zonePivot.Position :: Vector3
    zonePosition = Vector2.new(zonePosition.X, zonePosition.Z) :: Vector2
    local distanceToZone = (playerPosition - zonePosition).Magnitude :: number

    self._gui.Enabled = distanceToZone >= self._configs.ZonesConfig.GuiAppearingDistance
end

local function waitForInitializingEnd(self)
    while not self.IsInitialized do
        task.wait()
    end
end

function ZoneController:GetTeleportPart() : Part
    waitForInitializingEnd(self)

    if not self._teleportPart then
        self._teleportPart = self._zone:WaitForChild("TeleportPart") :: Part
    end

    return self._teleportPart
end

function ZoneController:GetPlayersZone(player: Player) : Model
    if not player:GetAttribute("ZoneId") then
        player:GetAttributeChangedSignal("ZoneId"):Wait()
    end

    local zoneId = player:GetAttribute("ZoneId")

    return ZonesFolder:WaitForChild(zoneId)
end

function ZoneController:GetZone()
    waitForInitializingEnd(self)

    return self._zone
end

function ZoneController:AfterPlayerLoaded(player: Player)
    local zoneId = player:GetAttribute("ZoneId")
    self._player = player

    if not zoneId then
        player:GetAttributeChangedSignal("ZoneId"):Wait()
        zoneId = player:GetAttribute("ZoneId")
    end

    self._signPromptsConnections = {}
    self._zoneId = zoneId :: number
    self._zone = workspace:WaitForChild("PlayersZones"):WaitForChild(tostring(zoneId)) :: Model
    self._zonePivot = self._zone:GetPivot() :: CFrame
    self._gui = self._zone:WaitForChild("GuiHolder"):WaitForChild("Gui") :: BillboardGui
    self._gui.ProfileIcon.Image = self._utils.GetPlayerProfileIcon(player.UserId)

    RunService.Heartbeat:Connect(function(deltaTime)
        updateGuiVisibility(self)
    end)

    self.IsInitialized = true
end

function ZoneController.new()
    return setmetatable(ZoneController, {__index = ControllerTemplate})
end

return ZoneController