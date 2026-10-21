local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local tweenInfo = TweenInfo.new(.08, Enum.EasingStyle.Quad)
local BounceTweenInfo = TweenInfo.new(.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SettleTweenInfo = TweenInfo.new(.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local RestScale = .97 -- размер покоя; под курсором кнопка растёт до 1
local PressedScale = .9
local BounceScale = 1.06 -- перелёт после нажатия: это и есть «баунс»

--[[
	Окно, внутри которого второе срабатывание считается дубликатом одного и того же
	нажатия: часть устройств присылает тап дважды. Оно нарочно КОРОТКОЕ — любое
	осмысленное повторное нажатие (например, отмена выбора слота) должно проходить.
]]
local DuplicateInputWindow = .05

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local ButtonsInteractionsConnector = {}

--[[
	Что считается нажатием кнопки.

	Колбэк обязан идти В МОМЕНТ НАЖАТИЯ. Activated для этого не годится:
	он приходит по ОТПУСКАНИЮ, а подсечка в мини-игре меряется по нажатию —
	на отпускании бегунок успевает уехать с секции, и игрок промахивался мимо
	того, куда целился.

	MouseButton1Down тоже не годится, и это уже оплачено багом: это событие
	мыши, на касании оно приходит не на всех устройствах, и кнопка молча
	не работала на телефоне.

	Остаётся GuiObject.InputBegan с фильтром по типу ввода: он приходит ровно
	на нажатие и одинаково работает с мышью, тапом и кнопкой геймпада. Фильтр
	обязателен: InputBegan приходит и на наведение мыши (MouseMovement).
]]
local function isPressInput(input: InputObject): boolean
	if input.UserInputType == Enum.UserInputType.MouseButton1 then return true end
	if input.UserInputType == Enum.UserInputType.Touch then return true end

	return input.KeyCode == Enum.KeyCode.ButtonA
end

local function isMobile()
	if UserInputService.TouchEnabled and UserInputService.KeyboardEnabled == false then
		return true
	else
		return false
	end
end

local function getButtonsScreenGui(button)
	local ancestor = button.Parent

	while ancestor do
		if ancestor.ClassName == "ScreenGui" then
			return ancestor
		end

		ancestor = ancestor.Parent
	end

	return nil
end

local function isHoveringOver(button)
	local tx = button.AbsolutePosition.X
	local ty = button.AbsolutePosition.Y
	local bx = tx + button.AbsoluteSize.X
	local by = ty + button.AbsoluteSize.Y

	if Mouse.X >= tx and Mouse.Y >= ty and Mouse.X <= bx and Mouse.Y <= by then
		return true
	else
		return false
	end
end

local function isEnabled(button)
	if button.Visible == false then
		return false
	end

	local ancestor = button.Parent

	while ancestor do
		if ancestor:IsA("Frame") or ancestor:IsA("ImageLabel") or ancestor:IsA("ScrollingFrame") then
			if not ancestor.Visible then
				return false
			end
		end

		if ancestor:IsA("ScreenGui") then
			if not ancestor.Enabled then
				return false
			end
		end

		ancestor = ancestor.Parent
	end

	return true
end

--[[ твин только на смене цели: твин каждый кадр на каждую кнопку просаживал телефоны на экранах с магазином ]]
local function startHovering(self, button: GuiButton, newScale: UIScale)
	local playHoverSound = false
	local targetScale = RestScale

	local function tweenTo(scale: number)
		if scale == targetScale then return end

		targetScale = scale
		TweenService:Create(newScale, tweenInfo, {Scale = scale}):Play()
	end

	self._connectedButtons[button].HoveringTask = task.spawn(function()
		while self._connectedButtons[button].IsActive do
			task.wait()

			-- анимация нажатия сама вернёт масштаб покоя
			if self._tweenigButtons[button] then
				targetScale = RestScale

				continue
			end

			if self._isMobile then
				tweenTo(RestScale)
			else
				if not self._buttonsParent[button] then continue end

				if isHoveringOver(button) then
					if playHoverSound and isEnabled(button) then
						playHoverSound = false
						self._controllers.SoundPlayer:PlaySound(self._configs.SoundNames.Hover)
					end

					tweenTo(1)
				else
					playHoverSound = true
					tweenTo(RestScale)
				end
			end
		end
	end)
end

local function prepareButton(self, button: GuiButton): UIScale
	self._connectedButtons[button] = {IsActive = true}
	self._buttonsParent[button] = getButtonsScreenGui(button)

	local newScale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	newScale.Parent = button
	newScale.Scale = RestScale

	--[[ штатное затемнение Roblox на наведении и нажатии не нужно: отклик даёт масштаб ]]
	button.AutoButtonColor = false

	startHovering(self, button, newScale)

	return newScale
end

--[[ касания различаются объектом, а мышь и геймпад могут прислать отпускание новым объектом ]]
local function isSameInput(pressed: InputObject, input: InputObject): boolean
	if input == pressed then return true end
	if pressed.UserInputType == Enum.UserInputType.Touch then return false end

	return input.UserInputType == pressed.UserInputType and input.KeyCode == pressed.KeyCode
end

function ButtonsInteractionsConnector:DisconnectButton(button: GuiButton)
	if not self._connectedButtons[button] then return end

	task.spawn(function()
		while self._tweenigButtons[button] do
			task.wait()
		end

		local uiScale = button:FindFirstChildOfClass("UIScale")

		if uiScale then
			local tween = TweenService:Create(uiScale, tweenInfo, {Scale = .97})
			tween:Play()
		end

		self._connectedButtons[button].Connection:Disconnect()

		if self._connectedButtons[button].ReleaseConnection then
			self._connectedButtons[button].ReleaseConnection:Disconnect()
		end

		task.cancel(self._connectedButtons[button].HoveringTask)
		self._connectedButtons[button].IsActive = false
		table.clear(self._connectedButtons[button])
		self._buttonsParent[button] = nil
		self._connectedButtons[button] = nil
		self._lastActivations[button] = nil
	end)
end

function ButtonsInteractionsConnector:ConnectButton(button: GuiButton, callback: (any) -> (), ... : any)
	if self._connectedButtons[button] then return end

	local newScale = prepareButton(self, button)
	local args: any = table.pack(...)

	--[[ Именно нажатие, а не отпускание — почему, см. isPressInput. ]]
	self._connectedButtons[button].Connection = button.InputBegan:Connect(function(input: InputObject)
		if not isPressInput(input) then return end

		local now = os.clock()

		if now - (self._lastActivations[button] or 0) < DuplicateInputWindow then return end

		self._lastActivations[button] = now

		--[[
			Колбэк идёт на КАЖДОЕ нажатие, а не только когда кнопка свободна от
			анимации. Раньше анимация длиной .24 с съедала каждое второе быстрое
			нажатие: на телефоне это читалось как "выбор слота работает через раз",
			а отмена выбора повторным тапом не работала вовсе.
		]]
		task.spawn(function()
			callback(table.unpack(args))
		end)

		if self._tweenigButtons[button] then return end

		self._tweenigButtons[button] = true

		local press = TweenService:Create(newScale, tweenInfo, {Scale = PressedScale})
		press:Play()
		press.Completed:Wait()

		self._controllers.SoundPlayer:PlaySound(self._configs.SoundNames.Click)

		local bounce = TweenService:Create(newScale, BounceTweenInfo, {Scale = BounceScale})
		bounce:Play()
		bounce.Completed:Wait()

		local settle = TweenService:Create(newScale, SettleTweenInfo, {Scale = RestScale})
		settle:Play()
		settle.Completed:Wait()

		self._tweenigButtons[button] = nil
	end)
end

--[[ удержание: сжатие на нажатии и держится, отскок и возврат — только на отпускании; конец ловится через UserInputService — палец уезжает с кнопки, и её InputEnded не приходит ]]
function ButtonsInteractionsConnector:ConnectHoldButton(button: GuiButton, onPress: () -> (), onRelease: () -> ())
	if self._connectedButtons[button] then return end

	local newScale = prepareButton(self, button)
	local pressed: InputObject? = nil

	self._connectedButtons[button].Connection = button.InputBegan:Connect(function(input: InputObject)
		if not isPressInput(input) or pressed then return end

		pressed = input
		self._tweenigButtons[button] = true
		TweenService:Create(newScale, tweenInfo, {Scale = PressedScale}):Play()
		self._controllers.SoundPlayer:PlaySound(self._configs.SoundNames.Click)
		task.spawn(onPress)
	end)

	self._connectedButtons[button].ReleaseConnection = UserInputService.InputEnded:Connect(function(input: InputObject)
		if not pressed or not isSameInput(pressed, input) then return end

		pressed = nil
		task.spawn(onRelease)

		local bounce = TweenService:Create(newScale, BounceTweenInfo, {Scale = BounceScale})
		bounce:Play()
		bounce.Completed:Wait()

		-- зажали снова посреди отскока: сжатие уже играет
		if pressed then return end

		local settle = TweenService:Create(newScale, SettleTweenInfo, {Scale = RestScale})
		settle:Play()
		settle.Completed:Wait()

		if not pressed then
			self._tweenigButtons[button] = nil
		end
	end)
end

function ButtonsInteractionsConnector.new()
	local self = setmetatable(ButtonsInteractionsConnector, {__index = ControllerTemplate})
	self._isMobile = isMobile()
	self._tweenigButtons = {}
	self._lastActivations = {}
	self._connectedButtons = {}
	self._buttonsParent = {}

	return self
end

return ButtonsInteractionsConnector