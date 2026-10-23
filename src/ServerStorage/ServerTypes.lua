local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UtilsTypes = require(ReplicatedStorage.Modules.UtilsTypes)

local Types = {}

export type AdminService = {
	new: () -> AdminService;
} & ServiceTemplate

export type Analytics = {
	new: () -> Analytics;
} & ServiceTemplate

export type Monetization = {
	new: () -> Monetization;

	PromptProduct: (Monetization, player: Player, productId: number) -> nil;
	PromptPass: (Monetization, player: Player, passId: number) -> nil;

	-- the handler runs inside an UpdateAsync transform: it must not yield and must return true
	RegisterProduct: (Monetization, productId: number, handler: (Monetization, player: Player, receiptInfo: any) -> boolean) -> nil;
	RegisterPass: (Monetization, passId: number, handler: (Monetization, player: Player, passId: number) -> ()) -> nil;

	-- server wide switch, off by default: developers from DevelopersConfig get products and passes for free
	AreDeveloperPurchasesEnabled: (Monetization) -> boolean;
	SetDeveloperPurchasesEnabled: (Monetization, isEnabled: boolean) -> nil;
	GetDeveloperPurchasesChangedSignal: (Monetization) -> RBXScriptSignal;
} & ServiceTemplate

export type RewardService = {
	new: () -> RewardService;

	GiveMultipleRewards: (RewardService, player: Player, rewards: {[string]: any}) -> nil;
	GiveReward: (RewardService, player: Player, rewardInfo: {FunctionName: string, Data: any}) -> nil;
} & ServiceTemplate

export type SavesLoader = {
	new: () -> SavesLoader;

	IsLoaded: (SavesLoader, player: Player) -> boolean;

	-- does not yield; false = no session to write to, not a failed write
	Save: (SavesLoader, player: Player) -> boolean;

	-- never yields: the only save call allowed inside a purchase handler
	RequestSave: (SavesLoader, player: Player) -> nil;

	-- wipes the whole save and kicks; false = no session
	WipeSave: (SavesLoader, player: Player) -> boolean;
} & ServiceTemplate

--[[ SavesLoader finds owners by the SaveSection field; GetSave runs before every write, must be non-destructive, nil = save not read ]]
export type SaveSectionOwner = {
	SaveSection: string;

	LoadSave: (SaveSectionOwner, player: Player, data: any) -> nil;
	GetSave: (SaveSectionOwner, player: Player) -> any;
	UnloadSave: ((SaveSectionOwner, player: Player) -> any)?;
}

export type ServerMessagesSender = {
	new: () -> ServerMessagesSender;

	SendMessageToPlayer: (ServerMessagesSender, player: Player, messageType: "Default"|"Success"|"Error", baseMessage: string, playerNames: {string}?) -> nil;
	SendMessage: (ServerMessagesSender, messageType: "Default"|"Success"|"Error", baseMessage: string, playerNames: {string}?) -> nil;
} & ServiceTemplate

export type SoftCurrencyService = {
	new: () -> SoftCurrencyService;

	TrySpendCurrency: (SoftCurrencyService, player: Player, currencyName: string, spentAmount: number, transactionType: Enum.AnalyticsEconomyTransactionType | string, itemSku: string?) -> boolean;

	-- nil = save not loaded
	GetCurrency: (SoftCurrencyService, player: Player, currencyName: string) -> number?;

	-- false = save not loaded, unknown currency or invalid amount; also adds to Earned
	AddCurrency: (SoftCurrencyService, player: Player, currencyName: string, amount: number) -> boolean;
} & ServiceTemplate

export type RagdollService = {
	new: () -> RagdollService;

	-- raw pose switch without timers, for scenes that decide when to stand up themselves
	SetRagdoll: (RagdollService, player: Player, enabled: boolean, impulse: Vector3?) -> nil;

	-- knock down: impulse, timer, immunity
	Knockdown: (RagdollService, player: Player, options: ({
		Duration: number?;
		Immunity: number?;
		Impulse: Vector3?;
	} | number)?) -> boolean;
	Cancel: (RagdollService, player: Player) -> nil;

	IsRagdolled: (RagdollService, player: Player) -> boolean;
	IsImmune: (RagdollService, player: Player) -> boolean;
	GrantImmunity: (RagdollService, player: Player, duration: number) -> nil;

	RagdollStarted: UtilsTypes.Event;
	RagdollEnded: UtilsTypes.Event;
} & ServiceTemplate

--[[========================================================================================]]

--[[ a service missing here makes the types go stale silently ]]
export type Services = {
	AdminService: AdminService;
	Analytics: Analytics;
	Monetization: Monetization;
	RewardService: RewardService;
	SavesLoader: SavesLoader;
	ServerMessagesSender: ServerMessagesSender;
	SoftCurrencyService: SoftCurrencyService;
	RagdollService: RagdollService;
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
