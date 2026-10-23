# Roblox project template

A Roblox project framework. The code lives in the template place: locally `Empty.rbxl` next to this file, in the cloud — `Empty Project` (`86416691264868`). Here is the agent documentation in the `.claude/` layout, ready to copy into a new project.

| What | Where it goes in a new project |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | project root; fill in the `<angle brackets>` |
| [`.claude/`](.claude/README.md) | as a whole: rules, decisions, pitfalls, systems reference, principles, MCP and principles hooks, `settings.json` |
| [`tools/documentation/`](tools/documentation/check-agent-docs.ps1) | documentation check |
| `backup/` | not copied: the template's own archive |

## What the template has

- Own DI: `ServerCore` / `ClientCore`, a service is a ModuleScript in the core ([framework](.claude/docs/systems/framework.md)).
- Saves: ProfileStore, every field is a section of its owning service, the client gets player attributes ([saves](.claude/docs/systems/saves.md)).
- Monetization: developer product and game pass receipts, handlers without yields; free developer purchases behind a server switch, off by default.
- Admin panel for `DevelopersConfig` only: add cash, wipe the save, switch free developer purchases ([code map](.claude/docs/systems/code-map.md#admin-panel-serverstorageadmingui)).
- Ragdoll on the constructive R15: the server holds the state, the client does the physics.
- Tools without `Tool.Activated`, tap anywhere behind a flag, buttons on `InputBegan` with bounce and hold, key labels by `PreferredInput`, landscape only.
- `WorldQuery`, `CollisionConfig`, `SpawnerTemplate`, utilities ([code map](.claude/docs/systems/code-map.md)).
- Rules for code style, interface and animation, with the [animation](.claude/docs/animation-principles.md) and [UI](.claude/docs/ui-principles.md) principles.

No script knows a single game name. What is knowingly unfinished — [debts](.claude/docs/debts.md).

## Repository

[GitHub](https://github.com/Dankisey/PortableEmptyRobloxRojoProject): documentation, `Empty.rbxl` and `src/` — a snapshot of the place scripts in a Rojo layout for reading and diffs. The truth is in the place: `src/` has only scripts and folders, GUI layout, remotes and assets exist only in `Empty.rbxl`, so `rojo serve`/`rojo build` from `src/` does not build a working place.

Updating the snapshot (Python 3.14+, `rojo`), from the repository clone root after `File → Save` of the place:

    rm -rf src
    python -I tools/rbxl-export/export_rbxl.py Empty.rbxl src
    rojo build default.project.json -o build.rbxl
    python -I tools/rbxl-export/verify_build.py build.rbxl Empty.rbxl
    rojo sourcemap default.project.json -o sourcemap.json

`export_rbxl.py` compares the written files byte by byte with the place; `verify_build.py` checks that a build from `src/` gives the same scripts with the same class and text (exit code 1 on a mismatch). `build.rbxl` is not committed.

## Starting a new project

1. Copy the template place (`File → Save As` or a copy in Creator Hub) and **publish** it: saves and purchases need a published place.
2. Copy `CLAUDE.md`, `.claude/` and `tools/` into the new project root. Fill in `CLAUDE.md`, the [concept](.claude/docs/concept.md) and the [plan](.claude/docs/roadmap-to-prototype.md).
3. Check `SavesConfig.DataStoreName` and `GetProfileKey`: a second place of the same universe must match them, and `ServerStorage.ProfileStore` must be the same.
4. `SavesConfig.KickOnLoadFail`: `true` for a gameplay place, `false` for a lobby or menu.
5. Fill `DevelopersConfig` with the UserIds of developers and testers (admin panel and free developer purchases).
6. The first own service is a new ModuleScript in `ServerCore` plus a type export and an entry in `ServerTypes.Services`.
7. Run the documentation check:

       powershell -NoProfile -ExecutionPolicy Bypass -File tools/documentation/check-agent-docs.ps1

## Before release

- `SavesConfig.DataStoreName` = `PlayersSavesData`, `KickOnLoadFail` = `true`; with a second place — a shared key and the same `ProfileStore` in both.
- On release day the "save fields without migrations" rule is lifted ([saves-and-monetization](.claude/rules/saves-and-monetization.md)); every later schema change needs a migration.
- `DeveloperPurchasesEnabled` on `Monetization` stays `false` in the place.
- The game icon, name and the empty-on-purpose stubs ([code map](.claude/docs/systems/code-map.md#empty-on-purpose)) are filled.
