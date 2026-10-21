# Долги

Только открытое. Закрытый пункт удаляется; причина — в решения, результат — в milestones-done.

## Баги каркаса

- **`Monetization` падает в неопубликованном плейсе**: на загрузке модуля зовёт `DataStoreService:GetDataStore("PurchasesHistory")`, и в Studio без PlaceId ядро пишет `You must publish this place to the web to access DataStore` и `Module Monetization was not loaded`. В опубликованном плейсе не воспроизводится. Решение — получать стор лениво или под `pcall`; пока — опубликовать плейс до первого Play.
- В комментариях части модулей (`ControlsConfig`, `CollisionConfig` и др.) остались ссылки на несуществующий плоский файл граблей; теперь это [pitfalls](../pitfalls/README.md). Править при касании файла.

## Проверить глазами

- Отскок кнопок (`ButtonsInteractionsConnector`) и курсор в третьем лице — в шаблоне не смотрели.
- `KeyBadge` по `PreferredInput` — вызывающего кода нет: проверка на ПК с геймпадом, когда игра заведёт кнопку.
- `ConnectHoldButton` вместе со стиком на телефоне: `InputObject` касания в `InputBegan` кнопки и в `UserInputService.InputEnded` — один и тот же (предположение, машинно не проверено).

## Заглушки шаблона

- `ClickSound`, `HoverSound` без айди и молчат (гвард `SoundPlayer`); айди ставится в инстансе, `SoundConfig.Sfx` дублирует справочно.
- `ToolsConfig.Priority` и `Actions` пусты: ни один тул не берётся в руки, экранной кнопки нет.
- `GamepassesConfig.Attributes`, `DevProductsConfig`, `DevelopersConfig`, `ConflictingGuisConfig` пусты; `Assets.UI.Popups` — только пример `Cash`.
- Иконка и название игры в Creator Hub не заданы.

## Проверить перед релизом

- `SavesConfig.DataStoreName` = `PlayersSavesData`, `KickOnLoadFail` = `true`. Появится второй плейс — общий ключ и одинаковый `ProfileStore` в обоих.
- В день релиза снимается правило «поля сейва без миграций» ([saves-and-monetization](../rules/saves-and-monetization.md)).
