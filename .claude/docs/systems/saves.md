# Saves

Reasons — [decisions](../../decisions/saves.md), pitfalls — [saves-and-purchases](../../pitfalls/saves-and-purchases.md).

## Sections

Every saved field belongs to the owning service section; there are no `PlayerData` folders. `SavesLoader` holds the session and hands out sections by convention: a `SaveSection` field plus `LoadSave` and `GetSave`, `UnloadSave` is optional. A new section needs no `SavesLoader` edit and there is no profile template — the owner sets defaults in `LoadSave`.

```lua
local MyService = {}
MyService.SaveSection = "Index"

-- data = nil for a new player; garbage in the save is validated and replaced by the default
function MyService:LoadSave(player: Player, data: any) end

-- runs before EVERY write, must be non-destructive; nil = "save not read", the section is left untouched
function MyService:GetSave(player: Player): any end

-- optional: only releases the cache on leave, the return value is not read
function MyService:UnloadSave(player: Player) end
```

What the client needs, the owner publishes as a **player attribute**: the source of truth is the service cache, the attribute is a mirror updated on every change. The client subscribes to `GetAttributeChangedSignal`; no attribute means the save is not loaded, and the counter shows `...` (as `MainGui.CashLabel` does).

| Section | Owner | Data | Player attribute |
|---|---|---|---|
| `Stats` | `SavesLoader` | `FirstJoin`, `LastExit`, `TotalPlaytime` | — |
| `Currencies` | `SoftCurrencyService` | `Balances[currency]`, `Earned[currency]` — total earned | the currency name: `Cash` |

The currency list is `Currencies` in `SoftCurrencyService` itself. The service order is not defined, so sections do not depend on each other. A section without `GetSave` is skipped with a warning and leaves as it was read.

## Session and writes

- **ProfileStore locks the key for the session**: an arriving server waits until the previous one releases it. Only `SavesLoader` knows about it.
- **Owner caches are the working copy, `profile.Data` is what goes to `DataStore`.** `syncToProfile` connects them on `Profile.OnSave`, which fires before **every** write, autosave included. `syncToProfile` never yields.
- **No write call yields.** `false` means "no session", not "the write failed": the lock guarantees delivery.
- **Autosave** — `SavesConfig.AutoSavePeriod`, shorter than the library default; the only protection against a server crash. `SaveInterval` is the `RequestSave` debounce.
- **No `BindToClose`**: ProfileStore binds its own.
- `IsLoaded` is set on a failed load too; then `SavesConfig.KickOnLoadFail` decides (`true` for a gameplay place, `false` for a lobby or menu). Another server took the session — `Profile.OnSessionEnd` kicks the player.
- `SavesConfig.UseEmptySave` — the session runs in `ProfileStore.Mock`, Studio only.
- `DataStoreName` = `PlayersSavesData`, the key is `SavesConfig.GetProfileKey` (`UserId`). A second place of the universe must match both and keep the same `ServerStorage.ProfileStore`.
- **In Studio writes happen only with Studio Access to API Services enabled** and in a published place; without them ProfileStore prints `Roblox API services unavailable - data will not be saved`.
- **Wipe** — the admin panel `Reset` button for `DevelopersConfig` Ids: `SavesLoader:WipeSave` clears `profile.Data`, ends the session without syncing caches and kicks with `SavesConfig.WipeMessage` ([decision](../../decisions/saves.md#save-wipe-from-the-admin-panel-wipe-everything-and-kick)). `DevelopersConfig` is empty in the template.

**A save written not by ProfileStore is silently overwritten with an empty profile.** Saves of the folder schema are not read by sections.

## Purchases

`Monetization:ProcessReceipt` marks the receipt through `UpdateAsync`, and the delivery handler runs **inside the transform function**: it never yields and never writes to `DataStore`. It may call section owners (`AddCurrency`) and `RequestSave`/`Save`. Refusals checked without yielding (no session, a limit) return `false` and keep the receipt in the Roblox queue. The purchases history store is taken lazily on the first receipt, so an unpublished place still loads `Monetization`.

Free developer purchases: with the `DeveloperPurchasesEnabled` attribute on the `Monetization` module (off by default, switched by the admin panel), `PromptProduct`/`PromptPass` grant directly to `DevelopersConfig` players, in Studio too ([decision](../../decisions/saves.md#free-developer-purchases-are-a-server-switch)).
