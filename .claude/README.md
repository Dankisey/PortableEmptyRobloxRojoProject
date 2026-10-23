# Project documentation for Claude Code

Entry — [CLAUDE.md](../CLAUDE.md). `workflow` and `code-style` always load; other rules are read explicitly from the root table — code lives in Studio, and `paths` fires only on local documents. Why — [agent-docs](decisions/agent-docs.md).

## Where a fact lives

| File / folder | Content |
|---|---|
| `CLAUDE.md` | Shared constraints, project map and reading route |
| [rules/](rules/documentation.md) | Requirements by area |
| [decisions.md](decisions.md) / decisions/ | Choice, reason, cost, revision condition |
| [pitfalls/](pitfalls/README.md) | Symptom → cause → fix → check |
| [docs/systems/](docs/systems/README.md) | Actual structure: DI, modules, API, saves, remotes |
| [docs/animation-principles.md](docs/animation-principles.md) | 12 animation principles in games and the check for every animation |
| [docs/ui-principles.md](docs/ui-principles.md) | Nielsen heuristics, UX in Motion, game UX pillars and the check for every screen |
| [docs/concept.md](docs/concept.md) | Current game concept |
| [docs/roadmap-to-prototype.md](docs/roadmap-to-prototype.md) | Milestones, forks, acceptance criteria |
| [docs/milestones-done.md](docs/milestones-done.md) | Accepted results |
| [docs/debts.md](docs/debts.md) | Open work, bugs and decisions |
| [hooks/](hooks/roblox-mcp-reminders.json) | PreToolUse reminders for Studio MCP tools and the [principles](hooks/principles-reminders.json) |

One fact in detail in one place, elsewhere a scope line and a link. A closed debt is deleted, a useful regression stays in pitfalls. Documentation is English and impersonal: no dates, no names of other projects.

## Archive

No git: closed plans go to `backup/`. Code rollback is the place version history. The archive sets no rules.

## Check

After a documentation edit, from the root:

    powershell -NoProfile -ExecutionPolicy Bypass -File tools/documentation/check-agent-docs.ps1

The [script](../tools/documentation/check-agent-docs.ps1) checks rules/decisions/pitfalls/systems indexes, rule `paths`, local links and anchors, hook JSON and the absence of Cyrillic. It does not confirm game facts or hook delivery.
