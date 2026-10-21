--[[
	Смысл события → имя шаблона звука в SoundService.SFX.

	Игровые модули знают только имя отсюда, а SoundConfig держит id и громкость.
	Новый звук заводится в трёх местах сразу: здесь, в SoundConfig.Sfx
	и инстансом Sound в SoundService.SFX — иначе SoundPlayer предупредит
	в консоли, что шаблона нет.
]]

local SoundNames = {
	Click = "ClickSound";
	Hover = "HoverSound";
}

return SoundNames
