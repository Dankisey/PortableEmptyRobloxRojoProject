local MessagesConfig = {}

MessagesConfig.LifeTime = 5
MessagesConfig.DisappearingTime = 3

MessagesConfig.Colors = {
    NameColor = "#" .. Color3.new(0.972549, 0.4, 0.4):ToHex();
    ErrorColor = "#" .. Color3.new(1, 0, 0):ToHex();
    DefaultColor = "#" .. Color3.new(0.317647, 0.635294, 0.972549):ToHex();
    CongratsColor = "#" .. Color3.new(0.262745, 0.792156, 0.309803):ToHex();
}

MessagesConfig.MessagesTypes = {
    Congrats = "Congrats";
    Default = "Default";
    Error = "Error";
}

MessagesConfig.TypeToBaseColor = {
    [MessagesConfig.MessagesTypes.Congrats] = MessagesConfig.Colors.CongratsColor; 
    [MessagesConfig.MessagesTypes.Default] = MessagesConfig.Colors.DefaultColor;
    [MessagesConfig.MessagesTypes.Error] = MessagesConfig.Colors.ErrorColor;
}

--[[
    If playerNames is not nil, baseMessage must contain as much "%s", as count of playerNames !!!
]]
MessagesConfig.FormatMessage = function(messageType: string, baseMessage: string, playerNames: {string}?)
    local resultMessage = "<font color='" .. MessagesConfig.TypeToBaseColor[messageType] .. "'>" .. baseMessage  .. "</font>"

    if playerNames then
        for i: number, playerName: string in ipairs(playerNames) do
            playerNames[i] = "<font color='" .. MessagesConfig.Colors.NameColor .. "'>" .. playerName  .. "</font>"
        end

        resultMessage = string.format(resultMessage, table.unpack(playerNames))
    end

    return resultMessage
end

return MessagesConfig