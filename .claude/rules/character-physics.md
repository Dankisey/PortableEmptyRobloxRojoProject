---
paths: [".claude/decisions/character-physics.md", ".claude/pitfalls/world-and-physics.md", ".claude/pitfalls/models-and-animations.md"]
---

# Физика, рэгдолл, мир, модели

- **Физикой персонажа владеет клиент.** Рэгдолл и толчки делает `RagdollController`, `RagdollService` держит состояние, иммунитет и таймер и рассылает `Ragdoll.StateChanged`. Серверный толчок и `SetNetworkOwner(nil)` не работают ([почему](../decisions/character-physics.md)).
- Рэгдолл выключает `AnimationConstraint` **кроме `Root`**. Порядок — рэгдолл, затем импульс всем частям тела ровно один раз, в одном кадре.
- Коллизионные группы заводит код из `CollisionConfig`. **Всё, по чему рейкастят, сталкивается с `Default`**; перед сменой группы проверь, кто по парту рейкастит.
- Вода и земля — только `WorldQuery.RaycastWater` / `RaycastGround`; папки мира — `WorldQuery.GetWorldFolder`.
- Механику, которую рэгдолл обязан оборвать, обрывает она сама по `RagdollService.RagdollStarted`.
- Физику персонажа мерь на клиенте: сервер видит реплику.
- Модели: `ScaleTo` абсолютный, `GetBoundingBox` — по пивоту, `WorldPivot` игнорируется при `PrimaryPart`. Физические обломки и временные инстансы ограничены числом и временем жизни из конфига и подметаются по таймеру: `FallenPartsDestroyHeight` уничтожает парты, а не модель.
- Анимации: свои, не из чужих паков; постоянные — на клиенте; незацикленный трек по окончании отпускает позу.

Перед правкой прочитай [решения](../decisions/character-physics.md), [мир и физику](../pitfalls/world-and-physics.md), [модели и анимации](../pitfalls/models-and-animations.md).
