---@diagnostic disable-next-line: undefined-type
local function GetKeys(t: {[k]: v}) : {k}
	local keys = {}

	for key, _ in pairs(t) do
		table.insert(keys, key)
	end

	return keys
end

return GetKeys