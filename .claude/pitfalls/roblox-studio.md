# MCP tools

The most expensive points arrive by hook ([reminders](../hooks/roblox-mcp-reminders.json)); full entries are here.

## `execute_luau`

### A separate VM: `require` of a project module fails or lies

`require` of a project module from here may fail: `The current thread cannot require 'X' since 'X' has additional values for the Capabilities property`. Where it works, it returns **another instance** with a cache between calls — after an edit the module returned its old version, and the sign was a missing new function. In some places it worked; do not rely on it.

The reliable path for numbers and checks is `loadstring(module.Source)` in Edit. A module that `require`s inside gets its dependencies as varargs:

```lua
local source = module.Source:gsub("local WorldQuery = require%(.-%)\n", "")
local loaded = assert(loadstring("local WorldQuery = ...\n" .. source))(WorldQuery)
```

Live singleton state cannot be read from here: only the world, `GameValues`, attributes, remotes or a probe script ([validation](validation.md#a-probe-script-gives-the-live-singleton)).

### The Command Bar does not give the live service either

A direct `require(ServerCore.SomeService):Method(...)` from the server Command Bar failed on `self._states[player]`: the table was missing although the player was loaded. The Command Bar got a separate ModuleScript instance where DI never called `new()`. Never call `new()` to "fix" it: that creates another service without injections and state. Create a temporary `Script` in `ServerScriptService`, call the API from it and let it delete itself.

### `_G` lives between calls

There is one `execute_luau` VM per Studio session: a value put into `_G` in one call is read in the next. A large builder can be installed once and later calls send only data. After Studio reconnects, install it again.

### No `loadstring` in Play

`loadstring() is not available`. Configs can be loaded past the cache only in Edit.

### A new ModuleScript — through `multi_edit`

`Instance.new("ModuleScript")` + `Parent` may fail on Capabilities (`LoadUnownedAsset` and three more). Creating through `multi_edit` with `className` and an empty `old_string` works. Folders are created by `execute_luau` normally. Do not work around the limit; after an error, first check whether the object was created.

### A script created by `multi_edit` lives as a document

Six modules were created by `multi_edit` with a `return {}` stub, then the full code was written through `.Source` from `execute_luau`. `loadstring` over `.Source` — 0 errors, the module test — green, and in Play `PowerService has no constructor` and `MainGui was not created`: Play took the editor document with the stub still in it. `script_read` showed the same stub. A clone of the script on the same path did not help — the document sticks to the path.

Fix — write through the document: `game:GetService("ScriptEditorService"):UpdateSourceAsync(script, function() return text end)` from `execute_luau` works. Verify with `script_read` (it shows the document), not `.Source` and not `loadstring`.

Rule: **a new script — `multi_edit` with a stub, then the text through `UpdateSourceAsync`, verification with `script_read`, the final check is a Play run.**

### `.Source` is empty or stale — checks read `GetEditorSource`

Eight modules written with `UpdateSourceAsync` returned `.Source = ""`, and every script edited in the session had `.Source` different from the document — while Play worked. Place compilation over `.Source` showed "0 errors": `loadstring("")` compiles, the new modules were not checked at all.

Text for compilation, type checks and checksums is `game:GetService("ScriptEditorService"):GetEditorSource(script)`; snippets — in [validation](validation.md#syntax-of-the-whole-place-without-play). After `File → Save` most scripts matched, but the last ones edited by `UpdateSourceAsync` kept an old `.Source`. After a second save and a Studio restart the place had the latest versions. Rule: after saving, compare `.Source` with `GetEditorSource`; on a mismatch, save again.

### Signals are deferred

`workspace.SignalBehavior` = `Deferred`: a `Changed` handler does not run at the moment of assignment. Writing and reading in one call looks as if the handler is dead. Put `task.wait(.5)` between write and read; a suspected dead subscription is checked by a probe that writes the fact of the call into a `StringValue`.

### Slicing `.Source` by bytes hangs the response

`source:sub(a, b)` cuts by bytes; a boundary in the middle of a multibyte character gives broken UTF-8, and the response never arrives — the call times out as if Studio hung. Cut by lines (`gmatch("[^\n]*\n")`) or read with `script_read`.

### Long strings and probes

- Lua drops a newline right after `[[`: a "just in case" `sub(2)` cuts the first letter (`ocal function`). `loadstring` in the same call catches it.
- Inside `probe.Source = [[...]]` any `--[[` closes the string. The outer bracket is one level deeper than the inner one: `[===[ ... --[==[ ... ]==] ... ]===]`. Otherwise the answer is `Failed to parse command code` without a line. The same applies to find and replace pairs written as long strings.

### `gsub` with a replacement from another `gsub`

`gsub` returns two values, and `source:gsub(p, new:gsub("%%", "%%%%"))` passes the count as the third argument `n`; `n = 0` means zero replacements, without an error. Always wrap the replacement in brackets: `(new:gsub("%%", "%%%%"))`.

### Some service properties are closed by capabilities, and the error breaks the whole call

`game.Lighting.Technology` is read with `lacking capability RobloxScript` — and whatever the call did before stays in the place half done (a transfer folder was created, its content was not). Wrap reads of service properties in `pcall`; after a failed call, first look at what it created and continue from there instead of repeating the whole thing.

### Files and network are closed

The tool neither reads nor writes files; `HttpService:GetAsync/PostAsync` answer `lacking capability Network`. `http_get` of MCP reaches only the Roblox documentation; localhost and files are not available. Transfer — [source-transfer](source-transfer.md).

### Hundreds of `LoadAsset` do not fit into one call

`InsertService:LoadAsset` of a group asset from `execute_luau` in Edit works, but takes noticeable time per model: hundreds of models exceed the call timeout. Fix — the body in `task.spawn` with progress and a report in `Workspace` attributes, polled by separate calls. Check — the report attribute is not `running` and the model count in folders.

## `multi_edit`

### `replace_all` silently does nothing

The report says "edits applied", nothing changes. Mass replacements — through `.Source` with a check against fresh text.

### Tabs in JSON break the call

A literal tab inside `old_string`/`new_string` is not valid JSON: the whole argument stays a string, and the validator answers `edits: expected array, received string` — which says nothing about the file. Project indentation is tabs, so write them as `\t`. An edit without indentation passes and confuses.

### Matching by substring

`old_string` and a `gsub` pattern match as a substring: a line with one tab matches the end of a line with two, and the edit lands in another function. Take a chunk with neighboring lines; cut large blocks by unique markers (`source:find(marker, 1, true)`).

**Verify by the NEW text:** the new chunk almost always contains the old one, and "the old one is gone" gives a false alarm. Count occurrences of the new text — exactly one, with `find(..., true)` (`gsub` gives a false zero on brackets and dots). Count by the definition line (`local function renderBadge`), not by a call — that matches inside the definition.

```lua
local count, from = 0, 1
while true do
	local a, b = script_.Source:find(new, from, true)
	if not a then break end
	count += 1
	from = b + 1
end
```

### Do not mix `multi_edit` and `.Source` on one file

`multi_edit` after an edit through `.Source` duplicated the tail of the file (two `return`, `Expected <eof>`). And `.Source` from `execute_luau` right after `multi_edit` returns the text **before** the edit: a slice by markers from it silently rolls the edit back. Finish with the tool you started with. **Verify a `multi_edit` edit with `script_read`.** `loadstring` does not catch a duplicated `export type`.

### A timeout is not "maybe it passed"

`Request timed out` on one file three times in a row, and the file was untouched each time. An edit is atomic: after a timeout read the file first, otherwise a retry spoils the text.

## `script_grep` / `script_read`

- `script_grep` **does not count empty lines**: the number is smaller than the real one, and the difference grows down the file. `script_read` gives the line address and ignores `start_line`/`end_line`, returning the whole file.
- A `script_grep` query is a Luau pattern: `( ) % . - + [ ]` break the search, and an empty answer reads as "it is not there". Search for a chunk without these characters.
- In Play both see the client DataModel: `ServerStorage` answers `No matches` / `Script not found`. Read code in Edit, in Play — `.Source` through `execute_luau` with `datamodel_type = "Server"`.
- A method called as `pcall(obj.Method, obj)` is not found by `:Method(`: search for `.Method,` and `.Method)` too.

## Studio and windows

- **Edits can be rolled back silently**: a human `Ctrl+Z` or a place reload undoes everything. Four objects disappeared a few steps after successful reports and a matching checksum. Check that an object exists in a separate call before using it.
- **An unsaved session loses all work**: the next one opened on the version before all edits, with a clean console and zero `loadstring` errors. Edits in an open Studio do not reach Roblox by themselves; ask for `File → Save to Roblox` (a local file — `File → Save`) at the end of work.
- Another place may be open next to it: pick `studio_id` by the PlaceId in the window name.
- `start_stop_play` in auto mode may be refused by the classifier as an irreversible action. Do not retry: a human starts Play or allows it explicitly; write Play scenarios as Command Bar snippets right away.

## Frames and images

- Calls have a delay of seconds: short windows cannot be caught by a screenshot; a static frame with `camera_position`/`look_at_position` works for a long phase.
- **`screen_capture` in Play shows the client view** — with HUD and the player camera; camera parameters do not work in Play. In Edit a frame with `camera_position`/`look_at_position` is good for composition.
- **`screen_capture` in Play does not draw `BillboardGui`**: an HP bar with `Enabled = true` and its point in frame, its copy in `PlayerGui` and a plain red billboard over the head — empty on the frame, while the `ScreenGui` HUD is visible. Check billboards by state (`Enabled`, text, `WorldToViewportPoint`) and hand them to `[visual]`.
- **`screen_capture` in Edit does not show continuous particle emission**: an emitter with `Rate` is empty on the frame, a copy with a manual `Emit(20)` is visible. Particle looks are checked by eye in Run; by machine — properties and `Texture`.
- `screen_capture` may return GUI with a black world — the window is minimized or covered. Check: a neon part 12 studs in front of the camera. In this state `camera_position` does not move the camera.
- `StarterGui` is drawn in Edit: a screen can be viewed without Play — clone the `ScreenGui`, fill it, take a frame, restore the original.
- Color on a frame lies near bright fills (contrast, compression). Check color and geometry by number, the frame is for composition.
- `UIStroke` in `ScaledSize` is a share of the size (`.05`–`.1`), in `FixedSize` — pixels; the mode cannot be guessed from the number. Test `Instance.new` strokes arrive in `FixedSize` and "confirm" a wrong conclusion. Read `StrokeSizingMode`, set the mode of a new stroke explicitly or clone it from the layout.
- `upload_image` takes only an http link (`Only http/https URLs are supported`): a local `python -m http.server 8731 --bind 127.0.0.1`, stop it after the upload. `screen_capture` does not write to disk.
- A freshly uploaded image in a second Studio window may render tiny in a corner: the asset is not warm yet. Check — `AssetService:CreateEditableImageAsync` → `Size`.

## Synthetic input

- `user_keyboard_input` may fail with `CoreGUI has keyboard focus`, `user_mouse_input` with `position hits CoreGUI`; `VirtualInputManager` from a probe — `lacking capability RobloxScript`. With such an answer clicks and keys go to `[visual]`. Where input works, a GUI button click is still checked by state (connected, visible, rest scale), the tap itself goes to `[visual]`.
- **`keyDown` without `keyUp` in the same call keeps the key pressed** until it is released: a W held over three calls drove the character off the map. `keyDown` and `keyUp` go into one call with a `wait` between them; to read state during a hold, release the key in the very next call.

## Input and camera in Studio

- **The PlayerModule is different in Play.** `StarterPlayer.PlayerModule` is built on the Input Action System (contexts like `CharacterContext`, `CameraContext`, a `MoveAction` of type Direction2D). In Edit it is missing, it is not in `PlayerScripts`, and there is no public API (`GetControls`): the old `require(PlayerScripts:WaitForChild("PlayerModule"))` hangs with `Infinite yield possible`. It occupies keys: LeftShift — mouse lock, other keys and gamepad buttons — ability actions. Read movement for own mechanics from `Humanoid.MoveDirection`; a key taken by the PlayerModule is sunk by own action, otherwise both fire. Check the current set in the documentation.
- **`MoveDirection` is rotated by the camera of the frame start.** If own `RenderStep` code turns the camera, removing its rotation from `MoveDirection` with the current `Camera.CFrame` is wrong: the error equals the turn per frame, and a "straight" W steers. Remember the camera rotation on `RenderPriority.First`.

## Assets and imports

- **`insert_asset` inserts a package with a random turn**: a group model comes as a package (`PackageLink`), a MeshPart with an arbitrary Y rotation and not anchored. Bones stay in place: compare them in the mesh local axes (`CFrame:VectorToObjectSpace`). After inserting, set `CFrame` explicitly and anchor the parts.
- **An image for `TextureID` is not a decal id.** Open Cloud uploads a PNG as a `Decal`, and the manifest gets the decal id. `TextureID` needs the image id: `InsertService:LoadAsset(decalId)` in Edit returns a `Decal` with `Texture = rbxassetid://<another id>`. Check — `TextureID` differs from the decal id.
- **An Open Cloud upload operation may end with `Unknown Error`** and create no asset: write the error instead of the operation and continue; a rerun sends it again.
- **Large data from disk goes into Studio only by human hands.** Passing megabytes through MCP parameters fills the agent context. A script writes `.rbxmx`, the human inserts them with one Insert from File.
