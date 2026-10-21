local NumberPostfixes = {
	[1] = "";
	[2] = "K";
	[3] = "M";
	[4] = "B";
	[5] = "T";
	[6] = "Qa";
	[7] = "Qi";
	[8] = "Sx";
	[9] = "Sp";
	[10] = "Oc";
	[11] = "Nm";
	[12] = "Dc";
	[13] = "Udc";
	[14] = "Ddc";
	[15] = "Tdc";
	[16] = "Qadc";
	[17] = "Qidc";
	[18] = "Sxdc";
	[19] = "Spdc";
	[20] = "Ocdc";
	[21] = "Nmdc";
	[22] = "Vg";
	[23] = "Uvg";
	[24] = "Dvg";
	[25] = "Tvg";
	[26] = "Qavg";
	[27] = "Qivg";
	[28] = "Sxvg";
	[29] = "Spvg";
	[30] = "Ocvg";
	[31] = "Nmvg";
	[32] = "Tg";
}

local SignificantDigits = 3 -- 1.38K, 13.8K, 138K; до тысячи — целое

--[[ отбрасывание, а не округление: 999.9K не превращается в «1000K», а прогресс не забегает вперёд ]]
local function formatNumber(value: number): string
	if value ~= value or math.abs(value) == math.huge then
		return "???"
	end

	local sign = if value < 0 then "-" else ""
	local absolute = math.abs(value)

	if absolute < 1000 then
		return sign .. math.floor(absolute)
	end

	local exponent = 0

	while absolute >= 1000 ^ (exponent + 1) do
		exponent += 1
	end

	local normal = absolute / 1000 ^ exponent
	local decimals = math.max(0, SignificantDigits - #tostring(math.floor(normal)))
	local scale = 10 ^ decimals
	local shown = ("%." .. decimals .. "f"):format(math.floor(normal * scale) / scale)

	if decimals > 0 then
		shown = shown:gsub("0+$", ""):gsub("%.$", "")
	end

	return sign .. shown .. (NumberPostfixes[1 + exponent] or ("e+" .. exponent * 3))
end

return formatNumber
