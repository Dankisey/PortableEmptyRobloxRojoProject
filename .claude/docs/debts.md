# Debts

Open items only. A closed item is deleted; its reason goes to decisions, its result to milestones-done. The intentionally empty parts of the template are listed in the [code map](systems/code-map.md#empty-on-purpose), the release checklist is in the [project README](../../README.md#before-release).

## Check by eye

Machine checks are done; these need a human in Play.

- Button bounce (`ButtonsInteractionsConnector`) and the cursor in third person.
- A press through the visual children of an empty button reaches the button with mouse, touch and gamepad (`InputSink = None` on the visuals).
- The admin panel: visible only to a developer, `AddCash` adds, `Reset` asks for a second press then wipes and kicks, `FreePurchases` switches the label, the color and the purchase flow.
- The restyled confirmation prompt, tooltip, messages and world prompts read well on a phone in landscape.
- `KeyBadge` by `PreferredInput` has no caller: check on a PC with a gamepad when a game adds a button.
- `ConnectHoldButton` together with the stick on a phone: the touch `InputObject` in the button's `InputBegan` and in `UserInputService.InputEnded` is assumed to be the same object.
