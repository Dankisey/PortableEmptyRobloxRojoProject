local CameraConfig = {}

--[[
	Первое лицо: считать ли прозрачность персонажа самим.

	Включать надо ВМЕСТЕ с StarterPlayer.CameraMode = LockFirstPerson. Штатный
	TransparencyController в первом лице гасит персонаж целиком, вместе с тулом
	в руках, и отключается совсем, как только CameraSubject перестаёт быть
	Humanoid — а именно это делает RagdollCamera. Подробности в CameraController.

	В третьем лице флаг ОБЯЗАН быть выключен: иначе персонаж скрыт безусловно.
]]
CameraConfig.FirstPersonVisibility = false

--[[ Части, которые видно от первого лица. Плечи не входят: лезут в кадр. ]]
CameraConfig.VisibleCharacterParts = {
	LeftHand = true;
	RightHand = true;
	LeftLowerArm = true;
	RightLowerArm = true;
}

CameraConfig.ThirdPersonOffset = CFrame.new(3, 3, 4) * CFrame.fromOrientation(math.rad(-15), math.rad(15), math.rad(0))

CameraConfig.ShakingCircle = {
	Duration = 1.2;
	Intencity = {
		Min = 2;
		Max = 5;
	}
}

return CameraConfig
