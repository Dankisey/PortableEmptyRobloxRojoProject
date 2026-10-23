local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientInitialized = ReplicatedStorage.Remotes.ClientInitialized

--[[ required by path: the utils table does not exist yet while utils are loading ]]
local LoadModules = require(ReplicatedStorage.Modules.Utils.LoadModules)

local ServerCore = {}

ClientInitialized.OnServerEvent:Connect(function(player: Player)
	player:SetAttribute("IsClientInitialized", true)
end)

function ServerCore:Start()
	local services = {}
	local startTime = tick()

	local utils = LoadModules(ReplicatedStorage.Modules.Utils)
	local configs = LoadModules(ReplicatedStorage.Configs)

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

	--[[ without pcall a failed Initialize is lost inside task.spawn and the service stays half alive with no log line ]]
	for name, service in services do
		task.spawn(function()
			if not service.Initialize then return end

			local success, err = pcall(service.Initialize, service)

			if not success then
				warn("Error occurred while initializing service " .. name .. ":", err)
			end
		end)
	end

	print("Server modules were initialized")

	local totalTime = tick() - startTime
	print("Server modules takes " .. totalTime .. " to start")
	print("Server setup finished")
end

return ServerCore
