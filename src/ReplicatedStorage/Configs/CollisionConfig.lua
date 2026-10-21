--[[
	Коллизионные группы: имена и матрица.

	В ОТЛИЧИЕ от плейса, откуда взят шаблон, здесь группы заводятся КОДОМ —
	RagdollService:Initialize прогоняет Groups и Rules через PhysicsService.
	Причина простая: шаблон разворачивается в пустой плейс, где редактор
	Collision Groups пуст, а присваивание незарегистрированной группы падает
	с ошибкой. Хочешь вести их редактором — убери регистрацию из сервиса,
	но имена оставь здесь: иначе одну строку будут хранить четыре места.

	Матрица важна не только для физики, но и для РЕЙКАСТОВ:
	RaycastParams.CollisionGroup по умолчанию "Default", и запрос НЕ ВИДИТ
	парты, чья группа с его группой не сталкивается. Отсюда правило:
	всё, по чему рейкастят, ОБЯЗАНО сталкиваться с Default.

	                Default  Character  Ragdoll
	  Default         да        да        да
	  Character       да        да        да
	  Ragdoll         да        да       нет
]]

local CollisionConfig = {}

CollisionConfig.Default = "Default"

--[[ живой персонаж игрока; ставит RagdollService на каждом CharacterAdded ]]
CollisionConfig.Character = "Character"

--[[ сбитый с ног игрок; ставит и снимает ClientCore.RagdollController ]]
CollisionConfig.Ragdoll = "Ragdoll"

--[[ Группы, которые надо создать. Default существует всегда, его тут нет. ]]
CollisionConfig.Groups = {
	CollisionConfig.Character;
	CollisionConfig.Ragdoll;
}

--[[
	Пары, которые НЕ сталкиваются. Всё, чего здесь нет, сталкивается со всем.

	Ragdoll с самим собой: иначе конечности упираются в собственный торс
	и лежачее тело мелко трясёт.
]]
CollisionConfig.Rules = {
	{CollisionConfig.Ragdoll, CollisionConfig.Ragdoll, false};
}

return CollisionConfig
