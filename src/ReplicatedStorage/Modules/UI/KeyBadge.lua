local UserInputService = game:GetService("UserInputService")

--[[ badge layout: Frame "KeyBadge" with "KeyLabel" (TextLabel) and "KeyIcon" (ImageLabel) ]]
local KeyBadge = {}

--[[ the console glyph, because Xbox and PlayStation label buttons differently; falls back to config text when missing ]]
local function getGamepadImage(keyCode: EnumItem?): string?
	if not keyCode then return nil end

	local success, result = pcall(function()
		return UserInputService:GetImageForKeyCode(keyCode)
	end)

	return success and result or nil
end

--[[ by PreferredInput, not the device: a PC with a plugged in gamepad can play with either ]]
local function getControlType(): string
	local preferred = UserInputService.PreferredInput

	if preferred == Enum.PreferredInput.Touch then return "Mobile" end

	if preferred == Enum.PreferredInput.Gamepad or preferred == Enum.PreferredInput.MicroGamepad then return "Console" end

	return "Desktop"
end

-- hint is a ControlsConfig section {GamepadKeyCode, Labels = {Desktop, Console, Mobile}}; an empty label hides the badge
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

-- the button owner disconnects the returned connection
function KeyBadge.Bind(badge: Frame?, hint: {[string]: any}): RBXScriptConnection
	KeyBadge.Apply(badge, hint)

	return UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
		KeyBadge.Apply(badge, hint)
	end)
end

return KeyBadge
