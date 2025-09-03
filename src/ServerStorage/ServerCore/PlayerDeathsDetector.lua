local Players = game:GetService("Players")

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
local PlayerDeathsDetector = {} :: ServiceTemplate.Type

local function onPlayerDeath(self: ServiceTemplate.Type, player: Player)

end

local function onPlayerAdded(self: ServiceTemplate.Type, player: Player)
    local _ = player.Character or player.CharacterAdded:Wait()

    self._playerDeathConnections[player] = player.CharacterAdded:Connect(function()
        onPlayerDeath(self, player)
    end)
end

function PlayerDeathsDetector:Initialize()
    Players.PlayerAdded:Connect(function(player)
        onPlayerAdded(self, player)
    end)

    for _, player: Player in pairs(Players:GetPlayers()) do
        onPlayerAdded(self, player)
    end

    Players.PlayerRemoving:Connect(function(player)
        if self._playerDeathConnections[player] then
            self._playerDeathConnections[player]:Disconnect()
            self._playerDeathConnections[player] = nil
        end
    end)
end

function PlayerDeathsDetector.new()
    local self = setmetatable(PlayerDeathsDetector, {__index = ServiceTemplate})
    self._playerDeathConnections = {}

    return self
end

return PlayerDeathsDetector