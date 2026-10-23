local CameraConfig = {}

--[[ turn on together with StarterPlayer.CameraMode = LockFirstPerson; in third person it must stay off, or the character is always hidden ]]
CameraConfig.FirstPersonVisibility = false

--[[ visible in first person; upper arms are left out because they enter the frame ]]
CameraConfig.VisibleCharacterParts = {
	LeftHand = true;
	RightHand = true;
	LeftLowerArm = true;
	RightLowerArm = true;
}

CameraConfig.ThirdPersonOffset = CFrame.new(3, 3, 4) * CFrame.fromOrientation(math.rad(-15), math.rad(15), math.rad(0))

CameraConfig.ShakingCircle = {
	Duration = 1.2; -- seconds
	Intensity = {
		Min = 2;
		Max = 5;
	}
}

return CameraConfig
