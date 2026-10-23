--[[ the SoundId is set on the instance in SoundService.SFX, the clone plays it; here it is for reference, and empty is a valid template state ]]
local SoundConfig = {}

SoundConfig.SfxVolume = .3

--[[ key = template name in SoundService.SFX; optional Volume, PlaybackSpeed, RollOffMaxDistance, Lifetime, PitchVariation (share of random speed and pitch) ]]
SoundConfig.Sfx = {
	ClickSound = {
		SoundId = "";
		Volume = SoundConfig.SfxVolume;
	};
	HoverSound = {
		SoundId = "";
		Volume = SoundConfig.SfxVolume;
	};
}

SoundConfig.BackgroundTracks = {} -- empty: BackgroundMusicController plays nothing

SoundConfig.BackgroundVolume = .1
SoundConfig.BackgroundFadeTime = 1.2 -- seconds
SoundConfig.BackgroundFallbackDuration = 120 -- seconds when a track length is unknown

return SoundConfig
