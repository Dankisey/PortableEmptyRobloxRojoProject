local SavesConfig = {}

SavesConfig.DataStoreName = "PlayersSavesData"

--[[ must match in every place of the universe: a different key gives the player two separate progressions ]]
function SavesConfig.GetProfileKey(player: Player): string
	return tostring(player.UserId)
end

--[[ autosave is the only protection against a server crash for progress that changes silently ]]
SavesConfig.AutoSavePeriod = 60 -- seconds between autosaves, shorter than the ProfileStore default

SavesConfig.SaveInterval = 6 -- seconds of RequestSave debounce: a burst of purchases becomes one write

--[[ true for a gameplay place: playing on defaults and overwriting real progress on leave is worse than not letting in; false for a lobby or menu ]]
SavesConfig.KickOnLoadFail = true
SavesConfig.KickMessage = "Could not load your save, please rejoin"

SavesConfig.SessionEndedMessage = "Your save is open in another server, please rejoin"

SavesConfig.WipeMessage = "Your save was wiped, please rejoin"

--[[ Studio only: the session runs in ProfileStore.Mock and nothing reaches the DataStore ]]
SavesConfig.UseEmptySave = false

return SavesConfig
