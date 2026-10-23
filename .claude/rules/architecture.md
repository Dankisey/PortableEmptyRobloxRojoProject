---
paths: [".claude/docs/systems/README.md", ".claude/docs/systems/framework.md", ".claude/docs/systems/code-map.md", ".claude/docs/systems/public-api.md", ".claude/docs/systems/remotes-and-values.md", ".claude/decisions/framework.md"]
---

# Architecture and DI

- **The server is authoritative.** The client sends minimal facts (intent, target Id), the server checks distance, cooldown, time, balance and that the object belongs to the player. The client draws cosmetics. Exception — character physics ([character-physics](character-physics.md)).
- **The client plays cosmetics, the server places objects.** If each client has its own objects (a personal track, an instanced level), the server keeps their state per player in a table and checks the sent Ids itself; such a choice is recorded as a decision.
- **Everything that plays permanently starts on the client.** A server `Animator` replicates the command, not the track state: a late player never sees it. Scene state is an attribute on the model.
- **DI loads only direct children of a core.** A new service or controller is a ModuleScript in the core; equal names overwrite each other; a nested module never becomes a service. Order and contracts — [framework](../docs/systems/framework.md).
- **One state, one owner.** Others send a request or subscribe to an `Event`. Identity — a GUID (`utils.GenerateGuid`), the registry lives on the server.
- A remote carries minimal facts; every new remote checks the sender and the state on the server before any action.
- The order of handlers of one event is not defined: a flag cleared by another handler of the same event cannot be a guard.
- UI subscriptions are made once in `Initialize`; a remote handler changes only state and `Visible`.
- No `WaitForChild` without a timeout at module level: an endless yield in `require` kills the whole client. World folders — `WorldQuery.GetWorldFolder`.
- A new service or controller: type export, `Services`/`Controllers`, a line in the [code map](../docs/systems/code-map.md), the "types against core" check. Infrastructure and templates live next to `ServiceTemplate`, not in the core.
- **Developer tools only reach developers.** The admin panel lives in `ServerStorage.AdminGui` and `AdminService` clones it into `PlayerGui` for `DevelopersConfig` only; every command is checked on the server. A new command is an entry in `AdminConfig.Commands`, a button with the same name in the panel layout and a handler in `AdminService` ([decision](../decisions/framework.md#admin-panel-outside-di)).
- Most players are on phones: instance counts, remote rates and VFX are limited by config; UI is checked on a phone.

Before an edit read [framework](../docs/systems/framework.md), the [code map](../docs/systems/code-map.md), the [API](../docs/systems/public-api.md), [remotes](../docs/systems/remotes-and-values.md) and [runtime](../pitfalls/runtime.md).
