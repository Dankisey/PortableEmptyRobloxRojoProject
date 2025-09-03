local function DeepCopy(ititialTable: {any})
	local clone = {}

	for key, value in ititialTable do
        if type(value) == "table" then
			clone[key] = DeepCopy(value)
        else
            clone[key] = value
		end
	end

	return clone
end

return DeepCopy