local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UtilsTypes = require(ReplicatedStorage.Modules.UtilsTypes)

local ServerTypes = require(script.Parent.ServerTypes)
local ServiceTemplate: ServerTypes.ServiceTemplate = {}

export type Type = ServerTypes.ServiceTemplate

function ServiceTemplate:InjectServices(services: ServerTypes.Services)
    self._services = services
end

function ServiceTemplate:InjectUtils(utils: UtilsTypes.Utils)
    self._utils = utils
end

function ServiceTemplate:InjectConfigs(configs)
    self._configs = configs
end

return ServiceTemplate