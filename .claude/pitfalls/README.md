# Pitfalls

Before the first edit in a session, read [MCP](roblox-studio.md), [validation](validation.md) and [transfer](source-transfer.md) in full. The rest — together with the area. Entry form: **symptom → cause → fix → check**; add to an existing topic.

Pitfalls do not load by themselves: the route to them goes from [rules](../rules/) and the root, and the most expensive MCP ones arrive by hook ([reminders](../hooks/roblox-mcp-reminders.json)).

| File | Area |
|---|---|
| [roblox-studio.md](roblox-studio.md) | `execute_luau`, `multi_edit`, `script_grep`, Studio windows, frames, synthetic input, PlayerModule, assets |
| [validation.md](validation.md) | place compilation, dangling references, types, GUI, console, trajectory in Play, probes, test values, phone performance |
| [source-transfer.md](source-transfer.md) | text between disk and Studio, checksums, transfer between places, map and Terrain |
| [runtime.md](runtime.md) | framework start, event order, respawn, network ownership, sound |
| [input-and-ui.md](input-and-ui.md) | world GUI, buttons, keys and prompts, layout, loading screen, camera |
| [world-and-physics.md](world-and-physics.md) | collisions and raycasts, ragdoll, debris, NPC and pathfinding |
| [models-and-animations.md](models-and-animations.md) | model geometry, imported meshes, tool in hand, animations and publishing |
| [saves-and-purchases.md](saves-and-purchases.md) | purchase handler, ProfileStore, sections and attributes |

Numbers in entries are measurements, not requirements. An example of a mechanic the template does not have does not make it a requirement.

**Check the result:** a tool response means "the call happened". You need fresh Source, world state or the console.
