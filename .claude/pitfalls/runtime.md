# Engine and runtime

## Framework and start

- **An endless yield in `require` kills the client.** `workspace:WaitForChild("Debris")` at module level hung the `ClientCore` constructor — that is `Uninitialized controllers`. No `WaitForChild` without a timeout at module level; world folders — `WorldQuery.GetWorldFolder(name)`. The same with assets: `Assets:WaitForChild("X")` hangs the core if the folder was moved.
- **The order of handlers of one event is not defined.** One service cleared a "loaded" flag on `PlayerRemoving`, another used it to decide whether to write the save — the write happened every other time. A flag cleared by another handler of the same event cannot be a guard; check state that lives longer than the event.
- **Subscriptions inside a remote handler pile up**: on the third visit one click sent three requests, while the first visit worked perfectly. Subscribe once in `Initialize`; the remote changes only state and `Visible`.
- **Delivery order between different `RemoteEvent`s is not guaranteed.** Pose and impulse in different remotes gave "flies standing". What must apply in order travels in one signal.
- **Server validation must check what is actually used.** The server checked that the model argument was in the registry, and applied the action to the caller's object: the argument changed nothing. Removal from a registry goes through one method, otherwise linked GUI goes out of sync.
- **One completion event per state flag** (`_isRunning`), not by matching result values.

## Character and respawn

- **On respawn the `Backpack` is recreated already filled**, before `CharacterAdded`:
  ```
  3.451  Player.ChildRemoved: old Backpack removed
  3.451  Player.ChildAdded:   new Backpack, children = 1   <- the tool is already inside
  3.452  CharacterAdded
  ```
  `backpack.ChildAdded` never fires — iterate the existing children. There is no `HumanoidRootPart` at that moment, and the `CharacterUtils.GetAlive` guard silently failed the equip: the player stayed without a tool for the session. For `EquipTool` wait for a living `Humanoid`, then check that the character did not change.
- **Recovery paths do not check whether the character is alive**: unanchoring and returning the camera from its anchor must also work on a dead one, otherwise the player stays anchored and the camera on a deleted anchor.
- **A respawn while ragdolled goes through the normal stand up path** (the same knockdown finish method): otherwise there is no `RagdollEnded` and no immunity, and the tool block stays. The block flag is reset on respawn unconditionally.
- **Never wait for the character inside a speed setter** (`CharacterAdded:Wait()` blocks the caller); movement state resets on `CharacterAdded`. A speed recalculation does not turn on movement that a ragdoll turned off.
- **`PlayerScripts.PlayerModule` may not exist**: the default controls live elsewhere ([roblox-studio](roblox-studio.md#input-and-camera-in-studio)). Freeze — `HumanoidRootPart.Anchored`; `WalkSpeed = 0` is overwritten by other writers.
- **Measure character physics on the client**: the server sees a replica. `SpawnLocation` gives a floor at `Y = 1`, `Baseplate` at `Y = 0`.

## Network ownership of objects

- **A client can move an anchored replicated part locally**: the server position did not change, the client one moved by tens of studs. The edit does not replicate, the server does not override it until it writes itself. The server position of such a model is fiction.
- **An object placed by the server is taken back by the server.** After unanchoring, ownership goes to the nearest client, which keeps its own velocity (a thrown item flew off at the throw speed). Order: `Anchored = false` → `SetNetworkOwner(nil)` (if `CanSetNetworkOwnership()`) → zero the velocity. The `SetNetworkOwner(nil)` ban applies only to the character.
- **`AlignOrientation` with the default torque does not hold a large assembly** (`MaxTorque = 10000`, `Responsiveness = 10`): it tilted by tens of degrees. `RigidityEnabled = true` keeps it within a degree.
- **The velocity of rigidly aligned parts cannot be read from `AssemblyLinearVelocity`**: with `RigidityEnabled` alignment it returned 0 at a real speed. Measure speed by the position difference over time.
- **`FallenPartsDestroyHeight` destroys parts, not the model**: the model stays empty, `Destroying` does not fire. Listen to the model and `PrimaryPart`, sweep the registry by a timer.
- **With `StreamingEnabled` a model arrives in parts**: a moving assembly needs `ModelStreamingMode = Atomic`, otherwise the client sees it partly. Far parts may not be loaded at all — logic does not rely on long rays.

## Sound

- **A `Sound` with an empty `SoundId` never ends**: `IsPlaying = true`, `Ended` never fires, the clone lives until the safety `MaxLifetime`. Clones piled up in `workspace` on every cursor hover. Fixed: `SoundPlayer:PlaySound` silently skips a template with an empty `SoundId`.
- **Creator Store recordings differ in loudness**: at one `Volume` a destruction sound was several times quieter than the hit and drowned behind it. Compare the average `PlaybackLoudness` while playing on the client — it measures the recording and **ignores `Volume`**: the result is "recording × Volume", and `Volume` can exceed 1.
- `TimeLength` is 0 before loading — lifetime does not rely on it. Templates are preloaded, otherwise the first click sounds late.
- Positional SFX: the server broadcasts the name and a `BasePart`, every client plays a local clone.

## Other

- **`TeleportService` in Studio always fails** with `Request Context Failure` — normal.
- **`GetPlayerByUserId` in a chat handler may return `nil`**: the author left, and an error in a `TextChatService` handler breaks delivery for everyone. The guard is required.
- **Team Create does not sync different places** of one universe: shared code is mirrored by hand with a `.Source` check.
