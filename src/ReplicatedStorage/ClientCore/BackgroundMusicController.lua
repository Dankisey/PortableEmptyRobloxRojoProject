--[[
	BackgroundMusicController — локальный фоновый плейлист забега.

	Музыка не реплицируется и не привязана к миру: каждому игроку нужна своя
	громкость, а следующая композиция выбирается после окончания предыдущей.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local ControllerTemplate = require(ReplicatedStorage.Modules.ControllerTemplate)
local SoundConfig = require(ReplicatedStorage.Configs.SoundConfig)

local BackgroundMusicController = {}

local function getNextIndex(self): number
	local count = #self._tracks

	if count <= 1 then return 1 end

	local index = self._random:NextInteger(1, count - 1)

	if index >= self._currentIndex then
		index += 1
	end

	return index
end

local function stopCurrent(self)
	local sound = self._currentSound

	if not sound then return end

	if self._fadeTween then
		self._fadeTween:Cancel()
		self._fadeTween = nil
	end

	sound:Stop()
	self._currentSound = nil
end

local function playNext(self)
	if #self._tracks == 0 then return end

	stopCurrent(self)

	self._currentIndex = getNextIndex(self)

	local track = self._tracks[self._currentIndex]
	local sound = Instance.new("Sound")
	sound.Name = track.Name or ("Track" .. self._currentIndex)
	sound.SoundId = track.SoundId
	sound.Volume = 0
	sound.Looped = false
	sound.Parent = self._folder

	self._currentSound = sound
	sound:Play()

	self._fadeTween = TweenService:Create(
		sound,
		TweenInfo.new(SoundConfig.BackgroundFadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{Volume = SoundConfig.BackgroundVolume}
	)
	self._fadeTween:Play()

	sound.Ended:Once(function()
		if self._currentSound ~= sound then return end

		sound:Destroy()
		self._currentSound = nil
		self._fadeTween = nil
		playNext(self)
	end)

	--[[ Если аудио недоступно и Ended не придёт, плейлист не должен зависнуть. ]]
	task.delay(SoundConfig.BackgroundFallbackDuration, function()
		if self._currentSound ~= sound or not sound.Parent then return end

		sound:Destroy()
		self._currentSound = nil
		self._fadeTween = nil
		playNext(self)
	end)
end

function BackgroundMusicController:Skip()
	playNext(self)
end

function BackgroundMusicController:Initialize()
	if #self._tracks == 0 then return end

	self._folder = SoundService:FindFirstChild("BackgroundMusic")

	if not self._folder then
		self._folder = Instance.new("Folder")
		self._folder.Name = "BackgroundMusic"
		self._folder.Parent = SoundService
	end

	playNext(self)
end

function BackgroundMusicController.new()
	local self = setmetatable(BackgroundMusicController, {__index = ControllerTemplate})

	self._tracks = SoundConfig.BackgroundTracks
	self._random = Random.new()
	self._currentIndex = 0
	self._currentSound = nil
	self._fadeTween = nil
	self._folder = nil

	return self
end

return BackgroundMusicController