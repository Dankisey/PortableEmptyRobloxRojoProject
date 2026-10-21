# Ремоуты, значения, управление

## Ремоуты (`ReplicatedStorage.Remotes`)

`ClientInitialized`, `KickRequested`, `SoundRequested`, `UI` (`PopupRequested`, `ServerMessageSent`), `Monetization` (`DevProductRequested`, `GamepassRequested`), `Ragdoll.StateChanged`.

`Ragdoll.StateChanged` идёт `FireAllClients(target, enabled, impulse)`: позу собирает каждый клиент, импульс применяет только владелец.

Каждый новый ремоут: сервер проверяет аргументы (тип, диапазон, дистанцию, кулдаун, принадлежность объекта игроку) до любого действия.

## `GameValues`

Папка пустая — сюда кладутся `Value`-инстансы состояния рана. Они реплицируются даром, поэтому ремоут для показа счётчика не нужен: модуль подписывается на `Changed` в `AfterPlayerLoaded`. Не прочитался сейв — на счётчике остаётся `...`, а не `0`.

## Атрибуты игрока

Ставит только сервер; клиентская запись остаётся локальной. Атрибуты игрока видны всем клиентам.

| Атрибут | Кто ставит | Что значит |
|---|---|---|
| `IsLoaded` | `SavesLoader` | загрузка сейва **закончилась** (не обязательно удачно); клиент ждёт его перед `AfterPlayerLoaded` |
| `JoinTime`, `OwnsPremium`, `CanPurchaseRandomItems`, атрибуты геймпассов | `SavesLoader` | данные входа |
| `Cash` | `SoftCurrencyService` | баланс; имя атрибута = имя валюты |

Сохраняемое значение публикует владелец раздела ([saves](saves.md#разделы)); атрибута нет — сейв не загружен, на счётчике `...`.

## Тулы и кнопка использования

**Всё, что игрок держит в руках, — `Tool`.** Тип — строка в атрибуте `ToolsConfig.ToolTypeAttribute` (`"ToolType"`) на самом туле; ставит его тот, кто тул создаёт.

| Кто | Что делает |
|---|---|
| Сервер | создаёт тул, кладёт в рюкзак, ставит атрибут типа |
| `ToolsConfig.Priority` | какой тул важнее, если их несколько |
| `ToolsController` | берёт в руки самый приоритетный из рук и рюкзака |
| `ToolsController:RegisterAction` | что делает использование конкретного типа |
| `ToolsConfig.Actions` | подпись и иконка экранной кнопки |
| `Modules.UI.KeyBadge` | подпись клавиши в углу этой кнопки |

Тулам ставится `ManualActivationOnly = true`, `Tool.Activated` не слушает никто. Использование — только `ToolsController:UseEquippedTool()`: клавиши `ControlsConfig.Use`, экранная кнопка игры и, если включён `TapAnywhere`, короткий тап вне интерфейса ([решение](../../decisions/input-and-ui.md#тап-в-любую-точку-экрана--под-флагом-выключен)). Второй вход — `ReleaseEquippedTool()`: по `InputEnded` мыши и геймпада и при потере фокуса окна; касание не отпускает — кнопка удержания ловит конец своего касания сама (`ConnectHoldButton`).

**Экранной кнопки в каркасе нет.** Заводит её игра: подключает `ConnectHoldButton(button, UseEquippedTool, ReleaseEquippedTool)`, показывает по записи `ToolsConfig.Actions` для типа тула в руках, подпись клавиши — `KeyBadge.Bind`.

## Управление (`ControlsConfig`)

`ControlsConfig.Use`: `MouseButton1`, `ButtonR2`, `TapAnywhere = false` (`TapMaxMove` 10 px, `TapMaxDuration` .25 с); подписи `LMB` / `RT` / на мобилке пусто (бейджа нет). Клавиша и подпись лежат в одной секции; новая механика заводит свою секцию. Бейдж выбирает подпись по `UserInputService.PreferredInput`: текст на ПК, глиф через `GetImageForKeyCode` на геймпаде, нет бейджа на касании.

## Кнопки интерфейса

Все кнопки идут через `ButtonsInteractionsConnector`: `GuiObject.InputBegan` с фильтром по типу ввода, а не `GuiButton.Activated`. Колбэк на каждое нажатие, анимация отдельно (сжатие `.9`, отскок `1.06`, покой `.97`), дубли одного тапа режет `DuplicateInputWindow`, `AutoButtonColor` выключается при подключении.

## Камера

Режим — **свойство** `StarterPlayer.CameraMode` (в шаблоне третье лицо). Курсор скрыт только при `LockFirstPerson`. Включаешь `LockFirstPerson` — включи и `CameraConfig.FirstPersonVisibility`. Подробности — [input-and-ui](../../rules/input-and-ui.md).
