local ToolsConfig = {}

ToolsConfig.ToolTypeAttribute = "ToolType" -- set on the Tool by whoever creates it, the server

--[[ higher is more important; an unknown type gets zero and is never equipped. Example: {Sword = 2; Shovel = 1} ]]
ToolsConfig.Priority = {}

--[[ what the game's use button shows per tool type; an unknown type hides the button, an empty ImageId shows Label. Example: {Sword = {Label = "HIT"; ImageId = ""}} ]]
ToolsConfig.Actions = {}

return ToolsConfig
