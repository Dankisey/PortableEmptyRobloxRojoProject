---
paths: [".claude/docs/systems/framework.md", ".claude/docs/systems/code-map.md", ".claude/pitfalls/roblox-studio.md", ".claude/pitfalls/source-transfer.md", ".claude/hooks/**", ".claude/settings.json", "tools/**"]
---

# Studio, MCP, tools

- Development happens directly in Studio through MCP; there is no Rojo and no git. Before work — `list_roblox_studios`, pick the window by the PlaceId from the [root](../../CLAUDE.md#where-to-work) (other places are often open next to it), `get_studio_state`; code edits need Edit mode.
- Source in Studio outranks the reference and any text on disk. In Play `script_read`/`script_grep` see only the client DataModel; read `ServerStorage` through `execute_luau` with `datamodel_type = "Server"`, edit code in Edit.
- `execute_luau` is a separate VM: `require` of a project module fails or returns another instance; use `loadstring(module.Source)`; live singleton state — through the world, `GameValues`, attributes or a probe script. Details — [roblox-studio](../pitfalls/roblox-studio.md).
- A new `ModuleScript` is created with `multi_edit` (className + empty `old_string`), its text goes through `ScriptEditorService:UpdateSourceAsync`, verification through `script_read`: writing `.Source` into such a script never reaches Play ([pitfall](../pitfalls/roblox-studio.md#a-script-created-by-multi_edit-lives-as-a-document)). Folders — `execute_luau`. One file is edited with one tool.
- Code counts as working after a Play run with a clean console: `loadstring` and module tests check the text, not what runs.
- After a code step: place compilation, console, and on composition changes — types against cores and GUI against modules ([validation](../pitfalls/validation.md)).
- There are no Source copies on disk: rollback is the place version history. Before a mass deletion and at the end of meaningful work, ask the user to save the place (`File → Save to Roblox`, for a local file `File → Save`): an unsaved session loses everything.
- Hooks deliver MCP reminders ([reminders](../hooks/roblox-mcp-reminders.json)) and the animation and UI principles ([principles](../hooks/principles-reminders.json)). If a reminder did not arrive, read the section of your tool by hand. A new expensive MCP pitfall — a line in the JSON.
- Assets and third-party code are never moved into other games without permission; secrets only through `HttpService:GetSecret`, never in code.
