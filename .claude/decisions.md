# Decisions

Index of non-obvious choices. Before replacing a decision, read its topic file; agree a revision with the user. Edit requirements live in [rules/](rules/), open work in [docs/debts.md](docs/debts.md).

| File | Decisions |
|---|---|
| [framework.md](decisions/framework.md) | own DI, no Rojo, version history instead of Source copies, infrastructure outside cores, counters on instances and attributes, module boundaries, admin panel outside DI |
| [saves.md](decisions/saves.md) | everything saved is service sections + attributes, ProfileStore, sync, `IsLoaded`, wipe from the admin panel, free developer purchases switch, join order |
| [character-physics.md](decisions/character-physics.md) | physics on the client, ragdoll structure, collision groups in code |
| [input-and-ui.md](decisions/input-and-ui.md) | tools without `Activated`, tap anywhere behind a flag, release, `InputBegan` and the hold button, label by `PreferredInput`, cursor, first person, mouse input, landscape only, layout from templates |
| [agent-docs.md](decisions/agent-docs.md) | documentation layout, one agent, English and impersonal text, rules without `paths`, hooks instead of skills, principles hook, mandatory planning |

Each entry has the reason, the cost and the revision condition. An accepted decision does not mean an implemented mechanic. Game decisions get their own files with milestones.
