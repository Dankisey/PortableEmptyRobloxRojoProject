local NumberPostfixes = require(game:GetService("ReplicatedStorage").Configs.NumberPostfixes)

local function formatNumber(value: number, decimals: number?) : string
	if value == math.huge then
		return "???"
	end

	decimals = decimals or 1

	local exponent = math.floor(math.log(math.max(1, math.abs(value)), 1000))
	local postfix = NumberPostfixes[1 + exponent] or ("e+" .. exponent)
	local normal = math.floor(value * ((10 ^ decimals) / (1000 ^ exponent))) / (10 ^ decimals)

	if normal % 1 == 0 then
		decimals = 0
	end

	return ("%." .. decimals .. "f%s"):format(normal, postfix)
end

return formatNumber