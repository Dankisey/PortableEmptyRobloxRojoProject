# Agent documentation

## `.claude/` layout

A long file read at the start of a session is forgotten by the time of the mistake. So: a short root with constraints and routes, `rules/` by area, topic `decisions/` and `pitfalls/`, the `docs/systems/` reference, open work in `docs/debts.md`, a milestone plan.

- **One agent.** There is no `.codex/` and no `AGENTS.md`: mirrors double every documentation edit.
- **No HTML site** — one reference for people and the agent, `docs/systems/`.
- **No git** — closed plans go into `backup/` as copies; code rollback is the place version history.
- **`paths` barely works.** Code lives in Studio, there are no code files on disk, and `paths` frontmatter fires only on local documents. So `workflow` and `code-style` are rules **without** `paths` (Claude Code always loads them), the rest are read explicitly from the root table.
- **The main pitfall trigger is a hook on the MCP tool** ([reminders](../hooks/roblox-mcp-reminders.json)): there is no file path to attach a reminder to.

Cost: rules without `paths` take context in every session, so there are two and they are short. Revision — when Rojo appears and code lands on disk: area rules then get `paths` to code files.

## English and impersonal

All project text is English, chat replies use the user's language. Documentation has no dates, names of other projects or "who decided": a decision keeps the choice, the reason, the cost and the revision condition. Dated history goes stale and turns a rule into a story; English keeps code, comments and docs in one language.

## Principles hook

The animation and UI principles are delivered by a PreToolUse hook on `multi_edit` and `execute_luau` when the call text contains animation or interface words ([principles](../hooks/principles-reminders.json)). A rule in the root table is forgotten in a long session; the hook arrives at the moment of the edit. Cost: false positives on calls that only read GUI; the reminder is short. Revision — if it becomes noise.

## No workflow skill

The workflow is a rule without `paths` that loads itself: a skill has to be remembered and invoked, a rule does not.

## Planning with the user is mandatory

The workflow ([workflow](../rules/workflow.md), Workflow section of the root) forbids the agent to decide for the user: before agreement only reading the project and Studio. A wording like "make routine decisions yourself" let the agent pick unapproved options.
