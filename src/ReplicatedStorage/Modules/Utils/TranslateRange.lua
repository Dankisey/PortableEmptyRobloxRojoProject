local function translateRange(oldMin: number, oldMax: number, newMin: number, newMax: number, oldValue: number) : number
	local oldRange = oldMax - oldMin
	local newRange = newMax - newMin

	return (((oldValue - oldMin) * newRange) / oldRange) + newMin
end

return translateRange