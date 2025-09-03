local Player = game:GetService("Players").LocalPlayer

local GuiTemplate = {}

function GuiTemplate:Enable(isForced: boolean)
	if isForced then
		self._controllers.GuiController:ForceEnabling(self.Gui)
	else
		self._controllers.GuiController:TryAddToEnablingQueue(self.Gui)
	end

	self.Enabled:Invoke()
end

function GuiTemplate:Disable()
	self.Gui.Enabled = false
	self.Disabled:Invoke()
end

function GuiTemplate:AfterPlayerLoaded()
	for _, module in pairs(self._frames) do
		if module.AfterPlayerLoaded then
			task.spawn(module.AfterPlayerLoaded, module, self._player)
		end
	end
end

function GuiTemplate:Initialize(player: Player)
	self._player = player

	for _, module in pairs(self._frames) do
		if module.Initialize then
			module:Initialize(player)
		end
	end
end

function GuiTemplate:InjectConfigs(configs)
	self._configs = configs

	for _, module in pairs(self._frames) do
		module:InjectConfigs(configs)
	end
end

function GuiTemplate:InjectUtils(utils)
	self._utils = utils

	for _, module in pairs(self._frames) do
		module:InjectUtils(utils)
	end

	self.Disabled = utils.Event.new()
	self.Enabled = utils.Event.new()
end

function GuiTemplate:InjectControllers(controllers)
	self._controllers = controllers

	for _, module in pairs(self._frames) do
		module:InjectControllers(controllers)
	end
end

function GuiTemplate:CreateChildren(guiName, modules)
	local gui = Player.PlayerGui:WaitForChild(guiName)

	if not gui then
		warn("There is no GUI with name " .. guiName .. " in PlayerGui")

		return
	end

	self.Name = guiName
	self.Gui = gui
	self._frames = {}

	for _, module in pairs(modules) do
		local frame = gui:FindFirstChild(module.Name)

		if not frame then
			warn("There is no objects with name " .. module.Name .. " in " .. guiName)

			return
		end

		self[module.Name] = require(module).new(frame)
		self._frames[module.Name] = self[module.Name]
	end
end

return GuiTemplate