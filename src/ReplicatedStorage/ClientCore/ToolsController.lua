local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local ClientTypes = require(ReplicatedStorage.Modules.ClientTypes)
local ControlsConfig = require(ReplicatedStorage.Configs.ControlsConfig)
local ToolsConfig = require(ReplicatedStorage.Configs.ToolsConfig)

--[[ the server decides which tools the player has; this controller keeps the most important one in hand and never listens to Tool.Activated ]]
local ToolsController = {} :: ClientTypes.ToolsController

--[[ the game picks the tool, not the player: the default Backpack would let number keys and slot clicks unequip it ]]
local function hideBackpackGui()
	local success, err = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)

	if not success then
		warn("Failed to disable Backpack CoreGui: " .. tostring(err))
	end
end

local function getToolType(instance: Instance): string?
	if not instance:IsA("Tool") then return nil end

	local toolType = instance:GetAttribute(ToolsConfig.ToolTypeAttribute)

	return if type(toolType) == "string" then toolType else nil
end

--[[ a camera swipe also starts as a touch: a tap differs from it only after release ]]
local function isTap(start: {Position: Vector3, Time: number}, input: InputObject): boolean
	local moved = Vector2.new(input.Position.X - start.Position.X, input.Position.Y - start.Position.Y).Magnitude

	return moved <= ControlsConfig.Use.TapMaxMove and os.clock() - start.Time <= ControlsConfig.Use.TapMaxDuration
end

local function getPriority(instance: Instance): number
	local toolType = getToolType(instance)

	return toolType and ToolsConfig.Priority[toolType] or 0
end

local function getPreferredTool(self: ClientTypes.ToolsController): Tool?
	local best, bestPriority = nil, 0

	for _, container in {self._player.Character, self._player:FindFirstChild("Backpack")} do
		if not container then continue end

		for _, child in container:GetChildren() do
			local priority = getPriority(child)

			if priority > bestPriority then
				best, bestPriority = child, priority
			end
		end
	end

	return best
end

--[[ not CharacterUtils.GetAlive: the root part does not exist yet on the deferred respawn frame, and the player stayed without a tool for the session ]]
local function syncEquippedTool(self: ClientTypes.ToolsController)
	local character = self._player and self._player.Character

	if not character then return end

	local preferred = getPreferredTool(self)

	if not preferred then return end

	if preferred.Parent == character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
		or character:WaitForChild("Humanoid", 5)

	if self._player.Character ~= character then return end

	if not humanoid or humanoid.Health <= 0 then return end

	if not preferred.Parent or preferred.Parent == character then return end

	humanoid:EquipTool(preferred)
end

--[[ existing children must be checked: on respawn the Backpack arrives already filled and ChildAdded never fires for it ]]
local function watchContainers(self: ClientTypes.ToolsController)
	for _, connection in self._containerConnections do
		connection:Disconnect()
	end

	table.clear(self._containerConnections)

	--[[ outside any guard: on the first spawn there are no connections yet, and a respawn while ragdolled would keep the tool blocked ]]
	self._toolsBlocked = false

	local character = self._player.Character

	if character then
		table.insert(self._containerConnections, character.ChildAdded:Connect(function(child: Instance)
			if not child:IsA("Tool") then return end

			self.ToolEquipped:Invoke(child)
		end))

		table.insert(self._containerConnections, character.ChildRemoved:Connect(function(child: Instance)
			if not child:IsA("Tool") then return end

			self.ToolUnequipped:Invoke(child)
			task.defer(syncEquippedTool, self)
		end))
	end

	--[[ the Backpack is recreated on respawn, so it is found again every time ]]
	local backpack = self._player:FindFirstChild("Backpack") or self._player:WaitForChild("Backpack", 10)

	if backpack then
		table.insert(self._containerConnections, backpack.ChildAdded:Connect(function(child: Instance)
			if not child:IsA("Tool") then return end

			task.defer(syncEquippedTool, self)
		end))
	end

	task.defer(syncEquippedTool, self)
end

-- onRelease is needed only by tools that hold (windup, charge)
function ToolsController:RegisterAction(toolType: string, onUse: (Tool) -> (), onRelease: ((Tool) -> ())?)
	self._useActions[toolType] = onUse
	self._releaseActions[toolType] = onRelease
end

function ToolsController:SetToolsBlocked(isBlocked: boolean)
	self._toolsBlocked = isBlocked == true
end

function ToolsController:AreToolsBlocked(): boolean
	return self._toolsBlocked == true
end

function ToolsController:GetEquippedTool(): Tool?
	local character = self._player and self._player.Character

	if not character then return nil end

	return character:FindFirstChildOfClass("Tool")
end

function ToolsController:GetEquippedToolType(): string?
	local tool = self:GetEquippedTool()

	return tool and getToolType(tool) or nil
end

function ToolsController:ActivateTool(tool: Tool)
	if self._toolsBlocked then return end

	local toolType = getToolType(tool)
	local action = toolType and self._useActions[toolType]

	if not action then
		warn('Action for tool with type "' .. tostring(toolType) .. '" is not registered')

		return
	end

	action(tool)
end

function ToolsController:UseEquippedTool()
	local tool = self:GetEquippedTool()

	if not tool then return end

	self:ActivateTool(tool)
end

--[[ no blocked guard: blocking may start mid-windup, and an eaten release would leave the player in the windup forever ]]
function ToolsController:ReleaseEquippedTool()
	local tool = self:GetEquippedTool()

	if not tool then return end

	local toolType = getToolType(tool)
	local action = toolType and self._releaseActions[toolType]

	if not action then return end

	action(tool)
end

function ToolsController:AfterPlayerLoaded(player: Player)
	self._player = player

	hideBackpackGui()
	watchContainers(self)

	self._player.CharacterAdded:Connect(function(_: Model)
		watchContainers(self)
	end)

	--[[ the gameProcessed guard belongs on press: a click on the interface must not use the tool ]]
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.Touch then
			if ControlsConfig.Use.TapAnywhere then
				self._touchStarts[input] = {Position = input.Position; Time = os.clock()}
			end

			return
		end

		local isUse = input.UserInputType == ControlsConfig.Use.MouseButton
			or input.KeyCode == ControlsConfig.Use.GamepadKeyCode

		if not isUse then return end

		self:UseEquippedTool()
	end)

	--[[ no gameProcessed guard: a started hold must end wherever the cursor is; a touch never releases here, or a finger leaving the stick would cut the hold button ]]
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			local start = self._touchStarts[input]
			self._touchStarts[input] = nil

			if start and isTap(start, input) then
				self:UseEquippedTool()
			end
		end

		local isUse = input.UserInputType == ControlsConfig.Use.MouseButton
			or input.KeyCode == ControlsConfig.Use.GamepadKeyCode

		if not isUse then return end

		self:ReleaseEquippedTool()
	end)

	--[[ after focus loss the release never arrives, and a started hold would block the next press ]]
	UserInputService.WindowFocusReleased:Connect(function()
		self:ReleaseEquippedTool()
	end)
end

function ToolsController:InjectUtils(utils)
	self.ToolUnequipped = utils.Event.new()
	self.ToolEquipped = utils.Event.new()
	self._utils = utils
end

function ToolsController.new(): ClientTypes.ToolsController
	local self = setmetatable(ToolsController, {__index = ControllerTemplate})

	self._containerConnections = {}
	self._useActions = {}
	self._releaseActions = {}
	self._touchStarts = {} -- [InputObject] = {Position, Time} of a touch outside the interface
	self._toolsBlocked = false

	return self
end

return ToolsController
