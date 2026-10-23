# Source transfer

**`execute_luau` neither reads nor writes files, `HttpService` is closed from it (`lacking capability Network`), and `http_get` reaches only the Roblox documentation.** A localhost transport works for a real `Script` or a plugin, but not through MCP. There are no Source copies on disk ([decision](../decisions/framework.md#no-rojo-rollback-through-version-history)); transfer is needed for builders, checks and moving code between places.

## From Studio to disk and back

Without MCP the whole Source comes from a saved place: [`tools/rbxl-export`](../../tools/rbxl-export/export_rbxl.py) reads `.rbxl` (zstd and LZ4) and lays scripts out for Rojo with a byte check. Unsaved Studio edits do not reach the file — `File → Save` first.

Text goes twice: the file is written to disk with the `Write` tool, into Studio — through `execute_luau` with a long string `[==[ ... ]==]` (tabs and non-ASCII characters in the parameter pass unharmed).

- Lua drops the newline right after `[==[` — file and Source match byte for byte if the file starts without an empty line and ends with one newline.
- Make a point edit with a function using `source:find(old, 1, true)` and a check that there is one occurrence; make the same edit in the file with the `Edit` tool.
- Slicing `.Source` by bytes breaks multibyte characters and hangs the response; cut by lines.
- Heredoc in Bash fails on non-ASCII (`unexpected EOF`) — write such files with `Write`.
- The text for a checksum is `ScriptEditorService:GetEditorSource`: `.Source` of a script open in the editor may lag ([pitfall](roblox-studio.md#source-is-empty-or-stale--checks-read-geteditorsource)).

## Checksum

Length and djb2 must match for every file; length alone is not enough — with broken encoding it may still match. In Studio:

```lua
local hash = 5381
for i = 1, #source do
	hash = (hash * 33 + source:byte(i)) % 4294967296
end
return #source, hash
```

On disk (run Python from a short directory: Windows refuses to start `python` from a session directory with a long path):

```bash
cd /c && python -I -c "import glob,os
for f in sorted(glob.glob('<folder>/*.lua')):
    h=5381
    for b in open(f,'rb').read(): h=(h*33+b)%4294967296
    print(os.path.basename(f)[:-4], os.path.getsize(f), h)"
```

A 1 byte difference is the trailing newline.

## A copy inside the place

An old script goes into `ServerStorage` with `Disabled = true`: it does not run, the bytes are exact. Subtract such copies from the compilation norm.

## Between places of one universe

A shared `DataStore`: `SetAsync` in the source, `GetAsync` in the target, `RemoveAsync` right after. `GetAsync`/`RemoveAsync` from `execute_luau` in Edit work, no `Network` capability needed; `SetAsync` needs **Studio Access to API Services** — wrap it in `pcall`. Verify with a checksum.

## Between different universes

The `DataStore` is not shared. Collect a folder of copies in the source, ask the human to `Copy → Paste Into` in the target window and lay it out with a script. Team Create does not sync different places.

## Instances and the map

- `Sound` templates and layout are instances; a script cannot carry them between universes — copy them by hand or recreate them by properties.
- A map inserted from another window does not shift as a whole: top level objects move by a delta, folder contents stay. Set exact `CFrame`s from the source; compare sizes object by object.
- Terrain is not copied by the clipboard. First look at what is there: often it is one water rectangle — then `Terrain:FillBlock` plus water properties. `ReadVoxels` — at most 4 194 304 voxels per call; `Terrain.MaxExtents` returns the constant `±32000`.
- `RBX_*` attributes on Toolbox models cannot even be cleared: `CoreScript permission required` kills the whole script. Skip the prefix or `pcall` each clear.
