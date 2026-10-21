# Как проверять сделанное

## Синтаксис всего плейса без Play

`loadstring` в Edit только компилирует. Норма плейса-шаблона: **93 скрипта, 0 ошибок** — сверка, а не константа: в игре число растёт с каждым модулем. Текст — из документа редактора: `.Source` правленых скриптов отстаёт, а у записанных `UpdateSourceAsync` пуст и компилируется в ложный ноль ([грабля](roblox-studio.md#source-пуст-или-отстаёт--проверки-читают-geteditorsource)). То же для сверки типов и контрольных сумм.

```lua
local ScriptEditorService = game:GetService("ScriptEditorService")
local roots = {
	game:GetService("ReplicatedStorage"), game:GetService("ServerStorage"),
	game:GetService("ServerScriptService"), game:GetService("StarterPlayer"),
	game:GetService("StarterGui"), game:GetService("ReplicatedFirst"),
	game:GetService("Workspace"),
}
local failures, total = {}, 0

for _, root in roots do
	for _, d in root:GetDescendants() do
		if not d:IsA("LuaSourceContainer") then continue end
		total += 1
		local chunk, err = loadstring(ScriptEditorService:GetEditorSource(d), d.Name)
		if not chunk then table.insert(failures, d:GetFullName() .. ": " .. tostring(err)) end
	end
end

return ("Скриптов: %d | Ошибок: %d\n%s"):format(total, #failures, table.concat(failures, "\n"))
```

Бэкапы `ServerStorage.RemovedBackup_*` компилируются, но не исполняются — вычитай их из нормы.

**Чего `loadstring` не ловит:**
- битые `require` — путь разрешается в рантайме; разбери `require(...)` текстом и разреши через `FindFirstChild`;
- висячие поля после удаления (ниже);
- продублированный `export type`;
- пропущенный `..`: `name "text"` — это вызов `name("text")`, падает только при исполнении. Ищи идентификатор, за которым сразу идёт строковый литерал.

## Висячие ссылки после удаления и переименования

Тем же обходом ищи имена, которые должны были исчезнуть. Подстрока даёт ложные срабатывания (`getDebrisFolder` содержит `DebrisFolder`) — ищи с границей слова: `source:gsub("[^%w_]Name", "")`. Полезно и обратное: собрать все `ConfigName%.(%w+)` и сверить с реальным набором полей.

Новый необязательный аргумент старой функции компилируется везде и молча даёт число для дефолтного режима. До правки сигнатуры найди всех вызывающих; данные, которых у клиента нет, считай на сервере и клади в `GameValues`.

## Типы против кода

Сверяет таблицы `Services` / `Controllers` / `Utils` с реальным составом ядер — после любого добавления или удаления модуля.

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

## GUI против модулей

`GuiTemplate:CreateChildren` требует одноимённый фрейм для каждого дочернего модуля и молча прерывает создание остальных. Проверяй обе стороны: каждому модулю `GuiController` — свой `ScreenGui`, каждому вложенному модулю — фрейм в нём.

## Консоль

`get_console_output` после каждого шага. `Module X was not loaded` и `Unitialized controllers` ловят почти все поломки фреймворка. На чистом старте консоль пустая — любая строка настоящая.

## Числа конфигов для расчёта

Грузи свежим Source, не `require`:

```lua
local Configs = game:GetService("ReplicatedStorage").Configs
local function load(name) return loadstring(Configs[name].Source, name)() end
local SavesConfig = load("SavesConfig")
```

Числа баланса в документации протухают на первой правке — перед расчётом замеряй кривую скриптом по текущему коду. Во взвешенных списках сверяй длину с исходной: вес, ушедший в ноль, молча выбрасывает запись через гвард `weight > 0`.

## Тестовые значения конфигов

Ускорять тайминги — правкой файла конфига **до** Play: загруженный модуль в рантайме не изменить. Возвращай боевые значения и сверяй возврат чтением `.Source`. В отчёте — «обычно → для теста».

## Проба-скрипт даёт живой синглтон

`LocalScript` в `PlayerGui` во время Play исполняется в той же VM, что `ClientCore`, а `Script` в `ServerScriptService` — в той же, что `ServerCore`: `require` возвращает играющий экземпляр с его реестрами. Ответ проба пишет в `StringValue`, вызывающий ждёт его и удаляет пробу.

Нужна там, где задержка MCP в секунды не различает «нажал» и «отпустил», и там, где число живёт только в синглтоне. Ответ клиентской пробы в `StringValue` до сервера не доходит (клиентская запись не реплицируется): читай его `execute_luau` с `datamodel_type = "Client"`. Условия: после респавна `LocalScript` в `PlayerGui` удаляется — ставь заново; проба проверяет, что предмет действительно в руках; длинные скобки — [на уровень глубже](roblox-studio.md#длинные-строки-и-пробы).

**Телепорт перед ударом опережает сервер**: клиентская проба ставила персонажа у объекта и била через 0,1 с — сервер ещё видел его у прошлого объекта в 25 студах, удар не засчитал, а клиент сыграл эффект. Физикой персонажа владеет клиент, а прыжок на 16 студов сервер ещё ~0,2 с показывает на полпути (интерполяция). Между телепортом и ударом — не меньше 0,3 с; сценарий «подошёл к объекту» проверяй ходьбой `Humanoid:MoveTo`, а не телепортом.

## Численные метрики врут

Рэгдолл «включался» по всем метрикам, а рутпарт летел отдельно от тела. Согласованность чисел между собой ничего не доказывает, если все меряются от одной точки отсчёта (луч от собственного пивота сдвигал все замеры на одну величину) — проверяй саму точку отсчёта. Физику, анимации, тайминги, читаемость VFX и UI отдавай человеку с чеклистом и сниппетом.

Проверка сеткой по карте, а не парой точек: на реальной карте ветка «луч вернул `nil`» срабатывает постоянно, а на `Baseplate` — никогда.
