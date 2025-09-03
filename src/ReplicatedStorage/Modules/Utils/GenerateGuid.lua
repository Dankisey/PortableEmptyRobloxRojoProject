local HttpService = game:GetService("HttpService")

local function GenerateGuid(blacklist: {string}?)
	blacklist = blacklist or {}
	local guid
	
	repeat 
		guid = string.sub(HttpService:GenerateGUID(false), 1, 8)
	until not table.find(blacklist, guid)

	return guid
end

return GenerateGuid