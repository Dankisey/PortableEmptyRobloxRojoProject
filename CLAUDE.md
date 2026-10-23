# CLAUDE.md

Claude Code instructions for `<Game name>`. Before any task, read this file in full and apply the Workflow section; then read the rules of the affected areas from the table below.

> Template stub. Fill in everything in `<angle brackets>`, describe the game in [concept](.claude/docs/concept.md) and the milestones in the [plan](.claude/docs/roadmap-to-prototype.md). Delete this line.

## Project

`<Game name>` — `<one paragraph: what the player does, why, and how a session ends>`. Concept — [concept.md](.claude/docs/concept.md), plan — [roadmap-to-prototype.md](.claude/docs/roadmap-to-prototype.md), open work — [debts.md](.claude/docs/debts.md).

The place is built from the `Empty Project` template: own DI, saves on service sections and player attributes (ProfileStore), monetization, admin panel, ragdoll, tools, GUI framework. How it works — [systems reference](.claude/docs/systems/README.md).

## Required constraints

If a task requires breaking a constraint, stop and ask.

1. Truth order: Source in Studio → [systems reference](.claude/docs/systems/README.md) → decisions and history. Read balance numbers from current configs, not from documents.
2. No Rojo and no git. Code and layout live in Studio and are edited through MCP; documentation lives only here locally. Code rollback is the place version history.
3. The server is authoritative: the client sends intent, the server checks distance, cooldown, time, balance and that the object belongs to the player; currency and progress are granted only by the server, exactly once. The client draws effects and UI. Exception: character physics belongs to the client; the server holds the state and broadcasts signals.
4. Permanent animations and effects are started on the client; scene state travels through attributes and `Value` instances.
5. DI loads only direct children of a core; equal names silently overwrite each other. A new service or controller needs a type export, `Services`/`Controllers` and the [code map](.claude/docs/systems/code-map.md) in the same task.
6. Balance and content numbers live in configs with a single source; a new item, enemy or level is a config entry without logic changes.
7. A purchase handler never yields and never writes to `DataStore`; only `SavesLoader` knows about ProfileStore. Before release, save fields change without migrations.
8. Studio owns the GUI layout: the source of truth is a prepared template, code only clones prepared templates and never overwrites static `Position`/`Size`/`AnchorPoint`; a new `ScreenGui` has `ResetOnSpawn = false`; mouse input in the screen center is never sunk. Phones are the main platform. Details — [ui](.claude/rules/ui.md).
9. Everything that is raycast against collides with `Default`; water and ground only through `WorldQuery`. Temporary physical objects are limited in count and lifetime.
10. The audience includes children: content and mechanics are age-appropriate. Claims about Roblox platform rules are marked as needing a check in the current documentation.
11. If asked not to start Play, do not start it; never stop someone else's Play. Only the user closes a task or a milestone.

One task, one solution path. A second path for the same job is allowed only with a reason in decisions and a deadline for unification.

## Where to work

| Place | Purpose |
|---|---|
| `<Name>` — PlaceId `<placeId>`, GameId `<gameId>` | All development. Pick `studio_id` with `list_roblox_studios` by the PlaceId in the window name: other places are often open next to it |
| `ServerStorage.ServerCore` / `ReplicatedStorage.ClientCore` | Services / controllers; how they work — [framework](.claude/docs/systems/framework.md) |
| `ServerStorage.AdminGui` | Admin panel, given only to developers — [decision](.claude/decisions/framework.md#admin-panel-outside-di) |
| `ReplicatedStorage.Configs` | All balance and content numbers |
| `.claude/` | Rules, decisions, pitfalls, reference, hooks; layout — [README](.claude/README.md) |
| `tools/documentation/` | Documentation check |
| `tools/rbxl-export/` | Export scripts from a saved `.rbxl` into a Rojo layout and verify with `rojo build` |
| `backup/` | Archive of closed plans. Sets no rules |

## Which rules to read

Claude Code always loads `workflow` and `code-style`: they have no `paths`. Read the other rules explicitly from the table. Code lives in Studio, and `paths` fires only on local documents. Hooks deliver MCP tool reminders and the animation and UI principles at the moment of the call.

| Area | Rule in .claude/rules/ |
|---|---|
| Any task: conversation, questions, checks, report | [workflow.md](.claude/rules/workflow.md) |
| Any Luau | [code-style.md](.claude/rules/code-style.md) |
| Studio, MCP, Source transfer, hooks, tools | [project-setup.md](.claude/rules/project-setup.md) |
| DI, server/client, state owners, types, remotes, admin panel | [architecture.md](.claude/rules/architecture.md) |
| Saves, ProfileStore, sections, purchases, currency | [saves-and-monetization.md](.claude/rules/saves-and-monetization.md) |
| Tools, input, keys, camera | [input-and-ui.md](.claude/rules/input-and-ui.md) |
| Interface: layout, buttons, lists, fonts, purchase buttons, UI motion | [ui.md](.claude/rules/ui.md) |
| Ragdoll, collisions, raycasts, debris, models, animations | [character-physics.md](.claude/rules/character-physics.md) |
| Documentation, indexes, hooks | [documentation.md](.claude/rules/documentation.md) |

Game rules are added with milestones and listed here.

Before the first edit in a session, read [project-setup](.claude/rules/project-setup.md), [MCP](.claude/pitfalls/roblox-studio.md), [validation](.claude/pitfalls/validation.md) and [Source transfer](.claude/pitfalls/source-transfer.md) in full. For the affected system, read its reference, pitfalls and decisions. Every animation edit is checked against the [animation principles](.claude/docs/animation-principles.md); every interface edit against the [UI principles](.claude/docs/ui-principles.md).

## Workflow

- **Every task starts with planning together with the user. The agent must not decide for the user:** choose an unapproved option, replace an answer with an assumption or treat silence as consent. Before agreement, reading the project and Studio and gathering facts for the discussion are allowed; implementation is not.
- When defining a task, close every needed branch in order: goal and scope, expected behavior and game scenarios, constraints, dependencies on existing systems, implementation, edge cases and acceptance criteria. For a feature, discuss the relevant questions of server/client, saves, balance, presentation, phones and monetization; do not inflate irrelevant topics.
- Explain each new question briefly in plain words: what needs a decision, an example situation in the game, which mechanics and systems it touches and what the choice affects. Give several reasonable options with pros and cons, your recommendation and its reason; then wait for the choice. Discuss related questions together and dependent ones after the choice that defines them.
- If a choice needs a game reference, ask which game and mechanic to follow. Search the internet for references only with the user's permission, if not given yet; never attribute behavior to a game without checking.
- Before implementation, briefly summarize the agreed result and the verification plan. Start only when it is fully clear how the user wants the feature, every needed branch is closed and the implementation is approved. Reuse explicit answers and accepted decisions without asking again; do the ordinary details of the agreed approach yourself without adding new decisions for the user.
- Do not accept a proposed implementation automatically: assess the effect on server/client, phone performance, config extensibility and maintenance. If it has drawbacks, object with arguments and an alternative, separating facts from assumptions. Do not argue for its own sake.
- If a new question, ambiguity, material risk or a change of the agreed approach appears, stop the dependent work and return to the same discussion order; do not pick the answer yourself. An accepted decision goes to decisions; agreed scope, order and checks go to the plan.
- Details — [workflow.md](.claude/rules/workflow.md).

## Acceptance and writing

Chat replies use the user's language. All project text is English: documentation, code, comments, UI text, diagnostics. Simple common words and standard technical terms; Roblox terms are not translated. Short and concrete, bad news first; numbers, names and paths exactly.

- `[auto]` — an observed result: place compilation, fresh Source, world state, console. "edits applied" and `loadstring` without errors prove only that a call happened.
- `[visual] — needs your check`: physics, animations, timings, readability of VFX and UI, control feel. Never mark these done yourself.
- For a manual test, speed up numbers in the config file before Play and report "normal → test". After acceptance restore the normal values and verify `.Source`.
- Unverified work is called "done, not verified" with a way to check it.

## Documentation maintenance

- Before a task read [debts](.claude/docs/debts.md) and the [plan](.claude/docs/roadmap-to-prototype.md); before gameplay — the [concept](.claude/docs/concept.md); before an alternative solution — [decisions](.claude/decisions.md).
- The root holds constraints and routes; rules — area requirements; systems — the actual structure; decisions — choices and reasons; pitfalls — symptom/cause/fix; debts — open work; plan — order and criteria. One fact in detail in one place.
- Documentation is impersonal: no dates, no names of other projects, no history of who decided what.
- Added or renamed a rule — update the table above. A new expensive MCP pitfall — also a line in the [hook reminders](.claude/hooks/roblox-mcp-reminders.json).
- After editing documentation, run the check and follow [documentation.md](.claude/rules/documentation.md):

      powershell -NoProfile -ExecutionPolicy Bypass -File tools/documentation/check-agent-docs.ps1
