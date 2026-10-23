--[[ a key and its label live in one section: when they drift apart the label lies to the player; an empty label means no badge ]]
local ControlsConfig = {}

ControlsConfig.Use = {
	MouseButton = Enum.UserInputType.MouseButton1;
	GamepadKeyCode = Enum.KeyCode.ButtonR2;

	TapAnywhere = false; -- a touch outside the interface and the stick uses the tool on release, like in clickers
	TapMaxMove = 10; -- pixels of finger movement
	TapMaxDuration = .25; -- seconds on screen

	Labels = {
		Desktop = "LMB";
		Console = "RT";
		Mobile = "";
	};
}

--[[ a new mechanic adds its own section; Space is jump and must be bound through ContextActionService at High and unbound on every exit ]]

return ControlsConfig
