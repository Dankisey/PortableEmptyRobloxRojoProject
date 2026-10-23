local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Mouse = game:GetService("Players").LocalPlayer:GetMouse()

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local tweenInfo = TweenInfo.new(.08, Enum.EasingStyle.Quad)
local BounceTweenInfo = TweenInfo.new(.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SettleTweenInfo = TweenInfo.new(.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local RestScale = .97 -- under the cursor the button grows to 1
local PressedScale = .9
local BounceScale = 1.06 -- overshoot after the press

--[[ some devices send one tap twice; kept short so a deliberate second press still passes ]]
local DuplicateInputWindow = .05 -- seconds

local ButtonsInteractionsConnector = {}

--[[ InputBegan, not Activated (fires on release) or MouseButton1Down (missing on some touch devices); the filter drops MouseMovement ]]
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

--[[ tween only when the target changes: a tween per frame per button dropped phone frame rates on busy screens ]]
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

			--[[ the press animation returns the rest scale itself ]]
			if self._tweeningButtons[button] then
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

	--[[ the scale is the feedback; the default darkening is not wanted ]]
	button.AutoButtonColor = false

	startHovering(self, button, newScale)

	return newScale
end

--[[ touches differ by object, but mouse and gamepad may send the release as a new object ]]
local function isSameInput(pressed: InputObject, input: InputObject): boolean
	if input == pressed then return true end

	if pressed.UserInputType == Enum.UserInputType.Touch then return false end

	return input.UserInputType == pressed.UserInputType and input.KeyCode == pressed.KeyCode
end

function ButtonsInteractionsConnector:DisconnectButton(button: GuiButton)
	if not self._connectedButtons[button] then return end

	task.spawn(function()
		while self._tweeningButtons[button] do
			task.wait()
		end

		local uiScale = button:FindFirstChildOfClass("UIScale")

		if uiScale then
			local tween = TweenService:Create(uiScale, tweenInfo, {Scale = RestScale})
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

function ButtonsInteractionsConnector:ConnectButton(button: GuiButton, callback: (any) -> (), ...: any)
	if self._connectedButtons[button] then return end

	local newScale = prepareButton(self, button)
	local args: any = table.pack(...)

	self._connectedButtons[button].Connection = button.InputBegan:Connect(function(input: InputObject)
		if not isPressInput(input) then return end

		local now = os.clock()

		if now - (self._lastActivations[button] or 0) < DuplicateInputWindow then return end

		self._lastActivations[button] = now

		--[[ the callback runs on every press, not only when the animation is idle, or fast taps are eaten ]]
		task.spawn(function()
			callback(table.unpack(args))
		end)

		if self._tweeningButtons[button] then return end

		self._tweeningButtons[button] = true

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

		self._tweeningButtons[button] = nil
	end)
end

--[[ the press squeeze holds until release; the end is caught through UserInputService because a finger slides off and the button's InputEnded never comes ]]
function ButtonsInteractionsConnector:ConnectHoldButton(button: GuiButton, onPress: () -> (), onRelease: () -> ())
	if self._connectedButtons[button] then return end

	local newScale = prepareButton(self, button)
	local pressed: InputObject? = nil

	self._connectedButtons[button].Connection = button.InputBegan:Connect(function(input: InputObject)
		if not isPressInput(input) or pressed then return end

		pressed = input
		self._tweeningButtons[button] = true
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

		--[[ pressed again mid-bounce: the squeeze is already playing ]]
		if pressed then return end

		local settle = TweenService:Create(newScale, SettleTweenInfo, {Scale = RestScale})
		settle:Play()
		settle.Completed:Wait()

		if not pressed then
			self._tweeningButtons[button] = nil
		end
	end)
end

function ButtonsInteractionsConnector.new()
	local self = setmetatable(ButtonsInteractionsConnector, {__index = ControllerTemplate})

	self._isMobile = isMobile()
	self._tweeningButtons = {}
	self._lastActivations = {}
	self._connectedButtons = {}
	self._buttonsParent = {}

	return self
end

return ButtonsInteractionsConnector
