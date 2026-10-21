--[[
	Подпись клавиши на кнопке — маленький кружок в её углу.

	Живёт отдельно, потому что подписывать надо разные кнопки в разных модулях,
	а правило на всех одно.

	Структура бейджа в StarterGui: Frame "KeyBadge" с детьми "KeyLabel" (TextLabel)
	и "KeyIcon" (ImageLabel). Кнопку с таким бейджем заводит игра — в каркасе
	вызовов нет ни одного, и это не забытый код, а готовый инструмент.
]]

local UserInputService = game:GetService("UserInputService")

local KeyBadge = {}

--[[
	На геймпаде рисуем глиф самой консоли: подписи кнопок у Xbox и PlayStation
	разные, и угадывать их текстом нельзя. Глиф приходит не для всех устройств —
	тогда остаётся текст из конфига.
]]
local function getGamepadImage(keyCode: EnumItem?): string?
	if not keyCode then return nil end

	local success, result = pcall(function()
		return UserInputService:GetImageForKeyCode(keyCode)
	end)

	return success and result or nil
end

--[[ по PreferredInput, а не по типу устройства: на ПК с воткнутым геймпадом игрок может играть и тем, и другим ]]
local function getControlType(): string
	local preferred = UserInputService.PreferredInput

	if preferred == Enum.PreferredInput.Touch then return "Mobile" end
	if preferred == Enum.PreferredInput.Gamepad or preferred == Enum.PreferredInput.MicroGamepad then return "Console" end

	return "Desktop"
end

--[[
	Привести бейдж в соответствие с текущим вводом.

	hint — секция ControlsConfig вида {GamepadKeyCode, Labels = {Desktop, Console, Mobile}}.
	Пустая подпись значит "бейджа нет": так он пропадает на мобилке.
]]
function KeyBadge.Apply(badge: Frame?, hint: {[string]: any})
	if not badge then return end

	local controlType = getControlType()
	local label = badge:FindFirstChild("KeyLabel")
	local icon = badge:FindFirstChild("KeyIcon")
	local text = hint.Labels and hint.Labels[controlType] or ""

	if text == "" then
		badge.Visible = false

		return
	end

	local image = if controlType == "Console" then getGamepadImage(hint.GamepadKeyCode) else nil
	local hasImage = image ~= nil and image ~= ""

	if icon then
		icon.Visible = hasImage
		icon.Image = image or ""
	end

	if label then
		label.Visible = not hasImage
		label.Text = text
	end

	badge.Visible = true
end

--[[ Apply сейчас и на каждой смене PreferredInput; соединение отключает владелец кнопки ]]
function KeyBadge.Bind(badge: Frame?, hint: {[string]: any}): RBXScriptConnection
	KeyBadge.Apply(badge, hint)

	return UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
		KeyBadge.Apply(badge, hint)
	end)
end

return KeyBadge
