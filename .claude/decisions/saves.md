# Saves and ProfileStore

## Everything saved is service sections + attributes, no `PlayerData` folders

`Value` folders for simple fields next to service sections for complex ones are two mechanisms for one job, and the folders replicate to the client what it does not need (`FirstJoin`, `TotalPlaytime`). So every field belongs to the owning service section, the service publishes what the client needs as a player attribute, and service statistics are the `Stats` section of `SavesLoader` itself.

Cost: the save schema is spread over services (summary — [saves](../docs/systems/saves.md#sections)); defaults are set by the owner in `LoadSave`, there is no profile template. The client can change an attribute only locally — it never reaches the server. Saves of the old folder schema are not read by the new sections: a live game on the old schema needs a migrator.

## Complex sections belong to services

A loader that knows every structure of the game means editing one file per section and a cache nobody validates. A service knows what belongs in its own section.

**The owner is found by convention** (`SaveSection` + methods), not by a list in a config: a list drifting away from code is silent, the section would just stop loading.

**Data comes from a non-destructive `GetSave`**, and `UnloadSave` only releases the cache. Autosave writes many times per session, and a destructive method before each write would give emptiness on the second write. `nil` from `GetSave` means "save not read": writing emptiness instead of an unread value erases progress.

## ProfileStore, not an own loader

A single `SetAsync` on leave has two costs: a server crash loses the whole session (including an already marked purchase), and a second place with a shared `DataStore` silently overwrites the purchases of the first. ProfileStore closes both: a key lock and autosave.

**Not an own lock:** that is over a hundred lines in every place, without a `MessagingService` reaction and `IsCriticalState`. **ProfileStore** is taken, not `ProfileService`: the latter, by the same author, is legacy.

## Sync instead of writing straight into `profile.Data`

The live cache is the section owners' cache; `syncToProfile` pours it in on `Profile.OnSave`. Writes into `profile.Data` from every service would spread ProfileStore knowledge across the server. The seam's cost: progress must be visible through `GetSave`, and `syncToProfile` never yields.

## `IsLoaded` is set on failure too

The attribute means "loading finished". Without it the client would hang on start without a console line. Then `KickOnLoadFail` decides: in a gameplay place a kick is better than playing on defaults that overwrite progress. A "player loaded" flag cannot guard a write — another handler of the same event clears it; the guard is `profile:IsActive()`.

## Save wipe from the admin panel: wipe everything and kick

The admin panel `Reset` button ([admin panel](framework.md#admin-panel-outside-di)) wipes the developer's own save completely, `Stats` included, and kicks with `SavesConfig.WipeMessage`; on rejoin every section loads as for a new player (`LoadSave(player, nil)`). `SavesLoader:WipeSave` does it: a wipe flag, clearing `profile.Data`, `EndSession`, kick. The flag stops `syncToProfile` — otherwise service caches on leave and in the last session write would bring back the wiped data — and stops replacing the kick with the "save open in another server" text.

Why a kick and rejoin instead of an in-place reset: an in-place reset needs a reload path for every service at runtime. Why only a button: one path for one action; there is no chat command. The list is the `DevelopersConfig` keys; in the template it is empty, each project adds UserIds.

Cost: Studio writes to the real `DataStore` — `Reset` in Studio wipes the account's real save; test the wipe itself with `SavesConfig.UseEmptySave = true`.

## Free developer purchases are a server switch

`Monetization:PromptProduct` / `PromptPass` grant the item without a prompt only when the `DeveloperPurchasesEnabled` attribute on the `Monetization` module is `true` and the buyer is in `DevelopersConfig`. The attribute is `false` in the place and resets to it on every new server; the admin panel `FreePurchases` button switches it through `Monetization:SetDeveloperPurchasesEnabled`. It works in Studio too.

Why: by default a developer sees the same purchase flow as a player, including the real `ProcessReceipt` path; free grants are needed only for a deliberate test. The attribute on the module is one visible source of truth, readable in the Explorer during Play. Cost: the switch is server wide — while on, every developer on that server buys for free. Revision — if several developers test on one server at once: a per player attribute.

## `Connect` before iterating players already in the game

`onPlayerAdded` yields three times (policy, lock, game passes). In the reverse order, a player who joined during the loop never got `IsLoaded`. The lock can wait for seconds, so `StartSessionAsync` needs `Cancel`.
