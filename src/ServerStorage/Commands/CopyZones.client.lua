local zonePrefab = workspace:FindFirstChild("1")

for _, zone in pairs(workspace.PlayersZones:GetChildren()) do
  local clone = zonePrefab:Clone()
  clone.Name = zone.Name
  clone:PivotTo(zone:GetPivot())
  clone.Parent = zone.Parent
  zone:Destroy()
end