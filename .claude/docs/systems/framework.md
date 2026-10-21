# Фреймворк

Свой DI. `ServerScriptService.ServerBootstrap` → `ServerCore:Start()`, `StarterPlayer.StarterPlayerScripts.ClientBootstrap` → `ClientCore:Start()`. Почему свой, а не Knit/Rojo — [решения](../../decisions/framework.md).

## Порядок `Start()`

1. `LoadModules(Modules.Utils)` → `utils`, `LoadModules(Configs)` → `configs`.
2. `require` прямых детей ядра → `module.new()` → `services` / `controllers`.
3. `InjectServices` / `InjectControllers`, `InjectUtils`, `InjectConfigs`.
4. `Initialize()` (на клиенте `Initialize(player)`) у всех через `task.spawn` + `pcall`.
5. На клиенте — ждёт атрибут игрока `IsLoaded` и зовёт `AfterPlayerLoaded(player)`.

Порядок `Initialize` между модулями не задан: сервис не имеет права зависеть от того, кто поднялся раньше.

## Сервисы и контроллеры

**Новый сервис = новый ModuleScript в `ServerStorage.ServerCore`**, регистрировать нигде не надо; контроллер — в `ReplicatedStorage.ClientCore`. Фреймворк берёт только прямых детей: вложенные модули (`FooService.Bar`) он не трогает.

Сервисы и контроллеры — синглтоны, `self` это сама таблица модуля:

```lua
function MyService.new()
	local self = setmetatable(MyService, {__index = ServiceTemplate})
	self._field = {}
	return self
end
```

Следствие: **два модуля с одинаковым именем в ядре молча перетирают друг друга.**

Инфраструктура, которая сервисом быть не должна, лежит **рядом** с `ServiceTemplate`, а не в `ServerCore`: `ProfileStore`, `SpawnerTemplate`, `ServerTypes`.

## GUI

Каждый ребёнок `GuiController` — модуль одноимённого `ScreenGui` в `StarterGui`. `GuiTemplate:CreateChildren` требует одноимённый фрейм для каждого дочернего модуля, **иначе молча прерывает создание остальных**. Обратное безопасно: фрейм без модуля — норма для фреймов без поведения. Кнопки же всегда подключаются модулем через `ButtonsInteractionsConnector`, даже без действия, — иначе у них нет анимации нажатия. Новым `ScreenGui` — `ResetOnSpawn = false`.

## `utils.Event`

`Event.new()`, `:Invoke(...)`, `:Subscribe(key, callback)`, `:Unsubscribe(key)`, `:Destroy()`; `key` уникальный.

## `SpawnerTemplate`

Общая машина популяции: реестр, лимит, таймеры, цикл под `pcall`. Подключается к сервису, а не живёт сам:

```lua
SpawnerTemplate.InitSpawner(self, {Name, Config, LimitKey, TrySpawn, OnRemove, ShouldSpawn, OnUpdate})
```

Методы копируются на сервис напрямую: свой `__index` сервис уже занял под `ServiceTemplate`.
