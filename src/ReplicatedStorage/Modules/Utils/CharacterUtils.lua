local CharacterUtils = {}

-- nil when there is no character, no root part or no health, so the caller needs a one-line guard
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

-- R15, then R6, then the root part, which always exists
function CharacterUtils.GetTorso(character: Model): BasePart?
	return character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

return CharacterUtils
