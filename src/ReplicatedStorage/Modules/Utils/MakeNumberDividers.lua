local function makeSpaces(number: number, divider: string) : string
	local numberString = tostring(number)
	local result = string.reverse(numberString)

	return result:gsub("(%d%d%d)", "%1" .. divider):reverse() 
end

return makeSpaces