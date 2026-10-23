# World, raycasts, physics

## Collision groups and raycasts

- **A collision group filters raycasts, not only collisions.** `RaycastParams.CollisionGroup` = `Default`, and a query does not see parts whose group does not collide with it; `CanCollide` is irrelevant. Moving the water collider into its own group (`↔Default = false`) silently killed the water raycast and server validation: `nil` read as "no water". Everything that is raycast against collides with `Default`.
- **An unregistered group throws on assignment** — that is why code registers the groups.
- **Water and ground only through `WorldQuery`.** In the framework water is parts tagged `WorldConfig.WaterTag`; `RaycastGround` excludes them. Without water `RaycastWater` honestly returns `nil`. Never build `RaycastParams` by hand: copies drift apart in their filters.
- **A ray must exclude itself and every living character.** A ray from the model's own pivot hits the model, and all measurements shift by one value while staying consistent. An NPC stood on a character's head. Rebuild the exclusion list once per tick.
- **A ground ray respects `CanCollide`**, otherwise grass gives a support several studs too high.
- **Invisible service parts** (zones, triggers, boundary walls) have `CanQuery = false`, otherwise they become "ground". A project that needs a sensor to see them records it as a decision.
- **A ray from above hits rough mesh hulls** (`CollisionFidelity = Default`) well above the floor. A support ray starts from the feet plus the allowed step.
- **A ray starting inside a mesh finds nothing**, and the code reads "nothing" as "empty/water". A "what is here" ray starts above the whole map.
- **A ray hitting a vertical face gives a near vertical "floor"**: at a terrain edge alignment rays hit the side face and the object slid down along the wall. A normal steeper than the allowed slope is not a floor; map edges get invisible boundaries.
- **Logic does not depend on the name of a part that may disappear in a `Union`.** Acceptance is defined by a zone, the ray is only cosmetic.
- **"Time to call" and "this is the target" are one function**, otherwise the called one leaves at once.

## Building the map

- **A part is at most 2048 studs** on any axis: a long floor and walls are built from pieces.
- **A 180° turn is not a mirror**: a turned decor block repeats the left side backwards. An exact mirror around x = 0 is an inversion of `CFrame` components: `CFrame.new(-x, y, z, r00, -r01, -r02, -r10, r11, r12, -r20, r21, r22)`; textures swap `Left`↔`Right` faces. Asymmetric meshes (wedges, unions) mirror only approximately.
- **Measure decor size by part corners**, not centers: by centers a decor block looked about half as wide as by corners, and it did not fit.
- Editing a map the human edits in parallel — take a fresh snapshot first: a snapshot from before their edits leads to wrong conclusions.

## Ragdoll

- **The ragdoll pose does not replicate**: disabled `AnimationConstraint`s live on one client, the server rig is rigid. A server velocity moves "one part", the player stands. `SetNetworkOwner(nil)` makes it worse. Everything that moves the character physically lives on the client.
- **Order**: ragdoll first, then the impulse, in one frame — otherwise the character flies standing. The velocity goes to **every body part** exactly once: joints are constraints, each part is its own assembly; holding the velocity for several frames gives a board flight.
- **`EvaluateStateMachine = false`**, otherwise the `Humanoid` stands up every frame. Removing the root part collision is not enough — limbs fall through; support on the limbs and the `Ragdoll` group are needed.
- **Body orientation in physics goes through `AlignOrientation`**, not the root part `CFrame` (jitter with the joints). The loop has one exit, otherwise `AlignOrientation` stays hanging. The final anchor is set by the server: `Anchored`, then `CFrame`.

## Physical debris and temporary objects

- Count and lifetime come from the config; sweep by a timer, not only by an event (`FallenPartsDestroyHeight` kills parts, not the model).
- An object released from anchoring by the server — `SetNetworkOwner(nil)` and zero velocity ([runtime](runtime.md#network-ownership-of-objects)); otherwise the nearest client simulates it.
- A client can move a replicated part locally — client cosmetics are built on that, but the server never sees that position.

## NPC and pathfinding

- **Points for `ComputeAsync` must stand on support** (+1 stud), otherwise `NoPath` even on a flat floor.
- **`AgentCollisionGroupName` does not change the path**; `PathfindingModifier.PassThrough` works only if it is there before the navmesh is built.
- **A body right next to the agent gives `NoPath`**: turn off `CanCollide` of a carried object, move the start, try targets around.
- **`Costs` do not apply to the fallback `MoveTo`** — the terrain ban lives in the target itself. An empty waypoint list must not trigger a repath.
- **Distances to a target include half sizes of both bodies**: a large model does not drive into the center of another.
- **A zero direction means "do not turn"**, not `-LookVector`. "A step above zero" is not movement: a dead zone for the step and a speed threshold by actual displacement.
- **An emergency exit must move** (try directions), otherwise "stay because you stand badly" is an eternal trap; plus a stuck timer.
- **Splicing paths** "new to the end of the old" is right only for a standing agent.
