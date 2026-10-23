# How to check the work

## Syntax of the whole place without Play

`loadstring` in Edit only compiles. The template norm: **96 scripts, 0 errors** — a reference, not a constant: in a game the number grows with every module. Text comes from the editor document: `.Source` of edited scripts lags, and for scripts written by `UpdateSourceAsync` it is empty and compiles into a false zero ([pitfall](roblox-studio.md#source-is-empty-or-stale--checks-read-geteditorsource)). The same applies to type checks and checksums.

```lua
local ScriptEditorService = game:GetService("ScriptEditorService")
local roots = {
	game:GetService("ReplicatedStorage"), game:GetService("ServerStorage"),
	game:GetService("ServerScriptService"), game:GetService("StarterPlayer"),
	game:GetService("StarterGui"), game:GetService("ReplicatedFirst"),
	game:GetService("Workspace"),
}
local failures, missing, total = {}, {}, 0

for _, root in roots do
	for _, d in root:GetDescendants() do
		if not d:IsA("LuaSourceContainer") then continue end
		total += 1
		local source = ScriptEditorService:GetEditorSource(d)
		local chunk, err = loadstring(source, d.Name)
		if not chunk then table.insert(failures, d:GetFullName() .. ": " .. tostring(err)) end
		for name in source:gmatch("require%(script%.Parent%.([%w_]+)%)") do
			if not d.Parent:FindFirstChild(name) then table.insert(missing, d.Name .. " -> " .. name) end
		end
	end
end

return ("Scripts: %d | Errors: %d | Dangling require: %d\n%s\n%s"):format(total, #failures, #missing, table.concat(failures, "\n"), table.concat(missing, ", "))
```

Backups like `ServerStorage.RemovedBackup_*` compile but do not run — subtract them from the norm.

**What `loadstring` does not catch:**
- broken `require` with other paths (`script.Parent.Parent.X`, `ReplicatedStorage.Modules...`) — the path resolves at runtime; parse `require(...)` as text and resolve through `FindFirstChild`;
- dangling fields after removal (below);
- a duplicated `export type`;
- a missing `..`: `name "text"` is the call `name("text")` and fails only when run. Search for an identifier followed directly by a string literal.

## Dangling references after removal and rename

Use the same loop to search for names that had to disappear. A substring gives false hits (`getDebrisFolder` contains `DebrisFolder`) — search with a word boundary: `source:gsub("[^%w_]Name", "")`. The reverse is useful too: collect every `ConfigName%.(%w+)` and compare with the real field set.

A new optional argument of an old function compiles everywhere and silently gives a number for the default mode. Before changing a signature, find every caller; data the client does not have is computed on the server and put into `GameValues`.

## Types against code

Compares the `Services` / `Controllers` / `Utils` tables with the real core composition — after any module is added or removed.

```lua
local function listedIn(source: string, tableName: string): {string}
	local block = source:match("export type " .. tableName .. " = {(.-)\n}")
	local names = {}
	if block then
		for name in block:gmatch("\n%s*([%w_]+):") do table.insert(names, name) end
	end
	table.sort(names)
	return names
end
```

## GUI against modules

`GuiTemplate:CreateChildren` needs a frame with the same name for every child module and silently stops creating the rest. Check both sides: every `GuiController` module has its `ScreenGui`, every nested module has a frame in it. Removing a frame — remove the module too.

## Console

`get_console_output` after every step. `Module X was not loaded` and `Uninitialized controllers` catch almost every framework failure. On a clean start the console is empty — every line is real. At the end search for probe leftovers: there must be none.

## Config numbers for calculations

Load fresh Source, not `require`:

```lua
local Configs = game:GetService("ReplicatedStorage").Configs
local function load(name) return loadstring(Configs[name].Source, name)() end
local SavesConfig = load("SavesConfig")
```

Balance numbers in docs go stale on the first edit — before a calculation, measure the curve with a script over the current code. In weighted lists compare the length with the original: a weight that went to zero silently drops an entry through a `weight > 0` guard.

## Test config values

Speed up timings by editing the config file **before** Play: a loaded module cannot be changed at runtime. Restore the normal values and verify the restore by reading Source. In the report — "normal → test".

## Trajectory in Play instead of a snapshot

Movement is checked by a log: a client `execute_luau` starts a `task.spawn` loop that writes position and state into a `StringValue` every fraction of a second, one call plays the input scenario, the next reads and deletes the log. One snapshot shows a moment, not the behavior.

## A probe script gives the live singleton

A `LocalScript` in `PlayerGui` during Play runs in the same VM as `ClientCore`, and a `Script` in `ServerScriptService` in the same one as `ServerCore`: `require` returns the playing instance with its registries. The probe writes its answer into a `StringValue`, the caller waits for it and deletes the probe.

It is needed where the seconds of MCP latency cannot tell "pressed" from "released", and where a number lives only in a singleton. A client probe answer in a `StringValue` does not reach the server (client writes do not replicate): read it with `execute_luau` and `datamodel_type = "Client"`. Conditions: after a respawn a `LocalScript` in `PlayerGui` is removed — put it back; the probe checks that the item is really in hand; long brackets — [one level deeper](roblox-studio.md#long-strings-and-probes).

**A probe that called `RequestSave` is not deleted right away**: the debounced ProfileStore write runs in the probe script's context, and a deleted probe fails it with `Transform function error Script that implemented this callback has been destroyed while calling callback`. This is an artifact of the probe, not the code: the next autosave writes normally. Keep such a probe alive longer than `SaveInterval`, or read the error this way.

**A teleport before a hit runs ahead of the server**: a client probe put the character next to an object and hit a moment later — the server still saw it at the previous object far away, did not count the hit, and the client played the effect. The client owns character physics, and the server shows a long jump half way for a while (interpolation). Keep a pause between a teleport and an action; check "walked up to the object" with `Humanoid:MoveTo`, not a teleport.

## Numeric metrics lie

Ragdoll was "on" by every metric, while the root part flew separately from the body. Agreement between numbers proves nothing if all are measured from one reference point (a ray from the model's own pivot shifted all measurements by one value) — check the reference point itself. Physics, animations, timings, VFX and UI readability go to a human with a checklist and a snippet.

Check with a grid over the map, not a pair of points: on a real map the "the ray returned `nil`" branch fires constantly, on `Baseplate` — never.

## Measure performance on a phone, frame by frame

A freeze measured on a PC was several times shorter than on a phone; scripts on a phone run several times slower. A PC measurement does not decide anything. What works: `os.clock` around each operation, `Heartbeat` timestamps and a print for a second after the event, one line per frame "frame length | our operations | `Stats.PhysicsStepTimeMs`"; the tester sends a console screenshot (`/console`). `Stats.RenderCPUFrameTime` / `RenderGPUFrameTime` return 0 to scripts — rendering is visible only as "frame minus our work".
