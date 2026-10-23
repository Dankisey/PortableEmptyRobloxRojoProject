# Remotes, values, controls

## Remotes (`ReplicatedStorage.Remotes`)

`ClientInitialized`, `KickRequested`, `SoundRequested`, `UI` (`PopupRequested`, `ServerMessageSent`), `Monetization` (`DevProductRequested`, `GamepassRequested`), `Ragdoll.StateChanged`.

`Ragdoll.StateChanged` goes `FireAllClients(target, enabled, impulse)`: every client builds the pose, only the owner applies the impulse.

Outside `Remotes`: `AdminGui.CommandRequested` lives in the admin panel clone in `PlayerGui` and is seen only by its owner; arguments are the command name and a number (for `AddCash`). The server checks that the sender owns the clone and is in `DevelopersConfig`, the `AdminConfig.RequestCooldown`, the name against `AdminConfig.Commands` and the number — a whole number from 1 to `MaxAmount`.

Every new remote: the server checks the arguments (type, range, distance, cooldown, object ownership) before any action.

## `GameValues`

The folder is empty — run state `Value` instances go here. They replicate for free, so a counter needs no remote: the module subscribes to `Changed` in `AfterPlayerLoaded`. If the save is not read, the counter stays `...`, not `0`.

## Player attributes

Only the server sets them; a client write stays local. Player attributes are visible to all clients.

| Attribute | Set by | Meaning |
|---|---|---|
| `IsLoaded` | `SavesLoader` | the save load **finished** (not necessarily successfully); the client waits for it before `AfterPlayerLoaded` |
| `IsClientInitialized` | `ServerCore` on `ClientInitialized` | `ClientCore` finished `Start()`; the admin panel is delivered after it |
| `JoinTime`, `OwnsPremium`, `CanPurchaseRandomItems`, game pass attributes | `SavesLoader` | join data |
| `Cash` | `SoftCurrencyService` | balance; attribute name = currency name |

A saved value is published by its section owner ([saves](saves.md#sections)); no attribute means the save is not loaded, the counter shows `...`.

## Instance attributes

| Attribute | Where | Set by | Meaning |
|---|---|---|---|
| `DeveloperPurchasesEnabled` | `ServerStorage.ServerCore.Monetization` | `Monetization:SetDeveloperPurchasesEnabled` | free developer purchases on this server; `false` in the place |
| `DeveloperPurchasesEnabled` | the `AdminGui` clone in `PlayerGui` | `AdminService` | mirror of the module attribute for the panel label |

## Tools and the use button

**Everything the player holds is a `Tool`.** The type is a string in the `ToolsConfig.ToolTypeAttribute` (`"ToolType"`) attribute on the tool itself; whoever creates the tool sets it.

| Who | What |
|---|---|
| Server | creates the tool, puts it into the backpack, sets the type attribute |
| `ToolsConfig.Priority` | which tool matters more if there are several |
| `ToolsController` | equips the highest priority one from hand and backpack |
| `ToolsController:RegisterAction` | what using a given type does |
| `ToolsConfig.Actions` | label and icon of the on-screen button |
| `Modules.UI.KeyBadge` | key label in the corner of that button |

Tools get `ManualActivationOnly = true`, nobody listens to `Tool.Activated`. Use goes only through `ToolsController:UseEquippedTool()`: `ControlsConfig.Use` keys, the game's on-screen button and, with `TapAnywhere` on, a short tap outside the interface ([decision](../../decisions/input-and-ui.md#tap-anywhere-on-screen--behind-a-flag-off)). The second entry is `ReleaseEquippedTool()`: on mouse and gamepad `InputEnded` and on window focus loss; a touch never releases — the hold button catches the end of its own touch (`ConnectHoldButton`).

**There is no on-screen button in the framework.** The game adds it: connects `ConnectHoldButton(button, UseEquippedTool, ReleaseEquippedTool)`, shows it by the `ToolsConfig.Actions` entry for the held tool type, the key label is `KeyBadge.Bind`.

## Controls (`ControlsConfig`)

`ControlsConfig.Use`: `MouseButton1`, `ButtonR2`, `TapAnywhere = false` (`TapMaxMove` in pixels, `TapMaxDuration` in seconds); labels `LMB` / `RT` / empty on phones (no badge). A key and its label live in one section; a new mechanic adds its own section. The badge picks its label by `UserInputService.PreferredInput`: text on PC, a glyph through `GetImageForKeyCode` on gamepad, no badge on touch.

## Interface buttons

All buttons go through `ButtonsInteractionsConnector`: `GuiObject.InputBegan` with an input type filter, not `GuiButton.Activated`. The callback runs on every press, the animation separately (squeeze, bounce, rest), `DuplicateInputWindow` drops duplicates of one tap, `AutoButtonColor` is turned off on connect.

## Camera

The mode is the `StarterPlayer.CameraMode` **property** (third person in the template). The cursor is hidden only with `LockFirstPerson`. Turning on `LockFirstPerson` — also turn on `CameraConfig.FirstPersonVisibility`. Details — [input-and-ui](../../rules/input-and-ui.md).
