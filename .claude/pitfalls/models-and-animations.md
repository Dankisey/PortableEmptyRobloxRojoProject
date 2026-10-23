# Models and animations

Every animation is also checked against the [animation principles](../docs/animation-principles.md).

## Model geometry

- **`Model:ScaleTo` is absolute**: `ScaleTo(.667)` sets the scale from the original geometry and erases the previous one. Multiply: `model:ScaleTo(model:GetScale() * scale)`.
- **`BasePart.ExtentsSize` equals the local `Size`** and ignores rotation (a cylinder turned axis up had "height" 10 instead of 0.2 — objects sank into the ground). Compute world height by axes: `|Right.Y|·X + |Up.Y|·Y + |Look.Y|·Z`.
- **`Model:GetBoundingBox` measures by the pivot**, not the world: for a turned model "lies or stands" is wrong by it. Compute height by part corners in the world; a doubtful conclusion — by a screenshot.
- **`Model.WorldPivot` is ignored while `PrimaryPart` is set**; `PivotTo` works in the pivot space, and the pivot may be turned and shifted relative to `PrimaryPart` (some pack models had a 90° turn). Account for it in a placement utility.
- **The `PrimaryPart` of pack models is a transparent 1×1×1 cube**, the rig assembly point. Move it to the most massive part among the **direct** children: a search over descendants finds accessories.
- **`PrimaryPart` replicates separately from the model**: a client `ChildAdded` sees the model with `PrimaryPart = nil` while streaming and on join spawns. Wait plus a fallback to the first `BasePart`.
- **Collision and mass are carried by an invisible box**, not the visible part: an almost cubic part freezes in any orientation. Compute the size in the reference part space, not `GetExtentsSize`.
- **`WeldConstraint` returns the part to the remembered place**, while `Size` changes honestly — recreate the weld after an edit.
- **A weld outside `Workspace` does not move the welded part**: checking a pose on a clone outside the world gives a false angle. Check only joint parts.
- **A welded model in `Workspace` is a rigid assembly**: the `CFrame` of one part moves everything instead of bending a joint. Compute numbers on a clone outside `Workspace`, the picture with a real `Animator` in the world.
- **A model moved into an asset subfolder is silently lost by a hard path.** Search `Assets:FindFirstChild(name, true)` by a name from the config. The asset folder name differs from the world one, otherwise cleanup removes the templates.
- **Preview in a `ViewportFrame`**: center by the bounding box, distance from the field of view:
  ```lua
  local boundingCFrame, size = model:GetBoundingBox()
  model:PivotTo(CFrame.new(-boundingCFrame.Position) * model:GetPivot())
  local distance = size.Magnitude * .5 / math.tan(math.rad(camera.FieldOfView) * .5) * 1.2
  ```

## Imported meshes

- **A skinned model of several meshes comes with an invisible `RootPart`**: the importer adds a transparent `Part` with `Motor6D`s to the meshes, its bottom below the visible feet. A size over all parts lifted the model above the ground. Compute placement size without parts with `Transparency >= 1`; check — the bottom of the visible mesh is on the ground.
- **Vertices without weights in a skinned mesh stretch a thread across the scene**: a couple of unweighted vertices drew a black thread tens of studs long. Give such vertices the weights of the nearest bound vertex in the export script if they are a tiny share of the mesh; almost unbound meshes are rigid parts and stay as is. Check — the count of zero weight vertices in the export and the model look.
- **Vertex colors multiply by `MeshPart.Color`**: the import sets the default grey, and every vertex colored model looked a third darker than the source. Set `Color` to white in the builder; check — no `MeshPart` with the grey `Color` and a frame next to a copy on white.

## Tool in hand

- **`Tool.Grip` positions the `Handle`**, and the `Handle` center is offset differently in different models — compute the grip:
  ```lua
  -- Handle = GripPoint * Grip:Inverse();  Body = Handle * BodyOffset
  tool.Grip = bodyOffset * target:Inverse()
  ```
  Check: `GripPoint * Grip:Inverse() * BodyOffset == GripPoint * Target`, residual 1e-6. A move into a `Tool` takes only direct children.
- **The handle of a generated mesh is off the bounding box center**: it was tilted and offset at the grip point — the hand hung next to the handle. Compute `Grip` along the handle axis from vertices: `AssetService:CreateEditableMeshAsync(Content.fromUri(MeshId))`, centers of slices in the lower part of the height, a regression, `Grip = CFrame.fromMatrix(point, right, axis)`.
- **Two-handed grip poses are found by calculation, not by eye**: a dozen angles tried blindly never converged. Forward kinematics of the constructive rig — `Part1 = Part0 * Att0.CFrame * Pose.CFrame * Att1.CFrame:Inverse()` over `*RigAttachment` matched the live pose to 1e-4; right arm angles — coordinate descent toward the hand position and the tool direction, checking that the left hand can reach the handle end.
- **A fast hit of two keys breaks the arc**: a recorded path of the tool head showed the hit in a few frames with tens of degrees of turn per frame, the windup eaten by the transition, a near half turn after the hit. Arc and timing are functions, keys go on every frame (1/60 s, `Linear`), joints are solved frame by frame with a warm start from the previous frame. Check — the tip path by frames: the turn changes smoothly.
- **A `Trail` on a fast hit is a polygon**: a point is placed once per frame. A smooth trail is a Catmull-Rom spline through frame points made of `Beam`s: attachments with the X axis along the tangent, `CurveSize0/1 = |tangent| / 3`. Attachments in `workspace.Terrain` take world `CFrame`s.
- **A leg crouch in a running hit animation gives sliding**: legs go on a separate higher priority track and only when `Humanoid.MoveDirection` is near zero. The crouch is a `LowerTorso` shift down in the `Root` pose, feet stay in place by solving leg angles.
- **`IKControl` on a rig with `AnimationConstraint` works**, but does not reach fully: the hand stays a fraction of a stud from the target and bends the arm at unnatural angles — arms are solved with keys instead.
- **Hands at the chest fold an R15 arm into a lock**: a small radius arc of the hands gave sharp elbow angles and the forearm inside the shoulder. From the shoulder joint to the grip point of the reference R15: elbow 0° — 1.94, 60° — 1.70, 80° — 1.53, 100° — 1.33 studs. Keep the grip about 1.5 studs from the shoulder, the elbow up to 100° and below the shoulder–hand line.
- **A grip given only by the handle direction spins the tool around it**: the solver picked a rotation for wrist comfort, and the head went across the arc. Keep the head axis along the arc tangent as a separate goal; check — the angle between the head axis and the tip motion by frames.
- **Parts of the reference R15 arm render in the shoulder color**: the forearm and hand `Color` changes, the screen shows the shoulder color. To inspect a pose — a `Highlight` with `FillColor` on each part.
- **A `Grip` without rotation stands a long item upright**: the R15 `RightGripAttachment` has `LookVector = (0, -1, 0)`. The sign — by the tip position in the root part space.
- **The reference rig lies about the grip orientation**: `CreateHumanoidModelFromDescription` gives a `Motor6D` rig, while the framework character is the constructive R15 on `AnimationConstraint`. Try orientations on a live tool in Play with a probe; the reference is good for position.
- The constructive rig chain: `Part1.CFrame = Part0.CFrame * Attachment0.CFrame * Pose * Attachment1.CFrame:Inverse()`; there is no `Motor6D`. Raising an item — `atan2(axis.Y, -axis.Z)` by the handle `UpVector`; R15 holds an item with two hands only approximately.

## Animations

- **A server `Animator` replicates the command, not the track state**: an animation started before a player joined never reaches them. In Studio it works (the player is connected before `Initialize`), live — a pole. Permanent ones on the client, state as an attribute.
- **`Enum.PoseEasingStyle` has only `Linear`, `Constant`, `Elastic`, `Cubic`, `Bounce`, `CubicV2`**: there is no `Quad`, and the error in a keyframe table constructor breaks the whole call. A pose style sets the transition **out of** it into the next keyframe.
- **A short hit without a snap at the end**: a non-looped track releases the pose instantly on the last frame — freeze it with `AdjustSpeed(0)` and fade it out with `Stop(fade)`; the next `Play(fade, 1, 1)` restores the speed.
- **A non-looped track releases the pose at its end.** To hold a pose — a looped clip in the already taken pose plus `track:Play(fadeTime)`: the fade is the windup. A finished death track puts the corpse into a stance for a moment.
- **A looped clip shorter than its phase plays its exit in the middle of it**: the loop holds the state on all frames, entry and exit are track fades.
- **Other people's animations do not play**: `LoadAnimation` without an error, the model stands. They cannot be extracted (`GetKeyframeSequenceAsync` — 0 frames, `GetAnimationClipAsync` — `failed to load`). Own freshly published ones also returned 0 frames several times in a row: check with `LoadAnimation` + `Play` and the track length. A cold cache: the first call fails by timeout. Objects from `KeyframeSequenceProvider` are not `Destroy()`ed.
- **Own published animations do not play in Edit but can be read**: `LoadAnimation` by `rbxassetid` in Edit gives `Length = 0`, while `GetKeyframeSequenceAsync` returns the keys — compare the published one with the local one by them. After such attempts the test rig `Animator` stopped loading local tracks too — recreate the `Animator`. Check playback in Play.
- **`RegisterKeyframeSequence`** returns a bare hash (32 hex) — put it into `AnimationId` as is, `hash://` fails. In Edit move tracks with `animator:StepAnimations(dt)` on `Heartbeat`; `StepAnimations(0)` does not bring the weight to 1 — make several steps and check `WeightCurrent == 1.00`. `AnimationTrack.Length` right after `LoadAnimation` is 0.
- **An anchored part is not moved by `Motor6D`**: the track plays, `WeightCurrent = 1.00`, the model stands. Anchor only the rig root (a part that is no joint's `Part1`), the rest `Massless`, `CanCollide = false`.
- **A model can lose its `Animator`** — "one model does not work". `FindFirstChildWhichIsA("Animator", true)`, otherwise a warning.
- **`BreakJointsOnDeath`** breaks the rig on the death animation — `false`.
- **An animation never drops the root**: the `Humanoid` owns it. The server drops it (`PlatformStand`, anchor, `TweenPivot`), the animation only goes limp.
- **Skinned models animate by bones** (`HasSkinnedMesh`): `Pose` by `Bone` names, the root `Pose` name = the name of the part owning the bones. Measure by `Bone.Transform`. `Pose.CFrame` equals `Bone.Transform`, and the Animator finds a pose by the bone name under any chain above the bone tree. Check a clip before publishing with `KeyframeSequenceProvider:RegisterKeyframeSequence` on a client copy, positions — `Bone.TransformedWorldCFrame`.
- **A `Pose` with `Weight = 0` is left out of blending** — that is how partial clips over a base loop are built. A generator that puts `identity` everywhere resets the base. Two clips of one priority are switched by hand.
- **Keyframe optimization** drops repeating poses — a `Keyframe` walk is incomplete; check by playback (`TimePosition` + sampling).
- **Publishing animations**: `AssetService:CreateAssetAsync` in Studio — `not available yet`, there is no `plugin` in `execute_luau`. The working path — `.rbxmx` by code and Open Cloud `POST https://apis.roblox.com/assets/v1/assets` with a key the human creates and keeps; keys never enter the project, documents or chat. A lost response — do not repeat the POST blindly.
- A pose is "baked" into a joint `C0` (`C0' = C0rest * Pose`) remembering the rest pose, otherwise a second run multiplies again.
- A pose from the Animation Editor is read straight from `Bone.Transform` (precision 1e-7), but the editor has no ground — press it down by calculation.

## Small parts disappear from a distance

Symptom: voxel models made of small parts "crumble" from a medium distance — some bricks are not drawn, grass shows through the holes of a hollow box; large parts of older models are fine. Reproduces in Edit too.

Cause — the engine does not draw parts that are small on screen, and the distance depends on the graphics level ([DevForum](https://devforum.roblox.com/t/all-parts-disappearing-at-graphics-level-1/2300988)); the exact rules need a check in the current Roblox documentation. Streaming is not involved: the models are client side.

Fix: in a whole object voxels are merged into large bricks, a closed cavity is filled, pieces for breaking are a separate model. Check — a frame from that distance: boxes without holes.
