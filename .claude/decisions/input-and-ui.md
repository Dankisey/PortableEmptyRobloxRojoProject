# Tools, input, interface

## Nobody listens to `Tool.Activated`

The default activation fires on a tap anywhere on screen and does not know what is in hand: a tap on the interface activates the tool, a second tool needs a second handler, a hold cannot be expressed. So `ManualActivationOnly = true`, and the only entry point is `ToolsController:UseEquippedTool()`.

**The framework does not know what a tool type does:** the owner registers `RegisterAction(toolType, onUse, onRelease)`. An action table in `ToolsController` would tie the framework to game mechanic names.

**There is no on-screen use button in the framework on purpose:** its look and place belong to the game. The ready parts are `ToolsConfig.Actions`, `Modules.UI.KeyBadge` and `ButtonsInteractionsConnector:ConnectHoldButton`.

## Tap anywhere on screen — behind a flag, off

`ControlsConfig.Use.TapAnywhere = true`: on touch devices a short tap outside GUI and the stick calls `UseEquippedTool` **on release** — the finger moved less than `TapMaxMove` and stayed less than `TapMaxDuration`. On release, so a camera swipe does not start with an extra use. Recognition lives in `ToolsController`: one entry for all tools and devices. PC and gamepad use on press.

Cost: use is delayed by the tap length. That a stick touch arrives with `gameProcessed = true` is an assumption, to be checked in Play on a phone emulator.

The flag is off in the template: clickers need it, games with a hold button are hurt by it.

## Release has no `gameProcessed` guard; a touch never releases the tool

A started hold must end wherever the cursor is: an eaten release leaves the player in the windup forever. On press the guard is right — a click on the interface must not use the tool.

A touch in `ToolsController` **does not release** the tool: a finger leaving the movement stick is also a touch and would cut the hold of the on-screen button. The button catches the end of its own touch — `ConnectHoldButton` listens to `UserInputService.InputEnded` and compares the press `InputObject`: the finger slides off the button, and its own `InputEnded` may never come.

## Buttons listen to `InputBegan`, not `Activated`

`GuiButton.Activated` fires on **release** — for a timing mechanic that is a real bug. The fix is in the shared button machine (`ButtonsInteractionsConnector`), not local: two press schemes in one project guarantee screens that disagree. There also: the callback runs on **every** press (the animation never eats fast presses) and `DuplicateInputWindow` against duplicates of one tap.

Press — squeeze, bounce with overshoot, return to rest; the default `AutoButtonColor` darkening is turned off on connect. The hover tween runs only when the target changes: a tween per frame per button dropped phone frame rates.

The hold button (`ConnectHoldButton`): the press squeeze holds while pressed, bounce and return happen only on release.

## The key label follows `PreferredInput`, not the device

`KeyBadge.Apply(badge, hint)` picks the label by `UserInputService.PreferredInput` (`Touch` → `Mobile`, `Gamepad`/`MicroGamepad` → `Console`, otherwise `Desktop`), `KeyBadge.Bind` rebuilds the badge when it changes. A device type passed by the caller lies on a PC with a plugged in gamepad. The control type for the cursor and touch areas (`InputController:GetControlType`) is a different question and stays as is.

## The cursor hides only in first person

`InputController` follows `Player.CameraMode`: the cursor is hidden only with `LockFirstPerson`.

## First person character transparency is computed by the framework

The default `TransparencyController` in first person hides the character together with the held tool and **turns off completely** when `CameraSubject` stops being a `Humanoid` — which `RagdollCamera` does. The own bind runs on `Camera.Value + 1`: at equal priority the default one overwrites the result in the same frame. It is behind `CameraConfig.FirstPersonVisibility`, off: the template plays in third person, and the flag would hide the character.

## The interface never sinks mouse input

In first person the cursor is locked in the center, and anything covering the center that takes input steals camera rotation and tool use. So `BillboardGui.Active` is on only on touch devices (`adaptInputToDevice` in `CustomPromptTemplate`), and a full screen element is hidden with `Visible = false`, not `Active`.

## Landscape only

`StarterGui.ScreenOrientation = LandscapeSensor`: there is no portrait on any screen. Games with a stick and action buttons read better in landscape, and the layout keeps one format. Cost: a player holding the phone upright has to rotate it. Mobile layout is checked in landscape only. Revision — a game that needs portrait.

## Layout comes from prepared templates

The Studio layout is the source of truth: code clones prepared templates and changes only content and state, never building GUI with `Instance.new` (except `UIScale` for animations). A button is an empty transparent `GuiButton` for input, all visuals are children over it. Lists use a wrapped `UIListLayout` with spacing built into a transparent template cell instead of `Padding`, which keeps `AutomaticCanvasSize` correct. Proportions use `SizeConstraint` instead of `UIAspectRatioConstraint`. Interactive elements are anchored in the center so the press `UIScale` scales from the middle. Requirements — [ui](../rules/ui.md).

Why: a layout built by code cannot be checked by eye in Studio and drifts from the design; one template per element keeps fonts, colors and sizes consistent. Cost: every new element starts in Studio, not in code.
