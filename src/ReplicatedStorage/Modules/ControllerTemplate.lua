local ClientTypes = require(script.Parent.ClientTypes)
local UtilsTypes = require(script.Parent.UtilsTypes)

export type Type = ClientTypes.ControllerTemplate

local ControllerTemplate: ClientTypes.ControllerTemplate = {}

function ControllerTemplate:InjectControllers(controllers: ClientTypes.Controllers)
    self._controllers = controllers
end

function ControllerTemplate:InjectUtils(utils: UtilsTypes.Utils)
    self._utils = utils
end

function ControllerTemplate:InjectConfigs(configs)
    self._configs = configs
end

return ControllerTemplate