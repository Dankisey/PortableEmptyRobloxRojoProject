local FlatVector = {}

FlatVector.Mask = Vector3.new(1, 0, 1)

local MinMagnitude = .05 -- below this, normalizing would give NaN

function FlatVector.Distance(a: Vector3, b: Vector3): number
	return ((a - b) * FlatVector.Mask).Magnitude
end

-- returns fallback when the flat projection is degenerate (same points or a vertical vector)
function FlatVector.Flatten(vector: Vector3, fallback: Vector3?): Vector3
	local flat = vector * FlatVector.Mask

	if flat.Magnitude > MinMagnitude then
		return flat.Unit
	end

	return fallback or Vector3.new(0, 0, -1)
end

function FlatVector.Direction(from: Vector3, to: Vector3, fallback: Vector3?): Vector3
	return FlatVector.Flatten(to - from, fallback)
end

return FlatVector
