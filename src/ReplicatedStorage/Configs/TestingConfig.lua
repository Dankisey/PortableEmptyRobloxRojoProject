local RunService = game:GetService("RunService")

local TestingConfig = {}

TestingConfig.IsTesting = true and RunService:IsStudio()
TestingConfig.GizmosColor = "red"

return TestingConfig