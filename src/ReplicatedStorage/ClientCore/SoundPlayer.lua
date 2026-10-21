local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")

local SoundRequested = ReplicatedStorage.Remotes.SoundRequested
local SFX = SoundService.SFX

local SoundConfig = require(ReplicatedStorage.Configs.SoundConfig)

--[[ Страховка от зависшего или недоступного аудио. ]]
local MaxLifetime = 30
local LocalPlayer = Players.LocalPlayer

local SoundPlayer = {}

--[[ Шаблоны хранятся в SoundService.SFX ещё в Edit-режиме Studio. ]]
local function getTemplate(soundName: string): Sound?
	local template = SFX:FindFirstChild(tostring(soundName))

	if template and template:IsA("Sound") then
		return template
	end

	return nil
end

function SoundPlayer:PlaySound(soundName, onPart: (BasePart | Attachment)?) : Sound?
	local template = getTemplate(soundName)

	--[[ пустой SoundId штатный (звук ещё не выбран), а его клон не стреляет Ended и живёт до MaxLifetime ]]
	if template and template.SoundId == "" then return nil end

	local sound = template and template:Clone()

	if not sound then
		warn("SoundPlayer: не найден звук " .. tostring(soundName))

		return nil
	end

	local config = SoundConfig.Sfx[soundName]

	if config and config.PitchVariation then
		sound.PlaybackSpeed = template.PlaybackSpeed * (1 + (math.random() * 2 - 1) * config.PitchVariation)
	end

	sound.Parent = onPart or workspace
	sound.Ended:Once(function()
		if sound.Parent then sound:Destroy() end
	end)
	sound:Play()

	--[[ TimeLength равен нулю до загрузки, поэтому на него время жизни не опирается. ]]
	Debris:AddItem(sound, math.min(config and config.Lifetime or MaxLifetime, MaxLifetime))

	return sound
end

function SoundPlayer:Initialize()
	local sounds = {}

	for soundName in SoundConfig.Sfx do
		local template = getTemplate(soundName)

		if not template then
			warn("SoundPlayer: в SoundService.SFX нет шаблона " .. tostring(soundName))
		elseif template.SoundId ~= "" then
			table.insert(sounds, template)
		end
	end

	--[[ Не блокируем старт ClientCore: к первому игровому действию звуки уже в кэше. ]]
	task.spawn(function()
		pcall(ContentProvider.PreloadAsync, ContentProvider, sounds)
	end)
end

function SoundPlayer.new()
	local self = setmetatable({}, {__index = SoundPlayer})

	SoundRequested.OnClientEvent:Connect(function(soundName, onPart, exceptPlayer)
		-- Владелец заброса уже услышал локальный звук без сетевого круга.
		if exceptPlayer == LocalPlayer then return end

		self:PlaySound(soundName, onPart)
	end)

	return self
end

return SoundPlayer
