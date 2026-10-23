local HttpService = game:GetService("HttpService")

-- blacklist is a set {[guid] = true}, not an array: a lookup stays constant while the registry grows
local function GenerateGuid(blacklist: {[string]: any}?)
	local guid

	repeat
		guid = string.sub(HttpService:GenerateGUID(false), 1, 8)
	until not (blacklist and blacklist[guid])

	return guid
end

return GenerateGuid
