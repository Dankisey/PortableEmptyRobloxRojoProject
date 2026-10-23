# Framework

Own DI. `ServerScriptService.ServerBootstrap` → `ServerCore:Start()`, `StarterPlayer.StarterPlayerScripts.ClientBootstrap` → `ClientCore:Start()`. Why own and not Knit or Rojo — [decisions](../../decisions/framework.md).

## `Start()` order

1. `LoadModules(Modules.Utils)` → `utils`, `LoadModules(Configs)` → `configs`.
2. `require` of the direct core children → `module.new()` → `services` / `controllers`.
3. `InjectServices` / `InjectControllers`, `InjectUtils`, `InjectConfigs`.
4. `Initialize()` (on the client `Initialize(player)`) for everyone through `task.spawn` + `pcall`.
5. On the client — waits for the `IsLoaded` player attribute and calls `AfterPlayerLoaded(player)`.

The `Initialize` order between modules is not defined: a service may not depend on who started first.

## Services and controllers

**A new service = a new ModuleScript in `ServerStorage.ServerCore`**, nothing to register; a controller goes into `ReplicatedStorage.ClientCore`. The framework takes only direct children: nested modules (`FooService.Bar`) are left alone.

Services and controllers are singletons, `self` is the module table itself:

```lua
function MyService.new()
	local self = setmetatable(MyService, {__index = ServiceTemplate})

	self._field = {}

	return self
end
```

Consequence: **two modules with the same name in a core silently overwrite each other.**

Infrastructure that must not be a service lives **next to** `ServiceTemplate`, not in `ServerCore`: `ProfileStore`, `SpawnerTemplate`, `ServerTypes`, `AdminGui`.

## GUI

Each `GuiController` child is the module of the `ScreenGui` with the same name in `StarterGui`. `GuiTemplate:CreateChildren` needs a frame with the same name for every child module, **otherwise it silently stops creating the rest**. The reverse is safe: a frame without a module is normal for frames without behavior. Buttons are always connected by a module through `ButtonsInteractionsConnector`, even without an action — otherwise they have no press animation. New `ScreenGui` — `ResetOnSpawn = false`. Layout rules — [ui](../../rules/ui.md).

## `utils.Event`

`Event.new()`, `:Invoke(...)`, `:Subscribe(key, callback)`, `:Unsubscribe(key)`, `:Destroy()`; `key` is unique.

## `SpawnerTemplate`

The shared population machine: registry, limit, timers, a loop under `pcall`. It attaches to a service and does not live on its own:

```lua
SpawnerTemplate.InitSpawner(self, {Name, Config, LimitKey, TrySpawn, OnRemove, ShouldSpawn, OnUpdate})
```

Methods are copied onto the service directly: the service `__index` is already taken by `ServiceTemplate`.
