local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedTypes = require(ReplicatedStorage.Modules.SharedTypes)
local UtilsTypes = require(ReplicatedStorage.Modules.UtilsTypes)

local Types = {}

export type Analytics = {
    new: () -> Analytics;

} & ServiceTemplate

export type Monetization = {
    new: () -> Monetization;

    PromptProduct: (Monetization, player: Player, productId: number) -> nil;
    PromptPass: (Monetization, player: Player, passId: number) -> nil;
} & ServiceTemplate

export type RewardService = {
    new: () -> RewardService;

    GiveMultipleRewards: (RewardService, player: Player, rewards: {[string]: any}) -> nil;
    GiveReward: (RewardService, player: Player, rewardInfo: {FunctionName: string, Data: any}) -> nil;
} & ServiceTemplate

export type SavesLoader = {
    new: () -> SavesLoader;

    AddUsedCode: (SavesLoader, player: Player, code: string) -> nil;
    GetUsedCodes: (SavesLoader, player: Player) -> {string};
} & ServiceTemplate

export type ServerMessagesSender = {
    new: () -> ServerMessagesSender;

    SendMessageToPlayer: (ServerMessagesSender, player: Player, messageType: "Default"|"Congrats"|"Error", baseMessage: string, playerNames: {string}?) -> nil;
    SendMessage: (ServerMessagesSender, messageType: "Default"|"Congrats"|"Error", baseMessage: string, playerNames: {string}?) -> nil;
} & ServiceTemplate

export type SoftCurrencyService = {
    new: () -> SoftCurrencyService;

    TrySpentCurrency: (SoftCurrencyService, player: Player, currencyName: string, spentAmount: number, transactionType: Enum.AnalyticsEconomyTransactionType | string, itemSku: string?) -> boolean;
} & ServiceTemplate

export type ZonesService = {
    new: () -> ZonesService;

    TeleportCharacterToAssignedZone: (ZonesService, player: Player) -> nil;
    GetPlayerZone: (ZonesService, player: Player) -> Model?;
    RegisterPlayer: (ZonesService, player: Player) -> nil;
    RemovePlayer: (ZonesService, player: Player) -> nil;
} & ServiceTemplate

--[[========================================================================================]]

export type Services = {
    Analytics: Analytics;
    RewardService: RewardService;
    SavesLoader: SavesLoader;
    ServerMessagesSender: ServerMessagesSender;
    SoftCurrencyService: SoftCurrencyService;
    ZonesService: ZonesService;
}

--[[========================================================================================]]

export type ServiceTemplate = {
    InjectServices: (ServiceTemplate, services: Services) -> nil;
    InjectUtils: (ServiceTemplate, utils: UtilsTypes.Utils) -> nil;
    InjectConfigs: (ServiceTemplate, configs: {[string]: any}) -> nil;

    _services: Services;
    _utils: UtilsTypes.Utils;
    _configs: {[string]: any};
}

return Types