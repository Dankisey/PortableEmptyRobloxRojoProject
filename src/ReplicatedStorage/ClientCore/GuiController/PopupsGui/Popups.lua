local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PopupRequested = ReplicatedStorage.Remotes.UI.PopupRequested
local PopupsTemplatesFolder = ReplicatedStorage.Assets.UI.Popups
local Config = require(ReplicatedStorage.Configs.PopUpsConfig)

local TweenService = game:GetService("TweenService")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local Popups = {}

-- local function accumulateAndDisplay(self, statName, value)
--     self._pendingAmounts[statName] += value

--     if self._displayTimers[statName] then
--         task.cancel(self._displayTimers[statName])
--     end

--     self._displayTimers[statName] = task.delay(1, function()
--         local pending = self._pendingAmounts[statName]
--         if pending > 0 then
--             self._controllers.GuiController.MainGui.Upper:ShowPlusNStats(statName, pending)
--             self._pendingAmounts[statName] = 0
--         end
--     end)
-- end

local function spawnPopup(self, statName) : Frame
	local popupClone = PopupsTemplatesFolder[statName]:Clone()
	popupClone.Name = statName
	local x = self._random:NextNumber(Config.SpawningArea[statName].CornerA.X, Config.SpawningArea[statName].CornerB.X)
	local y = self._random:NextNumber(Config.SpawningArea[statName].CornerA.Y, Config.SpawningArea[statName].CornerB.Y)
	popupClone.UIScale.Scale = Config.AppearingParameters[statName].StartSize
	popupClone.Position = UDim2.fromScale(x, y)
	popupClone.Parent = self._frame

	return popupClone
end

local function shootPopup(self, statName: string, carryingAmount: number?)
	local popup = spawnPopup(self, statName)

	-- accumulateAndDisplay(self, statName, carryingAmount)

	local appearingTween = Config.GetAppearingTween(popup)
	appearingTween:Play()
	appearingTween.Completed:Wait()

	local movingTween = Config.GetDisappearingTween(popup)
	movingTween:Play()
	movingTween.Completed:Wait()

	popup:Destroy()
end

local function makeBurst(self, statName: string, amount: number)
	local popupsAmount = math.min(amount / Config.BurstParameters.TargetAmountPerVisual, Config.BurstParameters.VisualsLimit)

	if popupsAmount < 1 then
		popupsAmount = 1
	end

	popupsAmount = math.ceil(popupsAmount)
	local popupValue = amount / popupsAmount

	task.spawn(function()
		for _ = 1, popupsAmount do
			task.spawn(shootPopup, self, statName, popupValue)
			task.wait(Config.BurstParameters.AppearingRate)
		end
	end)
end

function Popups:FirePopup(statName: string, data: any)
	task.spawn(function()
		if statName == "Cash" then
			makeBurst(self, statName, data)
		elseif statName == "MagicPower" or statName:match("Potion") then
			shootPopup(self, statName, data)
		end
	end)
end

function Popups:Initialize()
	self._pendingAmounts = { Cash = 0}
	self._displayTimers = { Cash = nil}

	PopupRequested.OnClientEvent:Connect(function(...)
		self:FirePopup(...)
	end)
end

function Popups.new(frame)
	local self = setmetatable(Popups, {__index = ControllerTemplate})
	self._frame = frame
	self._random = Random.new()

	return self
end

return Popups