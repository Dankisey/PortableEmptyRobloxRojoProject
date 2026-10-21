--[[
	WorldQuery — рейкасты и сбор объектов мира.

	Главное здесь — вода. Обычно её два разных объекта: видимый Terrain
	и невидимый коллайдер с тегом Water (CanCollide = false, но CanQuery = true).
	Из-за этого любой рейкаст «где земля» ОБЯЗАН исключать тег Water,
	иначе он считает воду твёрдой опорой, а рейкаст «где вода» — наоборот,
	только его и включать.

	Это выбор функции, а не внимательности: RaycastWater против RaycastGround.
	Собирать RaycastParams руками не надо нигде.

	Воды в проекте может не быть вовсе — тогда тегом WorldConfig.WaterTag
	ничего не помечено, RaycastWater честно вернёт nil, а RaycastGround
	просто ничего не исключит.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage.Configs.WorldConfig)

local WorldQuery = {}

local function getWaterParts(): {BasePart}
	return CollectionService:GetTagged(WorldConfig.WaterTag)
end

--[[
	Рейкаст только по воде. nil означает и «не попал», и «воды в мире нет»:
	для вызывающих это один и тот же ответ — забрасывать некуда.
]]
function WorldQuery.RaycastWater(origin: Vector3, direction: Vector3): RaycastResult?
	local waterParts = getWaterParts()

	if #waterParts == 0 then return nil end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = waterParts
	params.FilterType = Enum.RaycastFilterType.Include
	params.IgnoreWater = false

	return workspace:Raycast(origin, direction, params)
end

--[[ Есть ли вода под точкой: бьём сверху вниз с запасом по высоте. ]]
function WorldQuery.IsOverWater(position: Vector3, height: number?): boolean
	local reach = height or 8

	return WorldQuery.RaycastWater(position + Vector3.yAxis * (reach * .5), -Vector3.yAxis * reach) ~= nil
end

--[[
	Рейкаст «где твёрдая земля». Коллайдеры воды исключаются всегда,
	ignore — дополнительные объекты вызывающего (свой персонаж, папка рыбы и т. п.).
]]
function WorldQuery.RaycastGround(origin: Vector3, direction: Vector3, ignore: {Instance}?): RaycastResult?
	local filter = {}

	if ignore then
		for _, instance in ignore do
			table.insert(filter, instance)
		end
	end

	for _, waterPart in getWaterParts() do
		table.insert(filter, waterPart)
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = filter
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	return workspace:Raycast(origin, direction, params)
end

--[[ Папка в Workspace по имени; если её нет — создаём. ]]
function WorldQuery.GetWorldFolder(name: string): Folder
	local folder = workspace:FindFirstChild(name)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = workspace
	end

	return folder
end

--[[
	Парты берём и из тега, и из папки; парт, помеченный дважды, не дублируется.
	Так удобно размечать зоны и точки спавна: часть тегом, часть папкой.
]]
function WorldQuery.CollectTaggedAndFoldered(tag: string, folderName: string): {BasePart}
	local parts = {}
	local seen = {}

	local function tryAdd(instance: Instance)
		if not instance:IsA("BasePart") then return end
		if seen[instance] then return end

		seen[instance] = true
		table.insert(parts, instance)
	end

	for _, tagged in CollectionService:GetTagged(tag) do
		tryAdd(tagged)
	end

	local folder = workspace:FindFirstChild(folderName)

	if folder then
		for _, descendant in folder:GetDescendants() do
			tryAdd(descendant)
		end
	end

	return parts
end

return WorldQuery
