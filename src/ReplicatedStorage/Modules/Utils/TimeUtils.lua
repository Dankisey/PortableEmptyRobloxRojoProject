local TimeUtils = {}

TimeUtils.TimeReferencePoint = 1738641600 -- Monday, 3 February 2025, 8am GMT-8 (Unix, see more at https://www.epochconverter.com)
TimeUtils.Day = 24 * 60 * 60
TimeUtils.Week = 7 * TimeUtils.Day

function TimeUtils.IsWeekExpired(timeStamp: number)
	local weekStart = TimeUtils.TimeReferencePoint
	local weekEnd = weekStart + TimeUtils.Week
	local timeNow = os.time()
	
	while weekStart <= timeNow do
		if weekEnd >= timeNow then
			break
		end
		
		weekStart = weekEnd
		weekEnd += TimeUtils.Week
	end
	
	return timeStamp < weekStart
end

function TimeUtils.GetWeekEnd()
	local weekStart = TimeUtils.TimeReferencePoint
	local weekEnd = weekStart + TimeUtils.Week
	local timeNow = os.time()

	while weekStart <= timeNow do
		if weekEnd >= timeNow then
			break
		end

		weekStart = weekEnd
		weekEnd += TimeUtils.Week
	end

	return weekEnd
end

function TimeUtils.IsDayExpired(timeStamp: number)
	local dayStart = TimeUtils.TimeReferencePoint
	local dayEnd = dayStart + TimeUtils.Day
	local timeNow = os.time()

	while dayStart <= timeNow do
		if dayEnd >= timeNow then
			break
		end

		dayStart = dayEnd
		dayEnd += TimeUtils.Day
	end
	
	return timeStamp < dayStart
end

function TimeUtils.GetDayEnd()
	local dayStart = TimeUtils.TimeReferencePoint
	local dayEnd = dayStart + TimeUtils.Day
	local timeNow = os.time()

	while dayStart <= timeNow do
		if dayEnd >= timeNow then
			break
		end

		dayStart = dayEnd
		dayEnd += TimeUtils.Day
	end

	return dayEnd
end

return TimeUtils