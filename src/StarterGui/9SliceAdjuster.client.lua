local starterGui = script.Parent
local mainGui = starterGui:WaitForChild("MainGui")
local uiAssets = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("UI")
local targetResolution = Vector2.new(1920, 1080)
local currentResolution = mainGui.AbsoluteSize
local xScale = currentResolution.X / targetResolution.X
local yScale = currentResolution.Y / targetResolution.Y

local resultScale = math.min(xScale, yScale)

for _, desc: ImageLabel in pairs(starterGui:GetDescendants()) do
	if desc:IsA("ImageLabel") == false then continue end

	if desc.ScaleType ~= Enum.ScaleType.Slice then continue end

	desc.SliceScale *= resultScale
end

for _, desc: ImageLabel in pairs(uiAssets:GetDescendants()) do
	if desc:IsA("ImageLabel") == false then continue end

	if desc.ScaleType ~= Enum.ScaleType.Slice then continue end

	desc.SliceScale *= resultScale
end