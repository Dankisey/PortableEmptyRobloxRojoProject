local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local CharacterUtils = require(ReplicatedStorage.Modules.Utils.CharacterUtils)

local LocalPlayer = Players.LocalPlayer

local AnchorName = "RagdollCameraAnchor"
local FollowSpeed = 9 -- lower is smoother

--[[ the camera follows an anchored anchor with position only: the tumbling root part would throw the view around ]]
local RagdollCamera = {}
RagdollCamera.__index = RagdollCamera

function RagdollCamera:Follow(character: Model)
	local torso = CharacterUtils.GetTorso(character)

	if not torso or not torso:IsA("BasePart") then return end

	self:Stop()

	--[[ fetched again: CurrentCamera may change after a respawn ]]
	local camera = workspace.CurrentCamera
	self._camera = camera

	local anchor = Instance.new("Part")
	anchor.Name = AnchorName
	anchor.Size = Vector3.one
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CFrame = CFrame.new(torso.Position)
	anchor.Parent = character

	self._anchor = anchor
	self._previousSubject = camera.CameraSubject
	camera.CameraSubject = anchor

	self._connection = RunService.RenderStepped:Connect(function(deltaTime)
		if not anchor.Parent or not torso.Parent then
			self:Stop()

			return
		end

		local alpha = 1 - math.exp(-FollowSpeed * deltaTime)

		anchor.CFrame = CFrame.new(anchor.Position:Lerp(torso.Position, alpha))
	end)
end

function RagdollCamera:Stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end

	if self._anchor then
		self._anchor:Destroy()
		self._anchor = nil
	end

	local camera = self._camera or workspace.CurrentCamera
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	--[[ the current Humanoid, not the stored subject: the character may have changed while lying down ]]
	if humanoid then
		camera.CameraSubject = humanoid
	elseif self._previousSubject then
		camera.CameraSubject = self._previousSubject
	end

	self._previousSubject = nil
	self._camera = nil
end

function RagdollCamera.new()
	return setmetatable({
		_anchor = nil;
		_camera = nil;
		_connection = nil;
		_previousSubject = nil;
	}, RagdollCamera)
end

return RagdollCamera
