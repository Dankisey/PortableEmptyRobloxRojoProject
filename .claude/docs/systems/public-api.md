# Публичное API каркаса

Контракты на йилд здесь обязательны к соблюдению: на них держится выдача покупок ([saves](saves.md#покупки)).

```lua
SavesLoader:IsLoaded(player)            -- сессия профиля активна
SavesLoader:Save(player)                -- НЕ йилдит; false = сессии нет, писать некуда
SavesLoader:RequestSave(player)         -- НИКОГДА не йилдит: можно из обработчика покупки
SavesLoader:WipeSave(player)            -- стирает сейв целиком и кикает; false = сессии нет

Monetization:RegisterProduct(productId, handler)  -- handler НЕ ИМЕЕТ ПРАВА ЙИЛДИТЬ
Monetization:PromptProduct(player, productId) / :PromptPass(player, passId)

RewardService:GiveReward(player, {FunctionName = ..., Data = ...})
SoftCurrencyService:GetCurrency(player, currencyName)          -- -> number?; nil = сейв не загружен
SoftCurrencyService:AddCurrency(player, currencyName, amount)  -- -> boolean; копит и Earned
SoftCurrencyService:TrySpentCurrency(player, currencyName, amount, transactionType, sku?)

RagdollService:Knockdown(player, {Duration, Immunity, Impulse} | duration)
RagdollService:SetRagdoll(player, enabled, impulse)  -- без таймеров, для сцен
RagdollService:IsImmune(player) / :GrantImmunity(player, duration)
RagdollService.RagdollStarted / .RagdollEnded        -- Event

ToolsController:RegisterAction(toolType, onUse, onRelease?)  -- зовёт владелец тула
ToolsController:UseEquippedTool() / :ReleaseEquippedTool()
ToolsController:GetEquippedTool() / :GetEquippedToolType()
ToolsController:SetToolsBlocked(isBlocked) / :AreToolsBlocked()

ButtonsInteractionsConnector:ConnectButton(button, callback, ...)        -- колбэк на нажатии, отскок
ButtonsInteractionsConnector:ConnectHoldButton(button, onPress, onRelease) -- удержание: конец этого же ввода
ButtonsInteractionsConnector:DisconnectButton(button)

KeyBadge.Apply(badge, hint)             -- подпись по UserInputService.PreferredInput; hint — секция ControlsConfig
KeyBadge.Bind(badge, hint)              -- -> RBXScriptConnection; Apply сейчас и на каждой смене PreferredInput

SoundPlayer:PlaySound(soundName, onPart?) -- -> Sound?; пустой SoundId молча пропускается

RagdollController.IsRagdolled           -- ПОЛЕ, не метод
RagdollController:ApplyState(target, enabled, impulse?)  -- поза + блокировка + камера

FormatNumber(value)                     -- 150, 1.38K, 13.8K, 138K: три значащие цифры, отбрасывание
```

Механике, которую рэгдолл обязан оборвать (удержание кнопки, мини-игра), надо подписаться на `RagdollService.RagdollStarted` и оборвать себя самой: сервис о ней не знает.
