local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local GuiController = {}

local function tryEnableNextGui(self)
	if #self._enablingQueue == 0 then return end

	local gui: ScreenGui = table.remove(self._enablingQueue, 1)
	self._currentEnabledConflictingGui = gui
	gui.Enabled = true
end

function GuiController:ForceEnabling(gui: ScreenGui)
	if not self._configs.ConflictingGuisConfig[gui.Name] then
		gui.Enabled = true

		return
	end

	self._isLastForced = true

	if self._currentEnabledConflictingGui then
		self._currentEnabledConflictingGui.Enabled = false
	end

	self._currentEnabledConflictingGui = gui
	gui.Enabled = true
end

function GuiController:TryAddToEnablingQueue(gui: ScreenGui)
	if not self._configs.ConflictingGuisConfig[gui.Name] then
		gui.Enabled = true

		return
	end

	if #self._enablingQueue == 0 and not self._currentEnabledConflictingGui then
		self._currentEnabledConflictingGui = gui
		gui.Enabled = true
	elseif not table.find(self._enablingQueue, gui) then
		table.insert(self._enablingQueue, gui)

		local comprassion = function(gui1: ScreenGui, gui2: ScreenGui)
			return gui1.DisplayOrder > gui2.DisplayOrder
		end

		table.sort(self._enablingQueue, comprassion)
	end
end

function GuiController:AfterPlayerLoaded(player: Player)
	for _, guiModule in pairs(self._guiModules) do
		task.spawn(guiModule.AfterPlayerLoaded, guiModule, player)
	end

	local function onImageAdded(image)
        local onRenderStepped = RunService.RenderStepped:Connect(function(dt)
			if image.Rotation >= 180 then
				image.Rotation = -180
			end
			image.Rotation += 0.3
		end)

		CollectionService:GetInstanceRemovedSignal("UISunray"):Connect(function()
			onRenderStepped:Disconnect()
		end)
    end

    for _, image in CollectionService:GetTagged("UISunray") do
        onImageAdded(image)
    end

    CollectionService:GetInstanceAddedSignal("UISunray"):Connect(onImageAdded)
end

function GuiController:Initialize(player: Player)
	local guiModuleNames = self._utils.GetKeys(self._guiModules)
	local initializedGuiModules = {}

	for name, guiModule in pairs(self._guiModules) do
		task.spawn(function()
			guiModule:Initialize(player)
			table.insert(initializedGuiModules, name)
		end)

		if self._configs.ConflictingGuisConfig[name] then
			guiModule.Disabled:Subscribe(self, function()
				self._currentEnabledConflictingGui = nil

				if self._isLastForced then
					self._isLastForced = false
				else
					tryEnableNextGui(self)
				end
			end)
		end
	end

	repeat task.wait() until #initializedGuiModules == #guiModuleNames
end

function GuiController:InjectConfigs(configs)
	self._configs = configs

	for _, guiModule in pairs(self._guiModules) do
		guiModule:InjectConfigs(configs)
	end
end

function GuiController:InjectUtils(utils)
	self._utils = utils

	for _, guiModule in pairs(self._guiModules) do
		guiModule:InjectUtils(utils)
	end
end

function GuiController:InjectControllers(controllers)
	self._controllers = controllers

	for _, guiModule in pairs(self._guiModules) do
		guiModule:InjectControllers(controllers)
	end
end

function GuiController.new()
	local self = setmetatable({}, {__index = GuiController})

	local children = script:GetChildren()
	self._enablingQueue = {}
	self._guiModules = {}

	for _, child in children do
		local success, module = pcall(require, child)

		if not success then
			warn("Module " .. child.Name .. " was not loaded: " .. tostring(module))

			continue
		end

		self[child.Name] = module.new()
		self._guiModules[child.Name] = self[child.Name]
	end

	return self
end

return GuiController