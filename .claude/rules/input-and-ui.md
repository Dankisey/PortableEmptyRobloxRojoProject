---
paths: [".claude/docs/systems/remotes-and-values.md", ".claude/decisions/input-and-ui.md", ".claude/pitfalls/input-and-ui.md"]
---

# Input, tools, camera

Interface layout, buttons and screens — [ui](ui.md).

- **Everything in hand is a `Tool`** with the `ToolsConfig.ToolTypeAttribute` attribute. `ManualActivationOnly = true`, `Tool.Activated` is not listened to. Use goes only through `ToolsController:UseEquippedTool()`/`ReleaseEquippedTool()`; the mechanic owner registers the action with `RegisterAction`.
- The game adds the on-screen use button by the `ToolsConfig.Actions` contract plus `Modules.UI.KeyBadge` (`KeyBadge.Bind` — the label follows `UserInputService.PreferredInput`, not the device). A key and its label come from one `ControlsConfig` section; a new mechanic adds its own section. Tap anywhere on screen — the `ControlsConfig.Use.TapAnywhere` flag, off.
- One key — one mechanic in one state. A `ProximityPrompt` on the same key takes it before `ContextActionService` ([pitfall](../pitfalls/input-and-ui.md#keys)).
- Buttons go only through `ButtonsInteractionsConnector` (`InputBegan` with an input filter), not `Activated`: it fires on release. **Every** visible button is connected, including future ones without an action (empty callback): the press animation with bounce and the click sound exist only on connected buttons. A hold button is `ConnectHoldButton`: the squeeze holds while pressed, bounce and return happen only on release. The connector turns off `AutoButtonColor` itself.
- A game field for taps inside a mini game is not a button: it listens to its own `InputBegan` and `UserInputService.InputEnded` for the same `InputObject`, without the connector, or the press animation squeezes the whole field.
- The cursor is visible in third person; `InputController` hides it only with `CameraMode = LockFirstPerson`.
- Release has no `gameProcessed` guard. A touch releases a tool only through a button that catches the end of its own touch (`ConnectHoldButton`): any touch release would also fire from the stick finger. Custom prompt input is guarded by `GetFocusedTextBox()`, not `gameProcessed`.
- Space is jump: intercept through `ContextActionService` at `High` and unbind on **every** exit from the state, ragdoll included.
- **The interface never sinks mouse input in the screen center.** `BillboardGui.Active` only on touch devices; full screen elements are hidden with `Visible = false`.
- Camera: the mode is the `StarterPlayer.CameraMode` property. `LockFirstPerson` requires `CameraConfig.FirstPersonVisibility`; an own transparency bind goes on `Camera.Value + 1`.
- Phones are the main platform: buttons at least finger sized, nothing important under the stick and the jump button. The game is landscape only (`StarterGui.ScreenOrientation = LandscapeSensor`, [decision](../decisions/input-and-ui.md#landscape-only)).

Before an edit read [remotes-and-values](../docs/systems/remotes-and-values.md), [decisions](../decisions/input-and-ui.md) and [pitfalls](../pitfalls/input-and-ui.md).
