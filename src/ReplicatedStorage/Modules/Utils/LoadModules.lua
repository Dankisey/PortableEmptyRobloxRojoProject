--[[ the only place with "Module X was not loaded"; ServerCore and ClientCore require it by path because utils are not injected yet ]]
local function LoadModules(folder: Instance): {[string]: any}
	local modules = {}

	for _, moduleScript in folder:GetChildren() do
		local success, module = pcall(require, moduleScript)

		if not success then
			warn("Module " .. moduleScript.Name .. " was not loaded: " .. tostring(module))

			continue
		end

		modules[moduleScript.Name] = module
	end

	return modules
end

return LoadModules
