--[[
	Работа с горизонтальной проекцией векторов.

	Высота в сравнениях только мешает: враг выше рыбы и ниже игрока на берегу,
	а спот лежит на поверхности воды. Маска и расстояние были размножены
	по пяти файлам, поэтому живут здесь.
]]
local FlatVector = {}

FlatVector.Mask = Vector3.new(1, 0, 1)

--[[ Минимальная длина, ниже которой нормализация дала бы NaN. ]]
local MinMagnitude = .05

function FlatVector.Distance(a: Vector3, b: Vector3): number
	return ((a - b) * FlatVector.Mask).Magnitude
end

--[[
	Нормализованная плоская проекция вектора. Если проекция выродилась
	(точки совпали или вектор смотрит строго вверх) — отдаём запасное направление.
]]
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
