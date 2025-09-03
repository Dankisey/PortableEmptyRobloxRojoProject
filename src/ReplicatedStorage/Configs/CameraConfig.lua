local CameraConfig = {}

CameraConfig.ThirdPersonOffset = CFrame.new(3, 3, 4) * CFrame.fromOrientation(math.rad(-15), math.rad(15), math.rad(0))

CameraConfig.ShakingCircle = {
    Duration = 1.2;
    Intencity = {
        Min = 2;
        Max = 5;
    }
}

return CameraConfig