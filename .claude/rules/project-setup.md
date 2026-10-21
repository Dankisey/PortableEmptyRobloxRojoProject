---
paths: [".claude/docs/systems/framework.md", ".claude/docs/systems/code-map.md", ".claude/pitfalls/roblox-studio.md", ".claude/pitfalls/source-transfer.md", ".claude/hooks/**", ".claude/settings.json", "tools/**"]
---

# Studio, MCP, инструменты

- Разработка прямо в Studio через MCP, Rojo и git нет. Перед работой — `list_roblox_studios`, выбрать окно по PlaceId из [корня](../../CLAUDE.md#где-работать) (рядом бывают открыты чужие плейсы), `get_studio_state`; для правок кода нужен Edit.
- Source в Studio главнее справки и локальных выгрузок. В Play `script_read`/`script_grep` видят только клиентский DataModel; `ServerStorage` читай через `execute_luau` с `datamodel_type = "Server"`, код правь в Edit.
- `require` проектного модуля из `execute_luau` запрещён — только `loadstring(module.Source)`; живое состояние синглтонов — через мир, `GameValues`, атрибуты или пробу-скрипт. Подробно — [roblox-studio](../pitfalls/roblox-studio.md).
- Новый `ModuleScript` создаётся `multi_edit` (className + пустой `old_string`), текст — через `ScriptEditorService:UpdateSourceAsync`, сверка — `script_read`: запись `.Source` в такой скрипт до Play не доходит ([грабля](../pitfalls/roblox-studio.md#скрипт-созданный-multi_edit-живёт-документом--запись-source-до-play-не-доходит)). Папки — `execute_luau`. Один файл правится одним инструментом.
- Код считается работающим после запуска в Play с чистой консолью: `loadstring` и модульный тест проверяют `.Source`, а не то, что исполнится.
- После шага кода: компиляция плейса, консоль, а при изменении состава — типы против ядер и GUI против модулей ([validation](../pitfalls/validation.md)).
- Перед массовым удалением выгрузи Source удаляемого в `backup/` и сверь контрольной суммой ([source-transfer](../pitfalls/source-transfer.md)). Новые модули после дописывания — тоже в `backup/`.
- В конце содержательной работы попроси сохранить плейс (`File → Save`): несохранённая сессия уносит всё.
- Памятку MCP даёт хук ([памятки](../hooks/roblox-mcp-reminders.json)). Не пришла — прочитай раздел своего инструмента вручную. Новая дорогая грабля MCP — строкой в JSON.
- Ассеты и сторонний код в чужие игры не переносим без разрешения; секреты — только `HttpService:GetSecret`, в коде их нет.
