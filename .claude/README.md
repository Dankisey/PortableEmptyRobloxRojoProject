# Документация проекта для Claude Code

Вход — [CLAUDE.md](../CLAUDE.md). `workflow` и `code-style` грузятся всегда; остальные правила читаются явно по таблице корня — код живёт в Studio, и `paths` срабатывает только на локальных документах. Почему так — [agent-docs](decisions/agent-docs.md).

## Где хранить факт

| Файл / каталог | Содержание |
|---|---|
| `CLAUDE.md` | Общие ограничения, карта проекта и маршрут чтения |
| [rules/](rules/documentation.md) | Требования по областям |
| [decisions.md](decisions.md) / decisions/ | Выбор, причина, цена, условие пересмотра |
| [pitfalls/](pitfalls/README.md) | Симптом → причина → исправление → проверка |
| [docs/systems/](docs/systems/README.md) | Фактическое устройство: DI, модули, API, сейв, ремоуты |
| [docs/concept.md](docs/concept.md) | Действующий замысел игры |
| [docs/roadmap-to-prototype.md](docs/roadmap-to-prototype.md) | Вехи, развилки, критерии приёмки |
| [docs/milestones-done.md](docs/milestones-done.md) | Принятые результаты |
| [docs/debts.md](docs/debts.md) | Открытые работы, баги и решения |
| [hooks/](hooks/roblox-mcp-reminders.json) | Памятки PreToolUse на инструменты Studio MCP |

Один факт подробно — в одном месте, в остальных граница и ссылка. Закрытый долг удаляется, полезная регрессия остаётся в pitfalls.

## Архив

Проекта без git: закрытые планы и выгрузки Source — в `backup/`. Архив не задаёт действующих правил.

## Проверка

После правки документации из корня:

    powershell -NoProfile -ExecutionPolicy Bypass -File tools/documentation/check-agent-docs.ps1

[Скрипт](../tools/documentation/check-agent-docs.ps1) проверяет индексы rules/decisions/pitfalls/systems, `paths` правил, локальные ссылки и anchors, JSON памяток. Он не подтверждает факты игры и доставку хука.
