# Шаблон Roblox-проекта

Каркас Roblox-проекта. Код живёт в плейсе-шаблоне: локально `Empty.rbxl` рядом с этим файлом, в облаке — `Empty Project` (`86416691264868`). Здесь — документация агента в раскладке `.claude/`, готовая к копированию в новый проект.

| Что | Куда кладётся в новом проекте |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | корень проекта; заполнить `<угловые скобки>` |
| [`.claude/`](.claude/README.md) | целиком: правила, решения, грабли, справка систем, хук-памятки MCP, `settings.json` |
| [`tools/documentation/`](tools/documentation/check-agent-docs.ps1) | проверка документации |
| `backup/` | не копируется: архив самого шаблона |

## Что в шаблоне

- Свой DI: `ServerCore` / `ClientCore`, сервис = ModuleScript в ядре ([framework](.claude/docs/systems/framework.md)).
- Сейв: ProfileStore, каждое поле — раздел сервиса-владельца, клиенту — атрибуты игрока; `/wipe` для `DevelopersConfig` ([saves](.claude/docs/systems/saves.md)).
- Монетизация: чеки дев-продуктов и геймпассов, обработчики без йилда.
- Рэгдолл на конструктивной R15: сервер держит состояние, клиент делает физику.
- Тулы без `Tool.Activated`, тап в любую точку под флагом, кнопки на `InputBegan` с отскоком и удержанием, подпись клавиши по `PreferredInput`.
- `WorldQuery`, `CollisionConfig`, `SpawnerTemplate`, утилиты ([карта кода](.claude/docs/systems/code-map.md)).

Ни один скрипт не знает ни одного игрового имени. Что заведомо не доделано — [долги](.claude/docs/debts.md).

## Репозиторий

[GitHub](https://github.com/Dankisey/PortableEmptyRobloxRojoProject): документация, `Empty.rbxl` и `src/` — снимок скриптов плейса в раскладке Rojo для чтения и диффов. Правда — в плейсе: `src/` содержит только скрипты и папки, разметка GUI, ремоуты и ассеты есть только в `Empty.rbxl`, поэтому `rojo serve`/`rojo build` из `src/` рабочий плейс не соберут.

Обновление снимка (Python 3.14+, `rojo`), из корня клона репозитория после `File → Save` плейса:

    rm -rf src
    python -I tools/rbxl-export/export_rbxl.py Empty.rbxl src
    rojo build default.project.json -o build.rbxl
    python -I tools/rbxl-export/verify_build.py build.rbxl Empty.rbxl
    rojo sourcemap default.project.json -o sourcemap.json

`export_rbxl.py` сверяет записанные файлы побайтово с плейсом; `verify_build.py` — что сборка из `src/` даёт те же скрипты с тем же классом и текстом (код выхода 1 при расхождении). `build.rbxl` не коммитится.

## Как заводить новый проект

1. Скопировать плейс-шаблон (`File → Save As` или копия в Creator Hub) и **опубликовать** его: неопубликованный плейс роняет `Monetization` в Play.
2. Скопировать в корень нового проекта `CLAUDE.md`, `.claude/` и `tools/`. Заполнить `CLAUDE.md`, [concept](.claude/docs/concept.md) и [план](.claude/docs/roadmap-to-prototype.md).
3. Проверить `SavesConfig.DataStoreName` и `GetProfileKey`: у второго плейса того же юниверса они обязаны совпадать, а `ServerStorage.ProfileStore` — быть одинаковым.
4. `SavesConfig.KickOnLoadFail`: `true` для игрового плейса, `false` для лобби и меню.
5. Заполнить `DevelopersConfig` UserId разработчиков и тестеров (бесплатные dev-покупки и `/wipe`).
6. Первый свой сервис — новый ModuleScript в `ServerCore` плюс экспорт типа и строка в `ServerTypes.Services`.
7. Запустить проверку документации:

       powershell -NoProfile -ExecutionPolicy Bypass -File tools/documentation/check-agent-docs.ps1
