# 12 animation principles in games

Required check for every animation: character tracks (`Animator`, `KeyframeSequence`), procedural motion (`TweenService`, `RenderStepped` code), camera moves and UI motion. The principles come from Thomas and Johnston, "The Illusion of Life" (1981); the game reading comes from the sources below. User decisions override this advice.

The main difference from film: the player controls the camera and the timing of actions. Input or interruption can stop an animation at any moment, and it must read from every angle and on a small phone screen.

| Principle | Meaning | In games | In Roblox |
|---|---|---|---|
| Squash and stretch | Shape changes with impact and speed while keeping volume | Rigs rarely scale bones; extended limb poses fake stretch. Strength follows the style | R15 parts are not scaled; stretch through reaching poses, crouch before jumps and on landing. UI: a short `UIScale` squeeze on press, overshoot on release |
| Staging | Present an action so it is understood | The player owns the camera: staging moves into the pose silhouette and level design; full staging only in cutscenes | The action reads from the side and from above in third person; the held tool does not hide behind the body |
| Anticipation | Preparation shows direction, force and size | Player actions need a short windup or input feels sluggish; enemies use long readable telegraphs | Player windups are a few frames; long telegraphs only for big threats, through poses and ground markers |
| Straight ahead and pose to pose | Draw sequentially, or set key poses and in-betweens | Games use pose to pose: states, transitions, runtime changes | Key poses in the Animation Editor or `KeyframeSequence`, transitions through track fades |
| Follow through and overlapping action | Parts stop at different times; motion continues after the main action | Follow through never blocks input: control returns on time, the tail blends into the next action. Plan its interruption | Hold and release phases of a hit, secondary parts (cape, tail, hair) on their own track or constraint; a tool hold must end on every exit path |
| Slow in and slow out | Acceleration and braking add weight | Heavy easing in the active phase reads as delay; weight goes to follow through, not to the strike start | `EasingStyle` per tween; in `KeyframeSequence` the pose easing sets the transition out of that pose. Fast strike, weight in recovery |
| Arcs | Living motion follows curves | Straight paths look mechanical, perfectly smooth ones float; a sharp break adds force | Check the path of the hand or tool tip frame by frame; it must not pass through the body |
| Secondary action | Supporting motion strengthens the main one | Extra layers live longer and must blend with every state; secondary physics costs frame time on phones | Breathing, head turn, cloth on separate low priority tracks; limit physics constraints by config |
| Timing | Frame count gives weight and character | Timing defines reaction windows and input feel. Practitioner guideline: 50–200 ms response, 0.5–2 s for a dramatic action | Press feedback in the same frame as input; durations live in configs, not literals |
| Exaggeration | Motion exceeds real life | Needed for readability from the game camera; one scale across the project | Bold poses and UI pops readable on a phone; the same exaggeration for every character and screen |
| Solid drawing | Shape and volume work from every angle | In 3D this is body mechanics: balance, center of mass, support | Feet under the center of mass, hands outside the torso, head over support |
| Appeal | The character is clear and interesting | A clear silhouette and character in stance and gait, seen thousands of times | Idle and walk carry the character, not only rare attacks |

## Checklist

- Never trade player response for cosmetics: a pretty slow pose is worse than an immediate one.
- Enemy telegraphs read before damage from every side and under network latency.
- Action tails stop without a snap on a new action, an interruption, a ragdoll or death.
- Support and center of mass are right: on one leg, the supporting foot is under the body.
- Arcs do not cross the torso; visuals match hitboxes.
- A side windup turns hips together with shoulders.
- A grabbing or holding hand reaches the object; a gap is worse than a stretch.
- Secondary motion follows its support and returns to rest without accumulating rotation.
- UI motion: the press reacts in the same frame, the element scales from its center anchor, and the animation never hides the result the player waits for.
- In the report: the principles used and how; what only eyes can check goes to `[visual]`.

## Sources

- [The 12 principles of animation in video games — Game Developer](https://gamedeveloper.com/production/the-12-principles-of-animation-in-video-games) (Jonathan Cooper, "Game Anim")
- [The 12 Principles of Animation, Reframed for Games — anim.works](https://anim.works/?p=23056)
- [12 principles for game animation — Game Developer](https://www.gamedeveloper.com/blogs/12-principles-for-game-animation)
- [Applying traditional animation principles to 3D games — Theseus](https://www.theseus.fi/handle/10024/138930)
