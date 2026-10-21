local HttpService = game:GetService("HttpService")

--[[
	blacklist — МНОЖЕСТВО вида {[guid] = true}, а не массив.

	Раньше это был массив с table.find, то есть линейный проход по всем выданным
	за сессию GUID на каждую новую выдачу: реестр может расти весь ран,
	и стоимость шла в квадрате. Проверка ни за что: восемь hex-символов дают
	порядка четырёх миллиардов вариантов.
]]
local function GenerateGuid(blacklist: {[string]: any}?)
	local guid

	repeat
		guid = string.sub(HttpService:GenerateGUID(false), 1, 8)
	until not (blacklist and blacklist[guid])

	return guid
end

return GenerateGuid
