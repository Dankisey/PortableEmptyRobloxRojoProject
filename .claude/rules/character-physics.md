---
paths: [".claude/decisions/character-physics.md", ".claude/pitfalls/world-and-physics.md", ".claude/pitfalls/models-and-animations.md", ".claude/docs/animation-principles.md"]
---

# Physics, ragdoll, world, models, animations

- **The client owns character physics.** `RagdollController` does ragdoll and pushes, `RagdollService` holds state, immunity and timer and broadcasts `Ragdoll.StateChanged`. A server push and `SetNetworkOwner(nil)` on the character do not work ([why](../decisions/character-physics.md)).
- Ragdoll disables `AnimationConstraint` **except `Root`**. Order — ragdoll, then an impulse to every body part exactly once, in one frame.
- Collision groups are registered by code from `CollisionConfig`. **Everything that is raycast against collides with `Default`**; before changing a group, check who raycasts against the part.
- Water and ground only through `WorldQuery.RaycastWater` / `RaycastGround`; world folders — `WorldQuery.GetWorldFolder`. Invisible service parts (zones, triggers, boundary walls) have `CanQuery = false`.
- A mechanic that a ragdoll must abort aborts itself on `RagdollService.RagdollStarted`.
- Measure character physics on the client: the server sees a replica.
- Models: `ScaleTo` is absolute, `GetBoundingBox` is pivot based, `WorldPivot` is ignored while `PrimaryPart` is set. Physical debris and temporary instances are limited in count and lifetime by config and swept by a timer: `FallenPartsDestroyHeight` destroys parts, not the model.
- **Every animation is checked against the [animation principles](../docs/animation-principles.md):** name the principles the motion uses and go through the checklist; what only eyes can check goes to `[visual]`. Player response is never traded for a pretty pose.
- Animations: own ones, not from other packs; permanent ones on the client; a non-looped track releases the pose at its end.

Before an edit read [decisions](../decisions/character-physics.md), [world and physics](../pitfalls/world-and-physics.md), [models and animations](../pitfalls/models-and-animations.md).
