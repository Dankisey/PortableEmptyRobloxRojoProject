# Код-стайл

Грузится в каждую сессию: любая правка Luau. Язык комментариев — русский, код и имена — английские.

## Оформление

- **Табы**, не пробелы. В `old_string`/`new_string` у `multi_edit` табы пишутся как `\t` ([почему](../pitfalls/roblox-studio.md)).
- **Точка с запятой** в конфигах и табличных литералах:
  ```lua
  local entry = {
  	Id = self:NextId();
  	Position = position;
  	Health = health;
  }
  ```
- **Шапка модуля:** `game:GetService` блоком → ассеты и ремоуты → `require`. Внутри `require`: шаблоны (`ServiceTemplate`, `ControllerTemplate`) → утилиты → конфиги → вложенные модули.
  ```lua
  local ReplicatedStorage = game:GetService("ReplicatedStorage")
  local Players = game:GetService("Players")

  local Remotes = ReplicatedStorage.Remotes.Ragdoll
  local StateChanged = Remotes.StateChanged

  local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
  local CharacterUtils = require(ReplicatedStorage.Modules.Utils.CharacterUtils)
  local CollisionConfig = require(ReplicatedStorage.Configs.CollisionConfig)
  ```
- **Гварды — одной строкой:** `if not thing then return end`.
- Пустая строка между логическими блоками функции; двух пустых строк подряд нет.
- Разделители секций в длинных модулях: `--[[========================= название =========================]]`.

## Именование

| Что | Как | Пример |
|---|---|---|
| Приватное поле | `_camelCase` | `self._activeEntries` |
| Публичное поле | `PascalCase` | `self.IsRagdolled` |
| Метод | `PascalCase` | `RagdollService:GrantImmunity()` |
| Локальная функция | `camelCase` | `local function getWorldFolder()` |
| Локальная константа модуля | `PascalCase` | `local CameraFollowSpeed = 9` |
| Модуль | `PascalCase` | `ToolsController` |

**Подчёркивание — только приватное.** Поле, которое читают снаружи, публичное и без подчёркивания: поэтому `RagdollController.IsRagdolled` — поле, а не метод.

## Функции

- Хелперы принимают `self` первым аргументом: `local function createEntry(self, zone, position)`. Не используется `self` — параметра нет.
- «Не получилось» — это `nil` или `false`, а не `error`.
- Публичный метод с `task.wait` или запросом к `DataStore` внутри помечается `-- блокирует вызывающий поток`.

## Комментарии

**По умолчанию комментариев нет. Код объясняет себя именем.** Тянет описать, что делает функция, — переименуй функцию.

Комментарий остаётся, только если **без него следующий читатель сломает рабочий код**: порядок рэгдолла и импульса, запрет йилда в обработчике покупки. Форма — **одна строка про ПОЧЕМУ**:

```lua
--[[ без гварда по блокировке: она могла включиться посреди замаха, и съеденное отпускание оставит игрока в замахе ]]
function ToolsController:ReleaseEquippedTool()
```

Под нож: шапки модулей, пересказ кода, докблоки-эссе, описания удалённого, закомментированный код. Крупные решения — в [решениях](../decisions.md), грабли — в [pitfalls](../pitfalls/README.md); в коде на них хватает намёка.

Остаются ещё: разделители секций, `-- блокирует вызывающий поток`, контракт возврата, не видный из имени (`-- false = сессии нет`), единицы у чисел конфига (`-- секунд между тиками`).

Код каркаса местами написан по старому правилу (многострочные `--[[ ]]`). Чужие комментарии ради стиля не переписывай; файл, который правишь по существу, приводи к правилу.

## Типы

Типы — `ServerStorage.ServerTypes`, `Modules.ClientTypes`, `Modules.SharedTypes`, `Modules.UtilsTypes`.

**Добавил сервис, контроллер или утилиту — обязан дополнить:** экспорт типа модуля и таблицу `Services` / `Controllers` / `Utils`. Иначе типы протухают молча. Сверка — скрипт «типы против кода» из [validation](../pitfalls/validation.md#типы-против-кода).

Аннотации параметров — везде, где тип не очевиден: `function Enemy:Attack(player: Player, targetRoot: BasePart)`.

## Конфиги

Каждое число баланса и контента — в конфиге, с одним источником: цена предмета живёт только в конфиге предметов. Новый предмет, враг или уровень добавляется записью в конфиг без правки логики. Единицы у чисел подписываются.

## Границы модулей

Новый модуль — только если **снимает дубляж из двух и более мест** или **отрезает самостоятельную ответственность от файла на 300+ строк**. Ответственность, читающая внутренности родителя, — вложенный модуль с фасадом API родителя ([решение](../decisions/framework.md#новый-модуль--только-по-делу)).
