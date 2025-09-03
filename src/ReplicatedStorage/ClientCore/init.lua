local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game:GetService("Players").LocalPlayer

local ClientCore = {}
local InitializingMaxTime = 20

function ClientCore:Start()
	local controllers = {}
	local configs = {}
	local utils = {}
	local startTime = tick()

	for _, utilsModule in pairs(ReplicatedStorage.Modules.Utils:GetChildren()) do
		local success, module = pcall(require, utilsModule)

		if not success then
			warn("Module " .. utilsModule.Name .. " was not loaded: " .. tostring(module))

			continue 
		end

		utils[utilsModule.Name] = module
	end

	for _, configModule in pairs(ReplicatedStorage.Configs:GetChildren()) do
		local success, module = pcall(require, configModule)

		if not success then
			warn("Module " .. configModule.Name .. " was not loaded: " .. tostring(module))

			continue 
		end

		configs[configModule.Name] = module
	end

	print("Start creating client modules")
	for _, moduleScript in pairs(script:GetChildren()) do
		local success, module = pcall(require, moduleScript)

		if not success then
			warn("Module " .. moduleScript.Name .. " was not loaded: " .. tostring(module))

			continue 
		end

		if not module.new then
			warn(moduleScript.Name .. " has no constructor")
		else	
			controllers[moduleScript.Name] = module.new()
		end
	end
	print("Client modules were created")

	print("Injecting controllers")
	for _, controller in controllers do
		if controller.InjectControllers then
			controller:InjectControllers(controllers)
		end
	end

	print("Injecting utils")
	for _, controller in controllers do
		if controller.InjectUtils then
			controller:InjectUtils(utils)
		end
	end

	print("Injecting configs")
	for _, controller in controllers do
		if controller.InjectConfigs then
			controller:InjectConfigs(configs)
		end
	end
	print("Injecting completed")

	print("Initializing client modules")
	local controllerNames = utils.GetKeys(controllers)
	local controllersWithoutInitializing = {}
	local initializedControllerNames = {}
	local elapsedInitializingTime = 0

	for name, controller in controllers do
		task.spawn(function()
			if controller.Initialize then
				local success, value = pcall(controller.Initialize, controller, Player)

				if not success then
					warn("Error occured while initializing controller " .. name ..":", value)
				else
					table.insert(initializedControllerNames, name)
				end
			else
				table.insert(controllersWithoutInitializing, name)
			end
		end)
	end

	repeat
		elapsedInitializingTime += task.wait()
	until (#initializedControllerNames == #controllerNames - #controllersWithoutInitializing) or (elapsedInitializingTime >= InitializingMaxTime)

	if #initializedControllerNames ~= #controllerNames - #controllersWithoutInitializing then
		warn("Unitialized controllers:")

		for _, controllerName in pairs(controllerNames) do
			if (not table.find(initializedControllerNames, controllerName)) and (not table.find(controllersWithoutInitializing, controllerName)) then
				warn(controllerName)
			end
		end
	end

	print("Client modules initializing ended")

	local totalTime = tick() - startTime
	print("Client modules takes " .. totalTime .. " to start")

	if not Player:GetAttribute("IsLoaded") then
		Player:GetAttributeChangedSignal("IsLoaded"):Wait()
	end

	for name, controller in controllers do
		task.spawn(function()
			if controller.AfterPlayerLoaded then
				local success, value = pcall(controller.AfterPlayerLoaded, controller, Player)

				if not success then
					warn("Error occured while calling 'AfterPlayerLoaded' function for controller " .. name ..":",  value)
				end
			end
		end)
	end

	print("Client setup finished")

	task.spawn(function()
		task.wait(2)
		ReplicatedStorage.Remotes.ClientInitialized:FireServer()
		Player:SetAttribute("IsClientInitialized", true)
	end)
end

return ClientCore