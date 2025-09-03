local Animation = game:GetService("ReplicatedStorage").Assets.Animations.LeaderboardDummy
local Players = game:GetService("Players")

local defaultImage = "http://www.roblox.com/asset/?id=14592693718"

local Dummy = {}

function Dummy:SetPlayer(userId: number)
	if userId == self._currentUserId then return end

	self._currentUserId = userId
	local description = Players:GetHumanoidDescriptionFromUserId(userId)
	self._humanoid:ApplyDescription(description)

	local success, name = pcall(Players.GetNameFromUserIdAsync, Players, tonumber(userId))

	if success then
		self._model.Name = name
	else
		self._model.Name = "???"
	end

	local content, isReady = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	self._avatarIcon.Image = (isReady and content) or defaultImage

	local animationTrack = self._animator:LoadAnimation(Animation)
	animationTrack.Looped = true
	animationTrack:Play()
end

function Dummy.new(model: Model)
	local self = setmetatable({}, {__index = Dummy})
	self._model = model:WaitForChild("Dummy")
	self._avatarIcon = model:WaitForChild("GuiHolder"):WaitForChild("Gui"):WaitForChild("AvatarHolder"):WaitForChild("Avatar")
	self._humanoid = model:WaitForChild("Dummy"):WaitForChild("Humanoid")
	self._humanoid.MaxHealth = math.huge
	self._humanoid.Health = math.huge
	self._animator = self._humanoid:WaitForChild("Animator")
	self._currentUserId = 0

	return self
end

return Dummy