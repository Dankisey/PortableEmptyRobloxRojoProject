# Framework public API

The yield contracts here are mandatory: purchase delivery depends on them ([saves](saves.md#purchases)).

```lua
SavesLoader:IsLoaded(player)            -- the profile session is active
SavesLoader:Save(player)                -- does not yield; false = no session to write to
SavesLoader:RequestSave(player)         -- never yields: allowed in a purchase handler
SavesLoader:WipeSave(player)            -- wipes the whole save and kicks; false = no session

Monetization:RegisterProduct(productId, handler)  -- the handler MUST NOT YIELD
Monetization:RegisterPass(passId, handler)        -- after a pass purchase and on a free developer purchase; ownership on join is read by the owner
Monetization:PromptProduct(player, productId) / :PromptPass(player, passId)
Monetization:AreDeveloperPurchasesEnabled()       -- -> boolean; the module attribute DeveloperPurchasesEnabled
Monetization:SetDeveloperPurchasesEnabled(isEnabled)  -- server wide, resets to false on a new server
Monetization:GetDeveloperPurchasesChangedSignal() -- -> RBXScriptSignal

RewardService:GiveReward(player, {FunctionName = ..., Data = ...})
SoftCurrencyService:GetCurrency(player, currencyName)          -- -> number?; nil = save not loaded
SoftCurrencyService:AddCurrency(player, currencyName, amount)  -- -> boolean; also adds to Earned
SoftCurrencyService:TrySpendCurrency(player, currencyName, amount, transactionType, sku?)

RagdollService:Knockdown(player, {Duration, Immunity, Impulse} | duration)
RagdollService:SetRagdoll(player, enabled, impulse)  -- no timers, for scenes
RagdollService:IsImmune(player) / :GrantImmunity(player, duration)
RagdollService.RagdollStarted / .RagdollEnded        -- Event

ToolsController:RegisterAction(toolType, onUse, onRelease?)  -- called by the tool owner
ToolsController:UseEquippedTool() / :ReleaseEquippedTool()
ToolsController:GetEquippedTool() / :GetEquippedToolType()
ToolsController:SetToolsBlocked(isBlocked) / :AreToolsBlocked()

CharacterMovementController:EnableMovement() / :DisableMovement()
CharacterMovementController:RefreshSpeed()  -- recalculates speed only while movement is enabled

ButtonsInteractionsConnector:ConnectButton(button, callback, ...)        -- callback on press, bounce
ButtonsInteractionsConnector:ConnectHoldButton(button, onPress, onRelease) -- hold: the end of the same input
ButtonsInteractionsConnector:DisconnectButton(button)

KeyBadge.Apply(badge, hint)             -- label by UserInputService.PreferredInput; hint is a ControlsConfig section
KeyBadge.Bind(badge, hint)              -- -> RBXScriptConnection; Apply now and on every PreferredInput change

SoundPlayer:PlaySound(soundName, onPart?) -- -> Sound?; an empty SoundId is silently skipped

RagdollController.IsRagdolled           -- a FIELD, not a method
RagdollController:ApplyState(target, enabled, impulse?)  -- pose + blocking + camera

FormatNumber(value)                     -- 150, 1.38K, 13.8K, 138K: three significant digits, truncation
```

A mechanic that a ragdoll must abort (a button hold, a mini game) subscribes to `RagdollService.RagdollStarted` and aborts itself: the service does not know about it.
