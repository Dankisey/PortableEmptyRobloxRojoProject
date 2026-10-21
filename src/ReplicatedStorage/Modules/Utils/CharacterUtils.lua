--[[
	Общие проверки персонажа. Раньше это было написано заново в восьми местах —
	трижды отдельной функцией и пять раз инлайном.
]]
local CharacterUtils = {}

--[[
	Живой персонаж игрока. Нет персонажа, нет рутпарта или здоровье на нуле —
	возвращаем nil, чтобы вызывающий гасился однострочным гвардом.
]]
function CharacterUtils.GetAlive(player: Player): (Model?, BasePart?, Humanoid?)
	local character = player.Character

	if not character then return nil, nil, nil end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root or humanoid.Health <= 0 then return nil, nil, nil end

	return character, root :: BasePart, humanoid
end

function CharacterUtils.GetAliveRoot(player: Player): BasePart?
	local _, root = CharacterUtils.GetAlive(player)

	return root
end

--[[
	Опорная часть тела для рэгдолла и вихря. Цепочка идёт от R15 к R6
	и заканчивается рутпартом: он есть всегда.
]]
function CharacterUtils.GetTorso(character: Model): BasePart?
	return character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

return CharacterUtils
