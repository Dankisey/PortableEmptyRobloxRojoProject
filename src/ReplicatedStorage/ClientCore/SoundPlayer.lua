local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local SoundRequested = ReplicatedStorage.Remotes.SoundRequested
local SFX = SoundService.SFX

local SoundConfig = require(ReplicatedStorage.Configs.SoundConfig)

local MaxLifetime = 30 -- seconds, a safety net against stuck or unavailable audio
local LocalPlayer = Players.LocalPlayer

local SoundPlayer = {}

local function getTemplate(soundName: string): Sound?
	local template = SFX:FindFirstChild(tostring(soundName))

	if template and template:IsA("Sound") then
		return template
	end

	return nil
end

function SoundPlayer:PlaySound(soundName, onPart: (BasePart | Attachment)?): Sound?
	local template = getTemplate(soundName)

	--[[ an empty SoundId is valid (not chosen yet), and its clone never fires Ended and lives until MaxLifetime ]]
	if template and template.SoundId == "" then return nil end

	local sound = template and template:Clone()

	if not sound then
		warn("SoundPlayer: sound not found " .. tostring(soundName))

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

	--[[ TimeLength is zero until loaded, so the lifetime does not rely on it ]]
	Debris:AddItem(sound, math.min(config and config.Lifetime or MaxLifetime, MaxLifetime))

	return sound
end

function SoundPlayer:Initialize()
	local sounds = {}

	for soundName in SoundConfig.Sfx do
		local template = getTemplate(soundName)

		if not template then
			warn("SoundPlayer: SoundService.SFX has no template " .. tostring(soundName))
		elseif template.SoundId ~= "" then
			table.insert(sounds, template)
		end
	end

	--[[ does not block ClientCore start: sounds are cached before the first gameplay action ]]
	task.spawn(function()
		pcall(ContentProvider.PreloadAsync, ContentProvider, sounds)
	end)
end

function SoundPlayer.new()
	local self = setmetatable({}, {__index = SoundPlayer})

	SoundRequested.OnClientEvent:Connect(function(soundName, onPart, exceptPlayer)
		--[[ the initiator already heard the local sound without a network round trip ]]
		if exceptPlayer == LocalPlayer then return end

		self:PlaySound(soundName, onPart)
	end)

	return self
end

return SoundPlayer
