local MarketplaceService = game:GetService("MarketplaceService")
local MaxTries = 3
local RetryDelay = 2

local TryGetProductInfo = function(id: number, infoType: Enum.InfoType)
	local tries = 0
	local result = nil

	repeat
		local isSuccess, value = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)

		if not isSuccess then
			warn("An error occured while getting product info: " .. tostring(value))
			task.wait(RetryDelay * (tries + 1))
		else
			result = value
		end

		tries += 1
	until isSuccess or tries == MaxTries

	return result
end

return TryGetProductInfo