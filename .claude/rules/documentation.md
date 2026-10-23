---
paths: ["CLAUDE.md", ".claude/**/*.md", ".claude/hooks/**", "tools/documentation/**"]
---

# Documentation

- All documentation is English: simple common words and standard technical terms, concise, facts preserved, filler removed. Chat replies use the user's language.
- **Documentation is impersonal:** no dates, no names of other projects or people, no "the user decided" or "previously". A decision states the choice, reason, cost and revision condition, not who and when.
- The root holds constraints and routes; [rules](./) — area requirements; [docs/systems](../docs/systems/README.md) — the actual structure; [decisions](../decisions.md) — choice, reason, cost, revision; [pitfalls](../pitfalls/README.md) — symptom → cause → fix → check; [debts](../docs/debts.md) — open work; [plan](../docs/roadmap-to-prototype.md) — order and criteria; [milestones-done](../docs/milestones-done.md) — accepted results.
- **One fact in detail in one place**, elsewhere a scope line and a link. When moving a fact, delete the old text instead of adding next to it.
- Write concisely: a requirement, a number and a reason in one or two sentences, without history. Shrink a grown item when editing it.
- Verify the actual implementation against Source in Studio. Concept, decisions and plans do not prove a built mechanic. A client brief, if any, goes into `.claude/docs/` as is and is not edited (exception — `$ExcludedDocs` in the check script); the current concept is [concept](../docs/concept.md).
- A closed debt is removed from debts; an accepted milestone goes as a summary into milestones-done, its plan as a copy into `backup/` and out of the active documents. An unconfirmed manual acceptance stays explicit.
- A new or renamed rule goes into the [CLAUDE.md](../../CLAUDE.md) table with `paths` to real local documents of its area (the Studio DataModel has no paths). Only `workflow` and `code-style` have no `paths`: they always load, and a third such rule needs a decision.
- A new decisions/pitfalls/systems file goes into its section index. A new expensive MCP pitfall is also a line in the [hook reminders](../hooks/roblox-mcp-reminders.json).
- If a topic does not fit the sections or a section grows too large, propose a new file to the user: purpose, location, paths. Do not create it silently.
- Documentation lives only locally; it is not duplicated in Studio.

After an edit, from the root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/documentation/check-agent-docs.ps1
```

The check confirms indexes, `paths`, links, anchors, hook JSON and the absence of Cyrillic. Meaning and agreement with Source are checked separately.
