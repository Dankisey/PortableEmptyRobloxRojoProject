---
paths: [".claude/docs/systems/remotes-and-values.md", ".claude/decisions/input-and-ui.md", ".claude/pitfalls/input-and-ui.md"]
---

# Ввод, тулы, интерфейс, камера

- **Всё в руках — `Tool`** с атрибутом `ToolsConfig.ToolTypeAttribute`. `ManualActivationOnly = true`, `Tool.Activated` не слушать. Использование — только `ToolsController:UseEquippedTool()`/`ReleaseEquippedTool()`; действие регистрирует владелец механики через `RegisterAction`.
- Экранную кнопку использования заводит игра по контракту `ToolsConfig.Actions` + `Modules.UI.KeyBadge` (`KeyBadge.Bind` — подпись по `UserInputService.PreferredInput`, не по устройству). Клавиша и подпись — из одной секции `ControlsConfig`; новая механика заводит свою секцию. Тап в любую точку экрана — флаг `ControlsConfig.Use.TapAnywhere`, выключен.
- Кнопки — только через `ButtonsInteractionsConnector` (`InputBegan` с фильтром ввода), не `Activated`: тот приходит по отпусканию. Подключается **каждая** видимая кнопка, включая будущие без действия (пустой колбэк): анимация нажатия с отскоком и звук клика есть только у подключённых. Кнопка удержания — `ConnectHoldButton`: сжатие держится, пока зажата, отскок и возврат — только на отпускании. Коннектор сам выключает `AutoButtonColor` — затемнение не нужно.
- Курсор виден в третьем лице; `InputController` прячет его только при `CameraMode = LockFirstPerson`.
- У отпускания нет гварда по `gameProcessed`. Касание отпускает тул только через кнопку, которая ловит конец своего касания (`ConnectHoldButton`): любое отпускание касания отпускало бы тул и от пальца со стика. Ввод кастомных промптов гвардится `GetFocusedTextBox()`, а не `gameProcessed`.
- Пробел — прыжок: перехват через `ContextActionService` на `High` и снятие бинда на **каждом** выходе из состояния, включая рэгдолл.
- GUI-разметкой владеет Studio: статические `Position`/`Size`/`AnchorPoint` кодом не перезаписывать, клоны наследуют шаблон. `Position` и `Size` — только в скейле, оффсеты нулевые; квадрат — скейлом и `UIAspectRatioConstraint`. Новый `ScreenGui` — `ResetOnSpawn = false`. Модуль `GuiController` без одноимённого фрейма молча обрывает создание остальных.
- **Интерфейс не топит ввод мыши в центре экрана.** `BillboardGui.Active` — только на тач-устройствах; полноэкранное гасится `Visible = false`.
- Камера: режим — свойство `StarterPlayer.CameraMode`. `LockFirstPerson` требует `CameraConfig.FirstPersonVisibility`; свой бинд прозрачности — на `Camera.Value + 1`.
- Мобилки — основная платформа: кнопки не меньше пальца, ничего важного под стиком и кнопкой прыжка, проверка в портрете и ландшафте. Обводки `UIStroke` — смотри режим `StrokeSizingMode`, а не толщину.

Перед правкой прочитай [remotes-and-values](../docs/systems/remotes-and-values.md), [решения](../decisions/input-and-ui.md) и [грабли](../pitfalls/input-and-ui.md).
