local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local tweenInfo = TweenInfo.new(.08, Enum.EasingStyle.Quad)

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)

local ButtonsInteractionsConnector = {}

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
		task.cancel(self._connectedButtons[button].HoveringTask)
		self._connectedButtons[button].IsActive = false
		table.clear(self._connectedButtons[button])
		self._buttonsParent[button] = nil
		self._connectedButtons[button] = nil
	end)
end

function ButtonsInteractionsConnector:ConnectButton(button: GuiButton, callback: (any) -> (), ... : any)
	if self._connectedButtons[button] then return end

	self._connectedButtons[button] = {}
	self._buttonsParent[button] = getButtonsScreenGui(button)

	local uiScale = button:FindFirstChildOfClass("UIScale")
	local newScale = uiScale or Instance.new("UIScale")
	newScale.Parent = button
	local playHoverSound = false
	newScale.Scale = .97

	self._connectedButtons[button] = {}
	self._connectedButtons[button].IsActive = true
	local args: any = table.pack(...)

	self._connectedButtons[button].Connection = button.MouseButton1Down:Connect(function()
		if self._tweenigButtons[button] then return end

		self._tweenigButtons[button] = true

		task.spawn(function()
			callback(table.unpack(args))
		end)

		local tween1 = TweenService:Create(newScale, tweenInfo, {Scale = .92})
		tween1:Play()
		tween1.Completed:Wait()

		self._controllers.SoundPlayer:PlaySound(self._configs.SoundNames.Click)

		-- local tween2 = TweenService:Create(newScale, tweenInfo, {Scale = 1.01})
		-- tween2:Play()
		-- tween2.Completed:Wait()

		local tween3 = TweenService:Create(newScale, tweenInfo, {Scale = .97})
		tween3:Play()
		tween3.Completed:Wait()

		self._tweenigButtons[button] = nil
	end)

	self._connectedButtons[button].HoveringTask = task.spawn(function()
		while self._connectedButtons[button].IsActive do
			task.wait()

			if self._tweenigButtons[button] then continue end

			if self._isMobile then
				local tween1 = TweenService:Create(newScale, tweenInfo, {Scale = .97})
				tween1:Play()
			else
				if not self._buttonsParent[button] then continue end

				if isHoveringOver(button) then
					if playHoverSound and isEnabled(button) then
						playHoverSound = false
						self._controllers.SoundPlayer:PlaySound(self._configs.SoundNames.Hover)
					end

					local tween = TweenService:Create(newScale, tweenInfo, {Scale = 1})
					tween:Play()
				else
					playHoverSound = true
					local tween = TweenService:Create(newScale, tweenInfo, {Scale = .97})
					tween:Play()
				end
			end
		end
	end)
end

function ButtonsInteractionsConnector.new()
	local self = setmetatable(ButtonsInteractionsConnector, {__index = ControllerTemplate})
	self._isMobile = isMobile()
	self._tweenigButtons = {}
	self._connectedButtons = {}
	self._buttonsParent = {}

	return self
end

return ButtonsInteractionsConnector