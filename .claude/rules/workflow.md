# Workflow

Loaded in every session. Root — [CLAUDE.md](../../CLAUDE.md).

## How to talk

- Chat in the user's language, like a colleague at the next desk: short live sentences, no bureaucratic tone. Code, names and Roblox terms stay English.
- Bad news goes first and plainly. The result is not sweetened: done is done, unverified is unverified.
- The relaxed tone is about form only: numbers, module names and paths are exact.

## Entry and decisions

- Before a task read [debts](../docs/debts.md) and the [plan](../docs/roadmap-to-prototype.md); before gameplay — the [concept](../docs/concept.md). Read the chosen documents in full.
- **Read the code first, then ask.** Read the relevant modules in full and grep for the real callers. Do not ask what can be read.
- **Every task starts with planning together with the user** following the Workflow section of the [root](../../CLAUDE.md#workflow). You make no decisions for the user: an unapproved option, an assumption instead of an answer and silence as consent are forbidden. Before agreement — only reading the project and Studio and gathering facts.
- Questions come **in batches of up to four**, each in plain words: what to decide, an example situation in the game, what the choice affects; options with a **difference in consequences** ("A gives this at that cost; B the other way round") and a recommendation with its reason.
- Do not accept a proposed implementation automatically: assess server/client, phone performance, config extensibility and maintenance. If it has drawbacks, object with arguments and an alternative, separating facts from assumptions. Do not argue for its own sake.
- **Do not write code or edit the place until the branches are closed** and the user approved the final summary with the verification plan. New questions appeared — stop the dependent work and ask again.
- Do the ordinary details of the agreed approach yourself without adding new decisions; list what you did in the report.
- One task, one path. A second path for the same job is allowed only with a reason in decisions and a deadline for unification.
- Found a side bug — say so, show the consequence, propose a fix. Never fix it silently "while at it".
- Hand subtasks to subagents yourself when justified: broad searches, independent research. Work tied to the current edit you do yourself.

## Studio and checks

- Follow [project-setup](project-setup.md). If asked not to start Play, do not; never stop someone else's Play; stop your own after the check and remove temporary probes.
- Run a large task in steps with a check after each. If the next step depends on a manual result, wait for the answer.
- Check everything machine-checkable per [validation](../pitfalls/validation.md): place compilation, dangling references and `require`, types against cores, GUI against modules, fresh Source, world state and console after every step.
- **Check the fact, not the tool response.** "edits applied", `loadstring` without errors, a metric saying "enabled" mean only "the call happened". Verify an edit by the **new** text and its occurrence count, with `find(..., true)`. Verify movement by a trajectory log in Play, not one snapshot.
- Verify claims of the plan and documentation with your own greps, not on trust.

## Acceptance and report

Report: **what was done** — the substance; **what was checked** — two flat lists without tables; **what to watch** — differences from the plan, interpretations, risks. A Command Bar snippet goes in a separate block before the lists.

```markdown
**[auto]:**
- `loadstring` over the place: 105 scripts, 0 errors, 0 dangling `require`.
- The edit is verified against fresh Source: the new text occurs exactly once.

**[visual] — needs your check:**
- The object breaks apart at the moment of the hit, not a frame later.
- The HP bar is visible above the object on a phone in landscape.
```

- `[auto]` is an observed result, not a claim about it.
- `[visual]` is a statement of what should be visible, not an assignment. Physics, animations, timings, readability of VFX/UI and control feel always go here: numeric metrics have lied before. Never declare them done.
- For a manual test, temporarily tune numbers for one person (widen short windows, shorten long waits) and report "normal → test". After acceptance restore the normal values and verify `.Source`, unless the user accepted the test values as balance. An accelerated test does not confirm balance.
- **Only the user closes a task or a milestone.** Until `[visual]` is confirmed — "done, not verified".

## Keeping the context

Follow [documentation](documentation.md): a new choice goes to decisions, a new pitfall to pitfalls and, when needed, to the hook reminders, a service or controller to types and the [code map](../docs/systems/code-map.md), open work to debts. Before a mass deletion and at the end of meaningful work, ask the user to save the place: rollback is the place version history.
