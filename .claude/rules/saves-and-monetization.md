---
paths: [".claude/docs/systems/saves.md", ".claude/decisions/saves.md", ".claude/pitfalls/saves-and-purchases.md"]
---

# Saves and monetization

- **The game is not released, there are no live saves.** Until release, fields can be renamed and removed without migrations; on release day this rule is lifted, and every schema change needs a migration.
- Every saved field lives in the section of its owning service by the `SaveSection` + `LoadSave` + `GetSave` convention ([saves](../docs/systems/saves.md)); there are no `PlayerData` folders. What the client needs, the owner publishes as a player attribute and updates on every change; the source of truth is the service cache. `SavesLoader` is not edited for a new section.
- `LoadSave` validates every field (type, finiteness, sign) and substitutes the default: saves contain garbage, and a new player has `data = nil`.
- `GetSave` is non-destructive and runs before every write; `nil` means "not read". Sections do not depend on each other.
- A derived value is not saved if it follows from a saved one (a level from an accumulated value): otherwise the two sources drift apart.
- Only `SavesLoader` knows about ProfileStore. No `BindToClose`. The write guard is `profile:IsActive()`, not a "loaded" flag.
- A purchase handler (`Monetization:RegisterProduct`) runs inside `UpdateAsync`: it never yields and never writes to `DataStore`. It may call section owners (`AddCurrency`) and `RequestSave`/`Save`. A refusal without yielding is `false`, the receipt stays queued.
- Currency and progress are granted only on the server, for a verified event, exactly once; repeating the same event gives nothing.
- Monetization — Game Pass / Developer Product through `Monetization`. Free developer purchases are off by default and switched by the `DeveloperPurchasesEnabled` attribute on the `Monetization` module (the admin panel button); while on, every developer from `DevelopersConfig` on that server gets items without a prompt.
- A save wipe is the admin panel `Reset` button: `SavesLoader:WipeSave` clears the whole save and kicks. Studio writes to the real `DataStore`, so test the wipe itself with `SavesConfig.UseEmptySave = true`.
- Robux prices account for the Roblox fee and the DevEx rate; platform rules (DevEx, Premium Payouts, paid random items) are checked in the current Roblox documentation.
- The audience includes children: purchase mechanics and texts are age-appropriate, without pressure or misleading wording.

Before an edit read [saves](../docs/systems/saves.md), [decisions](../decisions/saves.md) and [pitfalls](../pitfalls/saves-and-purchases.md).
