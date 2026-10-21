# Карта кода

В плейсе шаблона 93 скрипта. Добавил или удалил сервис/контроллер — обнови таблицу и типы ([code-style](../../rules/code-style.md#типы)).

## Дерево плейса

```
ServerScriptService.ServerBootstrap        → ServerCore:Start()
ServerStorage
  ServiceTemplate, ServerTypes, SpawnerTemplate, ProfileStore
  ServerCore/                              7 сервисов, ниже
ReplicatedStorage
  ClientCore/                              14 контроллеров, ниже
  Modules/                                 ClientTypes, SharedTypes, UtilsTypes, ControllerTemplate,
                                           Gizmos, UI/ (5), Utils/ (21)
  Configs/                                 18 конфигов
  Remotes/, GameValues/ (пусто)
  Assets/                                  GuideBeam, UI/ (Popups — пример Cash)
StarterPlayer.StarterPlayerScripts.ClientBootstrap → ClientCore:Start()
StarterGui                                 MainGui, FadingGui, MessagesGui, PopupsGui, TooltipsGui,
                                           ConfirmationPromptGui, CustomPrompts (все ResetOnSpawn = false)
SoundService.SFX                           ClickSound, HoverSound (пустые id — молчат)
Workspace                                  Baseplate, SpawnLocation, Debris
```

`StarterPlayer.CameraMode` = `Classic` (третье лицо), `Workspace.StreamingEnabled` = `true`.

## Сервер (`ServerStorage.ServerCore`)

| Модуль | Ответственность |
|---|---|
| `SavesLoader` | сессия ProfileStore, раздача разделов владельцам, атрибуты входа; свой раздел `Stats`; команда чата `/wipe` для `DevelopersConfig` |
| `Monetization` | маршрутизация чеков дев-продуктов и геймпассов, реестр обработчиков; бесплатные dev-покупки для `DevelopersConfig` |
| `RewardService` | выдача награды по описанию `{FunctionName, Data}`; сейчас умеет `Cash` |
| `SoftCurrencyService` | раздел `Currencies`, атрибут `Cash`; начисление и списание мягкой валюты |
| `ServerMessagesSender` | серверные сообщения в интерфейс игрока |
| `Analytics` | обёртка над `AnalyticsService`; баланс берёт у `SoftCurrencyService` |
| `RagdollService` | состояние рэгдолла, иммунитет, таймер подъёма, коллизионные группы |

`ServerStorage.ProfileStore` — библиотека MadStudio (не устаревший `ProfileService`). Обновляется целиком, файл не правится.

## Клиент (`ReplicatedStorage.ClientCore`)

`GuiController` (+ `MainGui` с `CashLabel` — атрибут `Cash`, `FadingGui`, `MessagesGui`, `PopupsGui`, `TooltipsGui`, `ConfirmationPromptGui`), `ButtonsInteractionsConnector` (`ConnectButton` — нажатие с отскоком, `ConnectHoldButton` — удержание), `ToolsController` (тап в любую точку — `ControlsConfig.Use.TapAnywhere`, выключен), `RagdollController` (+ `RagdollCamera`), `CameraController`, `CharacterMovementController`, `InputController` (курсор скрыт только в `LockFirstPerson`), `SoundPlayer`, `BackgroundMusicController`, `CustomPromptsController` (+ `CustomPromptTemplate`, `GuiOpenPrompt`, `DevProductPrompt`), `TooltipsController`, `ClientMessagesSender`, `GuideBeamController`, `ChatController`.

## Модули UI (`ReplicatedStorage.Modules.UI`)

`GuiTemplate`, `AnimatedGuiTemplate`, `Widget`, `InfoPin`, `KeyBadge` (подпись клавиши по `PreferredInput`).

## Утилиты (`ReplicatedStorage.Modules.Utils`)

```lua
CharacterUtils.GetAlive(player)      -- -> (Model?, BasePart?, Humanoid?)
CharacterUtils.GetAliveRoot(player)  -- -> BasePart?
CharacterUtils.GetTorso(character)   -- UpperTorso -> Torso -> HumanoidRootPart

FlatVector.Mask                          -- Vector3.new(1, 0, 1)
FlatVector.Distance(a, b)                -- плоское расстояние
FlatVector.Flatten(vector, fallback?)
FlatVector.Direction(from, to, fallback?)

-- единственный правильный способ рейкастить воду и землю
WorldQuery.RaycastWater(origin, direction)
WorldQuery.IsOverWater(position, height?)
WorldQuery.RaycastGround(origin, direction, ignore?)  -- сам исключает тег воды
WorldQuery.GetWorldFolder(name)                       -- найдёт или создаст
WorldQuery.CollectTaggedAndFoldered(tag, folderName)

TweenPivot(model, cframe, duration, easingStyle?, easingDirection?) -- -> Tween
LoadModules(folder)                      -- -> {[name] = module}, с warn на упавших
FormatNumber(value)                      -- 999, 1.38K, 13.8K, 138K, -2.5K: три значащие цифры, отбрасывание
```

Прочие: `Event`, `Timer`, `GenerateGuid`, `GetChancedRewardIndex`, `Lerp`, `EvaluateGradient`, `FormatTime`, `DeepCopy`, `GetKeys`, `CubicBezier`, `TimeUtils`, `TranslateRange`, `MakeNumberDividers`, `GetPlayerProfileIcon`, `TryGetProductInfo`.

`Modules.Gizmos` лежит **вне** `Utils` и реквайрится лениво только в `InputController` под `TestingConfig.IsTesting` — [почему](../../decisions/framework.md#gizmos-вне-utils).

## Конфиги (`ReplicatedStorage.Configs`)

`CameraConfig`, `CollisionConfig` (группы `Character`, `Ragdoll`), `ConflictingGuisConfig` (пуст), `ControlsConfig` (секция `Use`: клавиши, `TapAnywhere`, подписи), `DevProductsConfig` (пуст), `DevelopersConfig` (UserId разработчиков: dev-покупки и `/wipe`; пуст), `FadingConfig`, `GamepassesConfig` (`Attributes` пуст), `InputConfig`, `MessagesConfig`, `NumberPostfixes`, `PopUpsConfig`, `SavesConfig`, `SoundConfig` (`Sfx` с полем `PitchVariation`), `SoundNames`, `TestingConfig`, `ToolsConfig` (`Priority`, `Actions` пусты), `WorldConfig` (тег воды).
