# Framework and DI

## Own DI, not Knit

Short enough to read in full in minutes, no dependencies and no build step. The known costs:

- **`Initialize` order is not defined** — services do not depend on who started first;
- **names are globally unique** — two modules with one name in a core silently overwrite each other;
- **`self` is the module table itself** — every service is a singleton by construction.

## No Rojo, rollback through version history

Edits happen directly in Studio; sources on disk would drift away from the place. There are no Source copies on disk either: they go stale and cost a step on every change. Rollback is the place version history, so the place is saved before mass deletions and at the end of meaningful work. Cost — no code history outside Roblox; a local unpublished file is protected only by `File → Save` and a copy of the `.rbxl`. Revision — when Rojo appears.

## `SpawnerTemplate` next to `ServiceTemplate`

Everything in `ServerCore` becomes a service, and the population template is attached to a service through `InitSpawner`. Methods are copied directly, not through a second metatable: the service `__index` is already taken by `ServiceTemplate`. `ProfileStore` lives next to it for the same reason.

## Gizmos outside Utils

`LoadModules(Modules.Utils)` loads the whole folder, and `Gizmos` would show a false `Module Gizmos was not loaded` on the server, hiding real failures. It is required lazily in `InputController` under `TestingConfig.IsTesting`; the console on a clean start is empty, so every line in it is real.

## Counters read instances, not a remote

Player attributes replicate for free. A remote for showing a value is an extra network round trip and a second source of truth. If the save is not read, the counter shows `...`, not `0`: a zero reads as lost progress.

## A new module only when it pays

A module appears when it removes duplication from two or more places or cuts an independent responsibility out of a file of 300+ lines. Modules of 20–40 lines for neatness cost more than they give. A responsibility that reads the parent's internals goes into a nested module behind the parent's API.

## Admin panel outside DI

`ServerStorage.AdminGui` (layout, `LocalScript` `AdminPanel`, `ModuleScript` `AdminConfig`, `RemoteEvent` `CommandRequested`) is cloned by `AdminService` into `PlayerGui` of players from `DevelopersConfig` after `IsClientInitialized`, in the live game and in Studio. Commands act only on the sender. The server checks on every call that the sender owns the clone and is a developer, the cooldown, the command name and the number. Default commands: `AddCash`, `Reset` (wipe, second press), `FreePurchases` (switches free developer purchases, [decision](saves.md#free-developer-purchases-are-a-server-switch)).

Why: maximum protection — a regular player never downloads the layout, the code or the command names; a controller in `ClientCore` and a config in `Configs` would replicate to everyone. A remote inside a `PlayerGui` clone is seen only by its owner. The protection itself is the server check, not secrecy.

Cost: a second path for client code outside DI — a `LocalScript` without `Initialize` and injections; `ButtonsInteractionsConnector` is taken as the live singleton through `require`, so delivery waits for `IsClientInitialized`. `AdminConfig` lives outside `Configs` and is not in `_configs`. Revision — when there is more than one such panel: a shared mechanism for server-delivered GUI.
