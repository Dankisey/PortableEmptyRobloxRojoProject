local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage.Configs.WorldConfig)

--[[ water is usually an invisible collider tagged WorldConfig.WaterTag with CanQuery: ground casts must exclude it, water casts must include only it ]]
local WorldQuery = {}

local function getWaterParts(): {BasePart}
	return CollectionService:GetTagged(WorldConfig.WaterTag)
end

-- nil means both "missed" and "no water in the world"
function WorldQuery.RaycastWater(origin: Vector3, direction: Vector3): RaycastResult?
	local waterParts = getWaterParts()

	if #waterParts == 0 then return nil end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = waterParts
	params.FilterType = Enum.RaycastFilterType.Include
	params.IgnoreWater = false

	return workspace:Raycast(origin, direction, params)
end

function WorldQuery.IsOverWater(position: Vector3, height: number?): boolean
	local reach = height or 8

	return WorldQuery.RaycastWater(position + Vector3.yAxis * (reach * .5), -Vector3.yAxis * reach) ~= nil
end

-- water colliders are always excluded; ignore adds the caller's own instances
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

function WorldQuery.GetWorldFolder(name: string): Folder
	local folder = workspace:FindFirstChild(name)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = workspace
	end

	return folder
end

-- parts from both the tag and the folder, without duplicates
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
