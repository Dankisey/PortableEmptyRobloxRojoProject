local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local GuiController = {}

local InitializingMaxTime = 20 -- seconds, the same limit as ClientCore

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

		local compareByDisplayOrder = function(gui1: ScreenGui, gui2: ScreenGui)
			return gui1.DisplayOrder > gui2.DisplayOrder
		end

		table.sort(self._enablingQueue, compareByDisplayOrder)
	end
end

function GuiController:AfterPlayerLoaded(player: Player)
	for _, guiModule in pairs(self._guiModules) do
		task.spawn(guiModule.AfterPlayerLoaded, guiModule, player)
	end

	--[[ one connection per image and one removal subscription for the whole tag ]]
	local sunrayConnections = {}

	local function stopSunray(image)
		if not sunrayConnections[image] then return end

		sunrayConnections[image]:Disconnect()
		sunrayConnections[image] = nil
	end

	local function onImageAdded(image)
		if sunrayConnections[image] then return end

		sunrayConnections[image] = RunService.RenderStepped:Connect(function()
			--[[ the image may be destroyed without removing the tag ]]
			if not image.Parent then
				stopSunray(image)

				return
			end

			if image.Rotation >= 180 then
				image.Rotation = -180
			end

			image.Rotation += .3
		end)
	end

	for _, image in CollectionService:GetTagged("UISunray") do
		onImageAdded(image)
	end

	CollectionService:GetInstanceAddedSignal("UISunray"):Connect(onImageAdded)

	CollectionService:GetInstanceRemovedSignal("UISunray"):Connect(stopSunray)
end

function GuiController:Initialize(player: Player)
	local guiModuleNames = self._utils.GetKeys(self._guiModules)
	local initializedGuiModules = {}

	for name, guiModule in pairs(self._guiModules) do
		task.spawn(function()
			--[[ without pcall a failed module never reaches the initialized list and the wait below hangs ]]
			local success, err = pcall(guiModule.Initialize, guiModule, player)

			if not success then
				warn("Error occurred while initializing GUI module " .. name .. ":", err)
			end

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

	--[[ one module stuck on WaitForChild would otherwise hang the whole client start ]]
	local elapsedTime = 0

	repeat
		elapsedTime += task.wait()
	until (#initializedGuiModules == #guiModuleNames) or (elapsedTime >= InitializingMaxTime)

	if #initializedGuiModules == #guiModuleNames then return end

	warn("Uninitialized GUI modules:")

	for _, name in guiModuleNames do
		if not table.find(initializedGuiModules, name) then
			warn(name)
		end
	end
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

		--[[ one broken frame constructor would otherwise remove the whole interface and blame GuiController ]]
		local created

		success, created = pcall(function()
			return module.new()
		end)

		if not success then
			warn("GUI module " .. child.Name .. " was not created: " .. tostring(created))

			continue
		end

		self[child.Name] = created
		self._guiModules[child.Name] = created
	end

	return self
end

return GuiController