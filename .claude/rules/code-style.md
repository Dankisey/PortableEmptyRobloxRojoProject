# Code style

Loaded in every session: any Luau edit. All code text is English: names, comments, strings, warnings.

## Code reads like English

The main goal: a reader understands the code from names alone, as plain English sentences.

- Simple common words: `Animation`, not `cue`; standard game and algorithm terms are fine (`Cooldown`, `Hitbox`, `Path`). No abbreviations (`player`, not `plr`; `character`, not `char`), no vague `Manager`/`Helper`/`Data2`.
- Intermediate calculations and complex conditions get a named local variable, even when used once. An `and`/`or` chain moves out of `if` into a `local isX = ...`.
- One question, one function: before writing a check ("is alive", "is admin", "can buy") look for an existing function. Similar code answering different questions is not merged.
- A function longer than one screen or nested deeper than three levels is a reason to look for mixed responsibilities.
- Name every number through a module constant or a config field. A literal `0`, `1` or an empty table is fine when its meaning is obvious.
- Repeated blocks become a function. A calculation before `warn` or string formatting gets a local variable.

## Names are contracts

| What | How | Example |
|---|---|---|
| Private field | `_camelCase` | `self._activeEntries` |
| Public field | `PascalCase` | `self.IsRagdolled` |
| Method | `PascalCase` | `RagdollService:GrantImmunity()` |
| Local function, private method | `camelCase` | `local function getWorldFolder()` |
| Local module constant | `PascalCase` | `local CameraFollowSpeed = 9` |
| Module | `PascalCase` | `ToolsController` |
| Boolean | `isX` / `canX` / `hasX` | `local isEnabled` |
| Collection | plural | `self._guis` |

- **Underscore means private only.** A field read from outside is public and has no underscore: `RagdollController.IsRagdolled` is a field, not a method.
- `TryX` always returns `boolean`: `true` — done, `false` — not done; extra data goes as later return values.
- An action name (`Spawn`, `Apply`, `Give`, `Release`) promises the action happens. An action that may be skipped in normal play is `TryX` when the caller needs the result, otherwise the condition goes into the name: `MoveIfFree`.
- `IsX` / `CanX` / `HasX` only answer a question and change nothing.
- A name describes current behavior; when behavior changes, rename it.
- Classes, fields and modules are nouns; methods and functions are verbs. An active module names the actor: `SpawnPointFinder`, not `SpawnPointFinding`.

## Functions

- **A private method is only a local function** with `self` as the first argument: `local function createEntry(self, zone, position)`, called `createEntry(self, zone, position)`. `function Module:_name()` and `Module._name = function` are not written. Without `self` use, there is no parameter. The function is declared above its first use: otherwise Luau silently takes a global.
- "Did not work" is `nil` or `false`, not `error`. `error` and `assert` are for broken invariants and invalid content at load.
- A public method with `task.wait` or a `DataStore` request inside is marked `-- blocks the calling thread`.
- A test never replaces or calls private code: it checks through the public API, remotes and mock signals.

## Layout and indentation

- **Tabs**, not spaces. In `multi_edit` `old_string`/`new_string` tabs are written as `\t` ([why](../pitfalls/roblox-studio.md)).
- **Semicolons** in configs and table literals:
  ```lua
  local entry = {
  	Id = self:NextId();
  	Position = position;
  	Health = health;
  }
  ```
- **Module header:** `game:GetService` block → assets and remotes → `require`. Inside `require`: templates (`ServiceTemplate`, `ControllerTemplate`) → utilities → configs → nested and sibling modules.
  ```lua
  local ReplicatedStorage = game:GetService("ReplicatedStorage")
  local Players = game:GetService("Players")

  local Remotes = ReplicatedStorage.Remotes.Ragdoll
  local StateChanged = Remotes.StateChanged

  local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
  local CharacterUtils = require(ReplicatedStorage.Modules.Utils.CharacterUtils)
  local CollisionConfig = require(ReplicatedStorage.Configs.CollisionConfig)
  ```
- **Guards are one line:** `if not thing then return end`.
- At most one blank line in a row. A blank line between functions and between logical blocks of a function.
- `if` / `for` / `while` blocks and single-line guards are separated from neighboring code by a blank line.
- A multiline call, table or signature closes its bracket on its own line at the indentation where the expression starts.
  ```lua
  local tween = TweenService:Create(
  	value,
  	TweenInfo.new(duration, Enum.EasingStyle.Quad),
  	{Value = targetCFrame}
  )
  ```
- Section separators in long modules: `--[[========================= name =========================]]`.

## Comments

**By default there are no comments. Code explains itself by names.** Wanting to describe what a function does means renaming it or splitting it.

A comment stays only if **without it the next reader breaks working code**: the order of ragdoll and impulse, the no-yield rule in a purchase handler. The form is **one line about WHY**:

```lua
--[[ no blocked guard: blocking may start mid-windup, and an eaten release would leave the player in the windup forever ]]
function ToolsController:ReleaseEquippedTool()
```

- No dates, milestones, plan links or history ("previously", "we tried", "the user decided") in code: they go stale and belong in the docs.
- No numbers copied from code or configs into comments: values change and the comment starts lying. Name the constant or explain without the value.
- Removed: module headers, retelling of the code, essay docblocks, descriptions of removed code, commented-out code. Large decisions live in [decisions](../decisions.md), pitfalls in [pitfalls](../pitfalls/README.md); a hint in code is enough.
- Also kept: section separators, `-- blocks the calling thread`, a return contract not visible from the name (`-- false = no session`), units of config numbers (`-- seconds between ticks`).

A file edited for substance is brought to these rules. Someone else's comments are not rewritten for style alone.

## Types

Types live in `ServerStorage.ServerTypes`, `Modules.ClientTypes`, `Modules.SharedTypes`, `Modules.UtilsTypes`.

**Added a service, controller, GUI module or utility — you must add** the module type export and the entry in `Services` / `Controllers` / `Utils` (for `GuiController` — its fields). Otherwise the types go stale silently. Check — the "types against code" snippet in [validation](../pitfalls/validation.md#types-against-code).

Parameter annotations everywhere the type is not obvious: `function Enemy:Attack(player: Player, targetRoot: BasePart)`.

## Configs

Every balance and content number lives in a config with a single source: an item price lives only in the item config. A new item, enemy or level is a config entry without logic changes. Units of numbers are written next to them.

## Module boundaries

A new module appears only if it **removes duplication from two or more places** or **cuts an independent responsibility out of a file of 300+ lines**. A responsibility that reads the parent's internals becomes a nested module behind the parent's API ([decision](../decisions/framework.md#a-new-module-only-when-it-pays)).
