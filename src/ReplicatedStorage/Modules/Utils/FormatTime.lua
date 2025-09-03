local function getSlot(value: number)
	value = math.floor(value)

	if value > 9 then
		return tostring(value)
	else
		return string.format("0%i", value)
	end
end

local function FormatTime(seconds: number, minSlotsAmount: number): string
	local minutes = (seconds - seconds % 60) / 60
	seconds = seconds - minutes * 60

	local hours = (minutes - minutes % 60) / 60
	minutes = minutes - hours * 60

	local days = (hours - hours % 24) / 24
	hours = hours - days * 24

	if days > 0 or minSlotsAmount == 4 then
		return string.format("%s:%s:%s:%s", getSlot(days), getSlot(hours), getSlot(minutes), getSlot(seconds))
	elseif hours > 0 or minSlotsAmount == 3 then
		return string.format("%s:%s:%s", getSlot(hours), getSlot(minutes), getSlot(seconds))
	elseif minutes > 9 or minSlotsAmount == 2 then
		return string.format("%i:%s", minutes, getSlot(seconds))
	else
		return string.format("%i", seconds)
	end
end

return FormatTime