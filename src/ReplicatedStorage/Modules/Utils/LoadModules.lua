--[[
	Загрузка папки модулей с одинаковым поведением на сервере и на клиенте:
	упавший модуль не роняет весь старт, а только печатает предупреждение.

	Строка "Module X was not loaded" — главный признак поломки фреймворка,
	поэтому она должна быть объявлена ровно один раз на весь проект.

	ВНИМАНИЕ: модуль лежит в Modules.Utils и потому сам попадает в таблицу utils.
	Это безобидно, но ServerCore/ClientCore обязаны реквайрить его напрямую
	по пути: на момент загрузки утилит инъекции ещё нет.
]]
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
