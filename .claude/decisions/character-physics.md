# Character physics, ragdoll, collisions

## The client does character physics

The client owns its character. A server `AssemblyLinearVelocity` is reset by the owner, and `SetNetworkOwner(nil)` stops the body simulation entirely. Measured: a server push moved the body several times less than the same push from the client.

Split: **the server holds the state and broadcasts the signal, the client builds the pose and the impulse**. `RagdollService` is authoritative on who is down and who is immune; `RagdollController` on how it looks. The signal goes through `FireAllClients`: a local ragdoll does not replicate, so every client builds the pose, and only the owner applies the impulse.

## Ragdoll structure

The rig is the constructive R15: no `Motor6D`; `AnimationConstraint` holds the pose and `BallSocketConstraint` sets the limits. Ragdoll = disable `AnimationConstraint` **except the `Root` joint**, plus `RequiresNeck = false`, `EvaluateStateMachine = false`, support moved from the capsule to the limbs, an anchor for the camera.

`Root` holds `HumanoidRootPart` on `LowerTorso` and has no paired ball socket: disable it and the root part flies alone while the body stays down.

## The previous collision group is remembered

`RagdollController` restores the previous group on stand up, not `Default`: otherwise the character would lose `Character` and every rule tied to it. It is saved **exactly once** — a second enable would store ragdoll values as the originals, and the character would stay in `Ragdoll` forever.

## Groups are registered by code

The template is deployed into an empty place where the Collision Groups editor is empty, and assigning an unregistered group throws — the first `CharacterAdded` would kill `RagdollService`. So `RagdollService:Initialize` runs `CollisionConfig.Groups` and `Rules` through `PhysicsService`. To manage them in the editor, remove the registration and keep the names in the config.

## Everything that is raycast against collides with `Default`

`RaycastParams.CollisionGroup` is `Default`, and a query does not see parts whose group does not collide with it. Moving a water collider into its own group silently killed every water raycast. The `CollisionConfig` matrix turns off exactly one pair — `Ragdoll ↔ Ragdoll`: the limbs pushed against their own torso.
