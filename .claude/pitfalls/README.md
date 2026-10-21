# Грабли

До первой правки в сессии прочитай целиком [MCP](roblox-studio.md), [проверки](validation.md) и [перенос](source-transfer.md). Остальное — вместе с областью. Запись: **симптом → причина → исправление → проверка**; добавляй в существующую тему.

Pitfalls не подгружаются сами: маршрут к ним идёт из [rules](../rules/) и корня, а самое дорогое по MCP приезжает хуком ([памятки](../hooks/roblox-mcp-reminders.json)).

| Файл | Область |
|---|---|
| [roblox-studio.md](roblox-studio.md) | `execute_luau`, `multi_edit`, `script_grep`, окна Studio, кадры, синтетический ввод |
| [validation.md](validation.md) | компиляция плейса, висячие ссылки, типы, GUI, консоль, пробы, тестовые значения |
| [source-transfer.md](source-transfer.md) | выгрузка Source, контрольные суммы, перенос между плейсами, карта и Terrain |
| [runtime.md](runtime.md) | старт каркаса, порядок событий, респавн, сетевое владение, звук |
| [input-and-ui.md](input-and-ui.md) | мировой GUI, кнопки, клавиши и промпты, разметка, лоадскрин, камера |
| [world-and-physics.md](world-and-physics.md) | коллизии и рейкасты, рэгдолл, обломки, NPC и pathfinding |
| [models-and-animations.md](models-and-animations.md) | геометрия моделей, тул в руке, анимации и публикация |
| [saves-and-purchases.md](saves-and-purchases.md) | обработчик покупки, ProfileStore, разделы и атрибуты |

Числа в записях — замеры, а не требования. Пример механики, которой в шаблоне нет, не делает её требованием.

**Проверяй результат:** ответ инструмента означает «вызов состоялся». Нужны свежий Source, состояние мира или консоль.
