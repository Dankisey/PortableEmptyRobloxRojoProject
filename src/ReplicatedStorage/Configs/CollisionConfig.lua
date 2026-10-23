--[[
	registered in code by RagdollService: assigning an unregistered group throws in an empty place.
	Raycasts default to the Default group and do not see parts that do not collide with it,
	so everything that is raycast against must collide with Default.

	                Default  Character  Ragdoll
	  Default         yes       yes       yes
	  Character       yes       yes       yes
	  Ragdoll         yes       yes       no
]]
local CollisionConfig = {}

CollisionConfig.Default = "Default"
CollisionConfig.Character = "Character" -- a living player character, set by RagdollService on CharacterAdded
CollisionConfig.Ragdoll = "Ragdoll" -- a knocked down player, set and cleared by RagdollController

CollisionConfig.Groups = {
	CollisionConfig.Character;
	CollisionConfig.Ragdoll;
}

--[[ pairs that do not collide; Ragdoll with itself, or the limbs push against the torso and the body jitters ]]
CollisionConfig.Rules = {
	{CollisionConfig.Ragdoll, CollisionConfig.Ragdoll, false};
}

return CollisionConfig
