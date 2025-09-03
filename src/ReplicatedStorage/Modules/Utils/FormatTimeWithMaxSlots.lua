local function getSlot(value: number)
	value = math.floor(value)

	if value > 9 then
		return tostring(value)
	else
		return string.format("0%i", value)
	end
end

local function FormatTimeWithMaxSlots(seconds: number, maxSlotsAmount: number): string
	maxSlotsAmount = math.max(maxSlotsAmount, 1)

	local minutes = (seconds - seconds % 60) / 60
	seconds = seconds - minutes * 60

	local hours = (minutes - minutes % 60) / 60
	minutes = minutes - hours * 60

	local days = (hours - hours % 24) / 24
	hours = hours - days * 24

	local timeValues = {days, hours, minutes, seconds}
	local postfixes = {"d", "h", "m", "s"}
	local slots = {}

	local startTimeIndex = 4

	for i: number, timeValue: number in ipairs(timeValues) do
		if timeValue > 0 then
			startTimeIndex = i

			break
		end
	end

	for i = startTimeIndex, math.min(#timeValues, startTimeIndex + maxSlotsAmount - 1) do
		table.insert(slots, {Value = timeValues[i], Postfix = postfixes[i]})
	end

	local result = tostring(slots[1].Value) .. slots[1].Postfix

	for i = 2, #slots do
		result = string.format("%s:%s%s", result, getSlot(slots[i].Value), slots[i].Postfix)
	end

	return result
end

return FormatTimeWithMaxSlots