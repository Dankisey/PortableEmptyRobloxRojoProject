---
paths: [".claude/docs/ui-principles.md", ".claude/docs/animation-principles.md", ".claude/pitfalls/input-and-ui.md", ".claude/decisions/input-and-ui.md"]
---

# Interface

Input, tools and camera — [input-and-ui](input-and-ui.md). Every interface task is checked against the [UI principles](../docs/ui-principles.md); UI motion also against the [animation principles](../docs/animation-principles.md).

## Before designing

- **Ask the user for a reference** before designing any screen: a screenshot or an example inside a game. Without a reference there is no layout work.
- Fonts are consistent across the project and inside each window: one family per window, at most two weights; a new font is a decision, not a detail.
- All game text is English, including buttons, prompts, errors and item names.

## Layout belongs to Studio

- **The source of truth is a prepared template in Studio.** Code only clones prepared templates (list items, popups, cards) and changes their content: `Text`, `Image`, `Visible`, `LayoutOrder`, state colors. Code never builds GUI with `Instance.new`; the only exception is `UIScale` for animations.
- Static `Position`/`Size`/`AnchorPoint` are never overwritten by code; clones inherit them from the template.
- `Position` and `Size` only in scale, offsets zero.
- **Proportions through `SizeConstraint`** (`RelativeXX` / `RelativeYY`) on the frame itself, not `UIAspectRatioConstraint`; a square is a size in one axis with the matching `SizeConstraint`.
- **Interactive elements are anchored in the center** (`AnchorPoint = 0.5, 0.5`): `UIScale` of the press animation scales from the anchor, otherwise the button slides into a corner. The position is set for this anchor in the layout.
- Buttons never touch the visible edges of their window: keep an inner margin from the window frame.
- A new `ScreenGui` has `ResetOnSpawn = false`. A `GuiController` module without a frame of the same name silently stops creating the rest.

## Buttons

- **A button is empty.** The `GuiButton` itself is transparent, has no text and no image: it exists for input only. All visuals are `Frame`, `ImageLabel` and `TextLabel` children over it with `InputSink = None` (the default) and `Active = false`, so they never take the input ([pitfall](../pitfalls/input-and-ui.md#layout)). The standard structure is `Shadow` (darker frame), `Fill` (colored frame with the gradient) and `Fill.Label`; code changes only `Label.Text` and state colors.
- Every visible button is connected through `ButtonsInteractionsConnector`, even without an action ([input-and-ui](input-and-ui.md)).
- **A purchase button shows its currency in the text:** the Robux glyph or the soft currency sign right inside the label (`"\u{E002} 100"`, `"$ 100"`). The Robux glyph is a Roblox private use character: write it as an escape and check its look in the project font ([pitfall](../pitfalls/input-and-ui.md#layout)). Color follows the currency: green for soft currency, pink for Robux.
- **The "3D" shadow** is a frame under the colored fill, slightly darker than the main color (about 75 % of the dark gradient edge). A `UIGradient` above the shadow multiplies into it and makes the strip almost black: the gradient lives only on the fill.
- A button with states is several buttons of one template switched by `Visible`, and each is connected.

## Lists

- **A wrapped `UIListLayout` (`Wraps = true`) instead of `UIGridLayout`.**
- No spacing settings on lists: no `Padding` on the layout and no `UIPadding`. Spacing comes from the template: a transparent cell larger than the visual block, with the smaller visual block inside. This keeps `AutomaticCanvasSize` correct.
- A list item is a clone of a template from the layout; a list that is rebuilt often disconnects its buttons with `DisconnectButton` ([pitfall](../pitfalls/input-and-ui.md#buttons)).

## Phones

- Phones are the main platform; the game is landscape only. Buttons at least finger sized, nothing important under the stick and the jump button.
- For `UIStroke` read `StrokeSizingMode`, not the thickness.

Before an edit read the [UI principles](../docs/ui-principles.md), [decisions](../decisions/input-and-ui.md) and [pitfalls](../pitfalls/input-and-ui.md).
