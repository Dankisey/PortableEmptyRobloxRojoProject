# Input and interface

## World GUI and first person

- **`BillboardGui.Active = true` stops first person camera rotation**: a billboard under the crosshair sinks mouse movement, and a click on it becomes `gameProcessed`, so the tool drops it. `Active` only where it is tapped (touch). The `Active` condition must match the condition that draws the key label.
- **`SurfaceGui` has the opposite `Active` default**: `Instance.new("SurfaceGui").Active == true`, while `BillboardGui` has `false`. Set `Active = false` by hand on world GUI without buttons.
- **World GUI is one for everybody**: a personal number (a price, the HP of "your" object) cannot be shown on it — everyone sees the same. Personal data goes into a `ScreenGui` or a custom prompt; the personal state of a world object is an attribute with the `UserId` in its name, hidden by the client through `LocalTransparencyModifier` and `SurfaceGui.Enabled`.

## Buttons

- **A button without `ConnectButton` is visually dead**: unconnected buttons did not animate, and the default `AutoButtonColor` darkened them — it read as "no animations". Connect every visible button; the connector turns darkening off itself, and the layout has it off already.
- **A button with states is several buttons.** An action button in a window was two `TextButton`s (active and `...NoActive`) switched by `Visible`; one was connected, and in the unavailable state the player pressed the unconnected one — darkening without bounce. Connect every variant, even with an empty action.
- **The template cursor used to hide unconditionally**, leaving third person players without a cursor. Now it hides only with `LockFirstPerson`.
- **`GuiButton.Activated` fires on release** — for timing that is a real bug. A press on every device is `GuiObject.InputBegan` with a filter (`MouseButton1`, `Touch`, `KeyCode.ButtonA`): without the filter it fires on hover too, without `ButtonA` the gamepad loses buttons.
- **`MouseButton1Down` does not fire on some phones** — buttons "die".
- **The press animation ate every second press** (a callback only for a button free of animation). Invisible on PC, on a phone — "works every other time". A callback on every press, the animation separately, duplicates are dropped by `DuplicateInputWindow`.
- **The hover task created a tween every frame** (thousands of `TweenService:Create` per second on a screen with buttons). A tween only when the target scale changes (fixed in `ButtonsInteractionsConnector`).
- **A button `UIScale` has one owner** — `ButtonsInteractionsConnector`; an extra scale (an active slot) is an attribute the connector reads, otherwise animations fight.
- **Dynamic lists through the connector leak**: one coroutine task per button; a screen recreating dozens of cards on a filter change loses dozens of tasks at once. `DisconnectButton`, or direct subscriptions that die with the instance.
- **The own color of a decorated button is invisible**: with the visuals in children the button itself is transparent. The source of truth is the layout; state coloring is an explicit call on the visual child.
- **Do not stack button states from PNGs**: different semi-transparent edges give a second outline. One background; text and icons on a `ZIndex` above backgrounds.
- **State buttons** lie on top of each other and switch by `Visible`; two visible buttons call different methods.

## Keys

- **Custom prompt input cannot be guarded by `gameProcessed`**: `ProximityPromptService` takes `KeyboardKeyCode` and marks the press processed. Chat typing is cut by `if UserInputService:GetFocusedTextBox() then return end`.
- **A prompt on the same key takes it before `ContextActionService`**: a key bound through CAS at a high priority with `Sink` got no presses while a `ProximityPrompt` with that key was in range, and `InputBegan` came with `gameProcessed = true`. A tap on the scene is not affected, so "only tap works". Fix — turn off `ProximityPromptService.Enabled` for the time of your input mode and restore the previous value, or give the prompt another key. Check — a probe with a prompt on that key nearby: `Triggered` count 0, the mode's events arrive.
- **A prompt with `Style = Custom` never gets `PromptTriggered`** — neither on the server nor the client. A custom prompt sends its own remote, the server validates the distance. `InputHoldBegin()` from `execute_luau` is not a valid probe.
- **A prompt with `KeepShownOnUse`** is removed when its target instance disappears, not on press: the server may refuse. The cooldown goes on the success branch.
- **Space is jump.** `ContextActionService:BindActionAtPriority(name, handler, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)` (above the jump priority), `Sink` on `Begin`. Unbind on **every** exit from the state, otherwise the player cannot jump for the rest of the session.
- **The key label follows the active input**, not the device: the criterion is `UserInputService.PreferredInput`. `IsTenFootInterface` and `GamepadEnabled` lie to those who simply plugged in a gamepad. It is a separate method; the control type for the cursor and touch areas stays as is. `GetImageForKeyCode` returns a glyph even without a gamepad. The framework does this: `KeyBadge.Apply` takes `PreferredInput`, `KeyBadge.Bind` rebuilds the badge on its change.

## Layout

- **`ResetOnSpawn = true` destroys stored references**: the subscription lives, properties change, nothing on screen. New `ScreenGui` — `false`.
- **`UIScale` scales the object's position and its `UIPadding`**: a row shrunk by a container `UIScale` moved up. Shrink elements, not the container; `UIListLayout` gaps are computed from the container.
- **`UIScale` multiplies 9-slice edges**: compute an adaptive `SliceScale` from `AbsoluteSize` divided by the product of the `UIScale` of the image and its ancestors.
- **With `AutomaticCanvasSize`, `UIPadding` is not part of the canvas** — spacing comes from a transparent template cell around the visual block ([ui](../rules/ui.md#lists)).
- **A full screen window opens with `Enable(true)`**, not through the `TryAddToEnablingQueue` queue, which silently postpones it while the screen is busy. `Disable()` fires its event even for a hidden screen — guard with `if isVisible == self:IsVisible() then return end`.
- **The Robux glyph** `\u{E002}` is a Roblox private use character, not standard Unicode: in the source it looks like an empty space and is lost on copy, it renders only in text objects and not in every font ([DevForum](https://devforum.roblox.com/t/how-to-use-built-in-robux-icons/3081879)). One formatting function, the character as an escape sequence; check its look in the project font in Studio. If it renders wrong, use an icon `ImageLabel` next to the text instead.
- **Visual children over a button pass input through by `InputSink`**: a `GuiObject` defaults to `InputSink = None` — pointer and activation events go to elements beneath it; a `GuiButton` defaults to `Activate` ([InputSink](https://create.roblox.com/docs/reference/engine/enums/InputSink)). Keep visual children of an empty button at `None` and `Active = false`; a visual set to `All` swallows the press.

## Loading screen and UI animations

- The loading screen and its config live in `ReplicatedFirst`; it hides on two attributes ("save read" and "`ClientCore` finished `Start()`") with a timeout; only the HUD is restored, not "all `ScreenGui`s as they were".
- Two animations that cover the screen together are not opposite tweens: there are freezes under the loading screen and a gap between them. The new panel slides over, the old one is removed on `Completed`. One tween per property.

## Camera

- A temporary switch to third person (ragdoll): change `LocalPlayer.CameraMode` and turn off the transparency bind with it, otherwise the character is invisible.
- `CameraController:ShakeWithoutPivoting`, `TweenTo`, `FreezeCamera`, `FixThirdPerson` cannot be undone without the paired `ResetCamera`.
- Camera sway and hits are written into `Camera.CFrame` on `RenderPriority.Camera + 1`, guarded by `CameraType == Custom` and a living `Humanoid` subject. Step the spring with the exact exponential solution: Euler gave a frame rate dependent result. Do not take a third-party camera controller — it takes the camera from `RagdollCamera`.
