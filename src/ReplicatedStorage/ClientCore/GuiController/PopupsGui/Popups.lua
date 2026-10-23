local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PopupRequested = ReplicatedStorage.Remotes.UI.PopupRequested
local PopupsTemplatesFolder = ReplicatedStorage.Assets.UI.Popups

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local Config = require(ReplicatedStorage.Configs.PopUpsConfig)

local Popups = {}

local function spawnPopup(self, popupName: string): GuiObject
	local area = Config.SpawningArea[popupName]
	local popup = PopupsTemplatesFolder[popupName]:Clone()
	local x = self._random:NextNumber(area.CornerA.X, area.CornerB.X)
	local y = self._random:NextNumber(area.CornerA.Y, area.CornerB.Y)

	popup.Name = popupName
	popup.UIScale.Scale = Config.AppearingParameters[popupName].StartSize
	popup.Position = UDim2.fromScale(x, y)
	popup.Parent = self._frame

	return popup
end

local function shootPopup(self, popupName: string)
	local popup = spawnPopup(self, popupName)

	local appearingTween = Config.GetAppearingTween(popup)
	appearingTween:Play()
	appearingTween.Completed:Wait()

	local movingTween = Config.GetDisappearingTween(popup)
	movingTween:Play()
	movingTween.Completed:Wait()

	popup:Destroy()
end

local function makeBurst(self, popupName: string, amount: number)
	local parameters = Config.BurstParameters
	local popupsAmount = math.ceil(math.clamp(amount / parameters.TargetAmountPerVisual, 1, parameters.VisualsLimit))

	for _ = 1, popupsAmount do
		task.spawn(shootPopup, self, popupName)
		task.wait(parameters.AppearingRate)
	end
end

function Popups:FirePopup(popupName: string, amount: number?)
	if not PopupsTemplatesFolder:FindFirstChild(popupName) then return warn("Popups: no template " .. tostring(popupName)) end

	local isBurst = Config.BurstPopups[popupName] == true and type(amount) == "number"

	if isBurst then
		task.spawn(makeBurst, self, popupName, amount)
	else
		task.spawn(shootPopup, self, popupName)
	end
end

function Popups:Initialize()
	PopupRequested.OnClientEvent:Connect(function(...)
		self:FirePopup(...)
	end)
end

function Popups.new(frame: Frame)
	local self = setmetatable(Popups, {__index = ControllerTemplate})

	self._frame = frame
	self._random = Random.new()

	return self
end

return Popups
