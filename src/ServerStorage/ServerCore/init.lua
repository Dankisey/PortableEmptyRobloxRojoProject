local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientInitialized = ReplicatedStorage.Remotes.ClientInitialized

local ServerCore = {}

ClientInitialized.OnServerEvent:Connect(function(player: Player)
	player:SetAttribute("IsClientInitialized", true)
end)

function ServerCore:Start()
	local services = {}
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

	print("Start creating server modules")
	for _, moduleScript in pairs(script:GetChildren()) do
		local success, module = pcall(require, moduleScript)

		if not success then
			warn("Module " .. moduleScript.Name .. " was not loaded: " .. tostring(module))

			continue
		end

		if not module.new then
			warn(moduleScript.Name .. " has no constructor")
		else	
			services[moduleScript.Name] = module.new()
		end
	end
	print("Server modules were created")

	print("Injecting services")
	for _, service in services do
		if service.InjectServices then
			service:InjectServices(services)
		end
	end
	
	print("Injecting utils")
	for _, service in services do
		if service.InjectUtils then
			service:InjectUtils(utils)
		end
	end

	print("Injecting configs")
	for _, service in services do
		if service.InjectConfigs then
			service:InjectConfigs(configs)
		end
	end
	print("Injecting completed")
	
	print("Initializing server modules")
	for _, service in services do
		task.spawn(function()
			if service.Initialize then
				service:Initialize()
			end
		end)
	end
	print("Server modules were initialized")
	
	local totalTime = tick() - startTime
	print("Server modules takes " .. totalTime .. " to start")

	print("Server setup finished")
end

return ServerCore
