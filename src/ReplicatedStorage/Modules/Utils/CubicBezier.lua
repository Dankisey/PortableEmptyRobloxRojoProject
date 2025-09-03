local CubicBezier = {}

function CubicBezier:GetValueAtTime(t: number)
	local leftTime = 1-t

	return leftTime * leftTime * leftTime * self.P0.Y +
		3 * t * leftTime * leftTime * self.P1.Y +
		3 * t * t * leftTime * self.P2.Y +
		t * t * t * self.P3.Y
end

function CubicBezier.new(x1: number, y1: number, x2: number, y2: number)
	local self = setmetatable(CubicBezier, {})
	self.P0 = Vector2.new(0, 0)
	self.P1 = Vector2.new(x1, y1)
	self.P2 = Vector2.new(x2, y2)
	self.P3 = Vector2.new(1, 1)
	
	return self
end

return CubicBezier