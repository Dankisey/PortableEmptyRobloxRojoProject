# UI principles for games

Required check for every interface task, next to the [ui rule](../rules/ui.md). Three sets cover three questions: is the interface usable (Nielsen), does its motion help (UX in Motion), does it serve the player's brain and the fun (Hodent). User decisions override this advice.

## Nielsen: 10 usability heuristics

The classic set for any interface; rules of thumb, not strict laws.

| Heuristic | Meaning | In a Roblox game |
|---|---|---|
| Visibility of system status | The player always knows what is happening | A press reacts in the same frame; loading shows `...`, never a fake `0`; timers and cooldowns are visible |
| Match with the real world | Familiar words, icons and order | Genre conventions: Robux glyph on paid buttons, shop on the left, close at the top right |
| User control and freedom | An easy exit from a wrong step | Every window closes with one tap; destructive actions need a second press |
| Consistency and standards | Same thing looks and works the same | One font family per window, one button template, one color per currency across the project |
| Error prevention | Design so mistakes do not happen | Disable what cannot be bought, confirm spending, keep buttons away from the stick and the jump button |
| Recognition rather than recall | Show options instead of making players remember | Icons with labels, current state on the button itself, no hidden gestures |
| Flexibility and efficiency | Shortcuts for experienced players | Keys and gamepad buttons next to touch buttons, `KeyBadge` labels by `PreferredInput` |
| Aesthetic and minimalist design | Every extra element competes with the important one | HUD shows only what the current loop needs; secondary info goes to windows |
| Recognize, diagnose, recover from errors | Errors are plain and suggest a fix | "Not enough Cash: need 120 more" instead of "Error" |
| Help and documentation | Help is short and in context | A first time hint near the element, not a manual |

## UX in Motion: 12 principles of interface motion

Motion as behavior that supports usability, not decoration. All motion eases.

| Group | Principle | Meaning | In Roblox |
|---|---|---|---|
| Timing | Easing | Natural acceleration and braking | Every `TweenInfo` has an `EasingStyle`; `Linear` only for loops |
| Timing | Offset and delay | Staggered elements show hierarchy | List items appear one after another with a small delay from config |
| Relationships | Parenting | Child elements move with their parent | A window opens as one group: children scale with the parent `UIScale` |
| Continuity | Transformation | One element turns into another | A buy button turns into "Owned" in place instead of a new popup |
| Continuity | Value change | Numbers change visibly | Currency counters count and pop on change |
| Continuity | Masking | Showing and hiding parts of an element | `ClipsDescendants` frames for progress bars and reveals |
| Continuity | Overlay | Elements slide over each other | A new popup slides over the old one, which is removed on `Completed` |
| Continuity | Cloning | New elements grow out of an existing one | A reward icon flies from the button to the counter |
| Spatial | Obscuration | A layer dims what is behind it | A dark overlay behind a modal window |
| Hierarchy | Parallax | Layers move at different speeds | Background decorations of a window move slower than its content |
| Spatial | Dimensionality | Elements have depth and a direction of origin | Windows enter from where they were opened |
| Spatial | Dolly and zoom | Moving into and out of a space | Opening a section zooms into it instead of a hard cut |

## Hodent: game UX

The game frame on top of the general rules: usability (can the player use the game, given limits of perception, attention and memory) and engage-ability (is it fun and engaging).

**Usability pillars**

| Pillar | Meaning | In a Roblox game |
|---|---|---|
| Signs and feedback | Cues inform about state, invite an action and react to it | Every press has sound and motion; reward events have visible and audible feedback |
| Clarity | Information is easy to perceive and understand | Readable fonts on a phone, high contrast, no text over busy backgrounds |
| Form follows function | The look of an element tells how to use it | Buttons look pressable, a progress bar looks like progress |
| Consistency | The same rules everywhere | One button template, one place for close, one color per currency |
| Minimum workload | Least memory and attention needed | Few elements at once, short texts, no reading during action |
| Error prevention and recovery | Mistakes are hard to make and easy to undo | Confirm destructive actions, keep the previous state reachable |
| Flexibility | Players adapt the game to themselves | Settings for sound and controls when the game grows |

The first three pillar names are confirmed by the book's table of contents; the exact names and wording of the rest need a check in the book (chapter 11).

**Engage-ability pillars:** motivation (clear goals, competence, autonomy), emotion (game feel, discovery, surprise), game flow (difficulty and learning curves that keep the player between boredom and frustration). For an audience with children: no pressure, no misleading purchase wording.

## Checklist

- There is a reference from the user, and the screen matches it.
- Every interactive element gives feedback in the same frame; loading states are visible.
- One font family per window, one button template, currency shown in every purchase button.
- Every window closes in one tap; destructive actions need a second press.
- The screen reads on a phone in landscape: finger sized buttons, nothing under the stick and the jump button.
- Motion eases, has a reason (relationship, continuity, hierarchy) and never delays the result.
- In the report: which principles the screen relies on; readability and feel go to `[visual]`.

## Sources

- [10 Usability Heuristics — Nielsen Norman Group](https://www.nngroup.com/articles/ten-usability-heuristics/); summaries: [The Decision Lab](https://thedecisionlab.com/reference-guide/design/nielsens-heuristics), [ICS](https://www.ics.com/uxd/resources/nielsen)
- [Creating Usability with Motion: The UX in Motion Manifesto — UX Magazine](https://uxmag.com/articles/creating-usability-with-motion-the-ux-in-motion-manifesto) (Issara Willenskomer); [Adobe blog](https://blog.adobe.com/en/publish/2016/11/08/redesigning-the-12-principles-of-animation-for-motion-design)
- [The Gamer's Brain — Celia Hodent](https://thegamersbrain.com/); [summary of the usability framework](https://medium.com/design-bootcamp/finding-a-framework-for-ux-in-gaming-key-takeaways-for-understanding-usability-in-celia-hodents-9c0fcfee85f7); [GDC talk on engagement](https://celiahodent.com/gamers-brain-part-3-ux-engagement-immersion-retention-gdc17-talk/)
