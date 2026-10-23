# Saves and purchases

## A purchase handler lives inside `UpdateAsync`

`Monetization:ProcessReceipt` marks the receipt through the purchases history `UpdateAsync`, and the delivery handler runs **inside the transform function**, which never yields:

```
DataStore request was added to queue...
Transform function error Callbacks cannot yield
```

The first line looks like performance, the second is the cause: the purchase is not granted. Section owners may be called (`SoftCurrencyService:AddCurrency`) and `RequestSave`/`Save`. Writing to `DataStore` is forbidden even through a helper. The item counts as granted at the moment the owner cache changes; refusals without yielding are `false`, the receipt stays queued.

Check "does the handler yield" by reading the source: the words `UpdateAsync` and `WaitForChild` also appear in comments.

## `ProcessReceipt` must return a decision

A wrapper without `return` gives `nil`, Roblox reads it as `NotProcessedYet`: Robux are charged, nothing is granted, the receipt repeats on every join. The framework has the return — do not lose it in an edit.

## `DataStore` on module load fails in an unpublished place

`DataStoreService:GetDataStore` at module level prints `You must publish this place to the web to access DataStore`, and the whole module is lost (`Module Monetization was not loaded`). Get stores lazily on first use; `Monetization` does.

## `Profile:Save()` does not yield

The method ends with `task.spawn(SaveProfileAsync, self)` — this makes a write from a purchase handler legal. Check by the source, not by the name. On an inactive session it warns and returns (`Attempted saving an inactive profile`), so the `profile:IsActive()` guard is required.

`StartSessionAsync` yields long: `FIRST_LOAD_REPEAT`, `LOAD_REPEAT_PERIOD`, a steal by `SESSION_STEAL` take seconds. Without `Cancel` a player who left keeps the thread and the key. A handover between two windows: the second waited and left by `Cancel`; after `EndSession` it took the key within seconds.

## `MessagingService` and `BindToClose` are noisy in Edit

```
MessagingService can only be executed by game server
Script 'ServerStorage.ProfileStore', Line 1340 - function RobloxMessageSubscription
```

or `BindToClose can only be called on the server` — depending on the moment of `require`. An artifact of the mode, not a defect; a session handover measured in Edit is inflated.

## ProfileStore silently overwrites a foreign format

Anything not shaped like `{Data, MetaData, GlobalUpdates}` goes to `overwritten = true` ("Silently override with empty profile"). Moving a live game without a migrator wipes saves. Check by reading the branch, not by a probe on a live key: the probe is the overwrite.

## Reading a section in `LoadSave`

- **`or` replaces a saved `false` and `0` with the default** (`data.x or default`). Compare with `nil` and by type; a string in place of a number broke the whole join.
- **Changing a default grants nothing to old players**: their saved value is respected. A new default covers only new profiles; old ones need code.
- **A section in every place with a shared `DataStore` must be read the same way**: a place that does not know a section leaves it alone, but a place with an old section schema overwrites it with its own.

## Sections

- **A service that changes a section must implement `GetSave`.** Without it the section leaves as read on join: in session everything works (the cache was updated), after a rejoin it rolls back — a cooldown did not start, a purchase vanished. The sign is a console warning about a section without `GetSave`.
- **A purchase is written right away, with a debounce** (`RequestSave`, `SaveInterval`): the player leaves by teleport, and the next server reads almost immediately. The soft `DataStore` limit is about one write per several seconds per key; compare with the current limits in the Roblox documentation.
- **A shared synchronous write point for everyone** (round end) on a full server gives an `UpdateAsync` peak; a short `AutoSavePeriod` spreads the writes.
- **A debug empty save is a separate store** (`ProfileStore.Mock`), not a branch on write: a branch leaks into the real path.
- **A lock, not increments**: "owned / selected" fields are absolute, increments do not remove the race on them.

## Donations and soft currency

- A donation is routed by `ProductId`, not by a zero price (a free starter item also costs 0).
- No reply remote is needed: the result is visible through player attributes; "nothing changed" is an honest answer to a race or a cheat.
- A free developer purchase calls the product handler directly, outside `UpdateAsync` and without a receipt: a handler that relies on `receiptInfo` fields other than `ProductId` breaks there.
