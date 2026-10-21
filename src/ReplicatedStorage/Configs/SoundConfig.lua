--[[
	Звуки: id, громкость, дальность и время жизни клона.

	Все SFX играются разовыми клонами шаблона из SoundService.SFX — этим
	занимается ClientCore.SoundPlayer. Музыка играет локально у каждого игрока
	и после конца трека переключается на следующий без повтора подряд.

	ПУСТОЙ SoundId — штатное состояние шаблона, а не поломка: звуки клика
	и наведения не выбраны, инстансы в SoundService.SFX лежат пустыми.
	Ставить id надо ИМЕННО В ИНСТАНСЕ — здесь он справочный, играет клон
	шаблона, а не эта таблица.
]]

local SoundConfig = {}

--[[ Единый уровень для коротких событий; дальность гасит только 3D-звуки. ]]
SoundConfig.SfxVolume = .3

--[[
	Ключ — имя шаблона из SoundService.SFX (см. SoundNames). SoundPlayer
	предупредит в консоли, если шаблона с таким именем нет.

	Поля сверх SoundId необязательные: Volume, PlaybackSpeed,
	RollOffMaxDistance, Lifetime, PitchVariation (доля: скорость и высота
	случайно в ±PitchVariation, чтобы серия звуков не звучала одной нотой).
]]
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

--[[ Фоновая музыка: пусто — BackgroundMusicController просто ничего не играет. ]]
SoundConfig.BackgroundTracks = {}

SoundConfig.BackgroundVolume = .1
SoundConfig.BackgroundFadeTime = 1.2
SoundConfig.BackgroundFallbackDuration = 120

return SoundConfig
