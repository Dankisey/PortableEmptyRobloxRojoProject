local SoundRequested = game:GetService("ReplicatedStorage").Remotes.SoundRequested

local SoundService = game:GetService("SoundService")
local SFX = SoundService.SFX

local Debris = game:GetService("Debris")

local SoundPlayer = {}

function SoundPlayer:PlaySound(soundName, onPart: Part?) : Sound
	local sound: Sound = SFX[soundName]
	sound = sound:Clone()

	if onPart then
		sound.Parent = onPart
	else
		sound.Parent = workspace.Debris
	end

	sound:Play()
	Debris:AddItem(sound, sound.TimeLength)

	return sound
end

function SoundPlayer.new()
	local self = setmetatable({}, {__index = SoundPlayer})

	SoundRequested.OnClientEvent:Connect(function(...)
		self:PlaySound(...)
	end)

	return self
end

return SoundPlayer