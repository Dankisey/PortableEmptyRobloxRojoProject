# Сейв

Причины устройства — [решения](../../decisions/saves.md), грабли — [saves-and-purchases](../../pitfalls/saves-and-purchases.md).

## Разделы

Каждое сохраняемое поле принадлежит сервису-владельцу раздела; папок `PlayerData` нет. `SavesLoader` держит сессию и раздаёт разделы по соглашению: поле `SaveSection` плюс `LoadSave` и `GetSave`, `UnloadSave` необязателен. Правки `SavesLoader` новый раздел не требует, шаблона профиля нет — значения по умолчанию задаёт владелец в `LoadSave`.

```lua
local MyService = {}
MyService.SaveSection = "Index"

-- data = nil у нового игрока; мусор в сейве — валидировать и заменить значением по умолчанию
function MyService:LoadSave(player: Player, data: any) end

-- зовётся перед КАЖДОЙ записью, обязан быть неразрушающим; nil = «сейв не читался», раздел не трогают
function MyService:GetSave(player: Player): any end

-- необязателен: только отпускает кэш на выходе, возврат не читается
function MyService:UnloadSave(player: Player) end
```

Нужное клиенту владелец публикует **атрибутом игрока**: источник правды — кэш сервиса, атрибут — зеркало, которое сервис обновляет при каждом изменении. Клиент подписывается на `GetAttributeChangedSignal`; атрибута нет — сейв не загружен, на счётчике `...` (так сделан `MainGui.CashLabel`).

| Раздел | Владелец | Данные | Атрибут игрока |
|---|---|---|---|
| `Stats` | `SavesLoader` | `FirstJoin`, `LastExit`, `TotalPlaytime` | — |
| `Currencies` | `SoftCurrencyService` | `Balances[валюта]`, `Earned[валюта]` — всего заработано | имя валюты: `Cash` |

Список валют — `Currencies` в самом `SoftCurrencyService`. Порядок сервисов не задан, поэтому разделы не зависят друг от друга. Раздел без `GetSave` пропускается с варнингом и уезжает таким, каким был прочитан.

## Сессия и запись

- **ProfileStore держит ключ на время сессии**: пришедший сервер ждёт, пока прошлый отпустит. Знает про него ровно `SavesLoader`.
- **Кэши владельцев — рабочая копия, `profile.Data` — то, что уедет в `DataStore`.** Связывает их `syncToProfile` на `Profile.OnSave`, который стреляет перед **каждой** записью, включая автосейв. `syncToProfile` не йилдит.
- **Ни один вызов записи не йилдит.** `false` значит «сессии нет», а не «запись не удалась»: доставку гарантирует лок.
- **Автосейв** — `SavesConfig.AutoSavePeriod` = 60 с (у библиотеки 300); единственная защита от падения сервера. `SaveInterval` = 6 с — дебаунс `RequestSave`.
- **`BindToClose` не заводить**: ProfileStore ставит свой.
- `IsLoaded` ставится и при провале загрузки; дальше решает `SavesConfig.KickOnLoadFail` (`true` для игрового плейса, `false` для лобби и меню). Сессию угнал другой сервер — игрока кикает `Profile.OnSessionEnd`.
- `SavesConfig.UseEmptySave` — сессия в `ProfileStore.Mock`, работает только в Studio.
- `DataStoreName` = `PlayersSavesData`, ключ — `SavesConfig.GetProfileKey` (`UserId`). Второй плейс юниверса обязан совпадать в обоих и держать одинаковый `ServerStorage.ProfileStore`.
- **В Studio запись идёт только с включённым Studio Access to API Services** и в опубликованном плейсе; без них ProfileStore пишет `Roblox API services unavailable - data will not be saved`.
- **`/wipe`** — команда чата для Id из `DevelopersConfig`: `SavesLoader:WipeSave` очищает `profile.Data`, закрывает сессию без синка кэшей и кикает с `SavesConfig.WipeMessage` ([решение](../../decisions/saves.md#wipe-для-разработчиков-стереть-всё-и-кикнуть)). `DevelopersConfig` в шаблоне пуст.

**Сейв, написанный не ProfileStore, молча перезаписывается пустым профилем.** Сейвы схемы папок (`Currencies.Cash`, `TotalStats`) разделами не читаются.

## Покупки

`Monetization:ProcessReciept` помечает чек через `UpdateAsync`, и обработчик выдачи работает **внутри трансформ-функции**: не йилдит и не пишет в `DataStore`. Можно звать методы владельцев разделов (`AddCurrency`) и `RequestSave`/`Save`. Отказы, проверяемые без йилда (нет сессии, лимит), возвращают `false` и оставляют чек в очереди Roblox.
