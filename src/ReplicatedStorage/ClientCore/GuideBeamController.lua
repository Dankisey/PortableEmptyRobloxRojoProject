local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local BeamAsset = ReplicatedStorage.Assets.GuideBeam
local DebrisFolder = workspace:WaitForChild("Debris")

local GuideBeamController = {}

local function createEmptyPart(position: Vector3) : Part
    local part = Instance.new("Part")
    part.Position = position
    part.Size = Vector3.one
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Transparency = 1
    part.Anchored = true
    part.Name = "BeamPart"
    part.Parent = DebrisFolder

    return part
end

local function destroyBeam(self, category: string, isSavingTarget: boolean?)
    self._currentBeams[category].Beam:Destroy()

    if not isSavingTarget then
        self._currentBeams[category].Target:Destroy()
    end

    self._currentBeams[category].RootPartAttachment:Destroy()
    table.clear(self._currentBeams[category])
    self._currentBeams[category] = nil
end

local function createNewBeam(self, category: string, targetPosition: Vector3?, reachDistance: number?, targetPart: Part?)
    self._currentBeams[category] = {}
    self._currentBeams[category].ReachDistance = reachDistance or 10

    self._currentBeams[category].RootPartAttachment = Instance.new("Attachment")
    self._currentBeams[category].RootPartAttachment.Parent = self._rootPart
    self._currentBeams[category].RootPartAttachment.Position = Vector3.zero

    if targetPart then
        self._currentBeams[category].Target = targetPart
    else
        self._currentBeams[category].Target = createEmptyPart(targetPosition)
    end

    self._currentBeams[category].TargetAttachment = Instance.new("Attachment")
    self._currentBeams[category].TargetAttachment.Parent = self._currentBeams[category].Target
    self._currentBeams[category].TargetAttachment.Position = Vector3.zero

    self._currentBeams[category].Beam = BeamAsset:Clone()
    self._currentBeams[category].Beam.Parent = DebrisFolder
    self._currentBeams[category].Beam.Attachment0 = self._currentBeams[category].RootPartAttachment
    self._currentBeams[category].Beam.Attachment1 = self._currentBeams[category].TargetAttachment
end

local function restoreActiveBeams(self)
    for category: string, _ in pairs(self._currentBeams) do
        self._currentBeams[category].RootPartAttachment = Instance.new("Attachment")
        self._currentBeams[category].RootPartAttachment.Parent = self._rootPart
        self._currentBeams[category].RootPartAttachment.Position = Vector3.zero
        self._currentBeams[category].Beam.Attachment0 = self._currentBeams[category].RootPartAttachment
    end
end

local function updateCharacter(self)
    self._character = self._player.Character or self._player.CharacterAdded:Wait() :: Model

    if not self._character.PrimaryPart then
        self._character:GetPropertyChangedSignal("PrimaryPart"):Wait()
    end

    self._rootPart = self._character.PrimaryPart
    restoreActiveBeams(self)
end

function GuideBeamController:TryDestroyBeam(category: string, isSavingTarget: boolean?)
    if not self._currentBeams[category] then
        return false
    end

    destroyBeam(self, category, isSavingTarget)

    return true
end

function GuideBeamController:CreateOrRedirectGuideBeam(category: string, targetPosition: Vector3, reachDistance: number?)
    if self._currentBeams[category] then
        self._currentBeams[category].Target:Destroy()
        self._currentBeams[category].Target = createEmptyPart(targetPosition)
        self._currentBeams[category].TargetAttachment = Instance.new("Attachment")
        self._currentBeams[category].TargetAttachment.Parent = self._currentBeams[category].Target
        self._currentBeams[category].TargetAttachment.Position = Vector3.zero
        self._currentBeams[category].Beam.Attachment1 = self._currentBeams[category].TargetAttachment
        self._currentBeams[category].ReachDistance = reachDistance or self._currentBeams[category].ReachDistance
    else
        createNewBeam(self, category, targetPosition, reachDistance)
    end
end

function GuideBeamController:CreateOrRedirectGuideBeamToPart(category: string, part: Part, reachDistance: number?)
    if self._currentBeams[category] then
        self._currentBeams[category].Target:Destroy()
        self._currentBeams[category].Target = part
        self._currentBeams[category].TargetAttachment = Instance.new("Attachment")
        self._currentBeams[category].TargetAttachment.Parent = self._currentBeams[category].Target
        self._currentBeams[category].TargetAttachment.Position = Vector3.zero
        self._currentBeams[category].Beam.Attachment1 = self._currentBeams[category].TargetAttachment
        self._currentBeams[category].ReachDistance = reachDistance or self._currentBeams[category].ReachDistance
    else
        createNewBeam(self, category, nil, reachDistance, part)
    end
end

function GuideBeamController:Initialize(player: Player)
    self._player = player
    updateCharacter(self)

    self._player.CharacterAdded:Connect(function()
        updateCharacter(self)
    end)

    RunService.Heartbeat:Connect(function()
        if (not self._rootPart) or (not self._rootPart.Parent) then return end

        for category: string, _ in pairs(self._currentBeams) do
            local distance = (self._rootPart.Position - self._currentBeams[category].Target.Position).Magnitude

            if distance <= self._currentBeams[category].ReachDistance then
                destroyBeam(self, category)
            end
        end
    end)
end

function GuideBeamController.new()
    local self = setmetatable(GuideBeamController, {__index = ControllerTemplate})
    self._currentBeams = {}

    return self
end

return GuideBeamController