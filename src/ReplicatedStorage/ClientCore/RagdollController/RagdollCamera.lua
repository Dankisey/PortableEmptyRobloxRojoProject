--[[
	RagdollCamera — камера на время лежки.

	По умолчанию камера следит за Humanoid, то есть за рутпартом. В рэгдолле тот
	кувыркается вместе с телом, и картинку швыряет так, что смотреть невозможно.

	Поэтому подсовываем камере отдельный заанкеренный якорь: он повторяет только
	позицию тела, без вращения, и догоняет её плавно.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local CharacterUtils = require(ReplicatedStorage.Modules.Utils.CharacterUtils)

local LocalPlayer = Players.LocalPlayer

local AnchorName = "RagdollCameraAnchor"
local FollowSpeed = 9 -- чем меньше, тем плавнее камера догоняет тело

local RagdollCamera = {}
RagdollCamera.__index = RagdollCamera

function RagdollCamera:Follow(character: Model)
	local torso = CharacterUtils.GetTorso(character)

	if not torso or not torso:IsA("BasePart") then return end

	self:Stop()

	--[[ Камеру берём заново: после респавна CurrentCamera могла смениться. ]]
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

		-- экспоненциальное сглаживание: не зависит от частоты кадров
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

	--[[
		Возвращаем именно Humanoid, а не запомненный субъект: пока мы лежали,
		персонаж мог смениться, и старая ссылка уже никуда не годится.
	]]
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
