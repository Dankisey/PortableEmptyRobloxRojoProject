local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UtilsTypes = require(ReplicatedStorage.Modules.UtilsTypes)

local Types = {}

export type Analytics = {
	new: () -> Analytics;

} & ServiceTemplate

export type Monetization = {
	new: () -> Monetization;

	PromptProduct: (Monetization, player: Player, productId: number) -> nil;
	PromptPass: (Monetization, player: Player, passId: number) -> nil;

	--[[
		Привязать обработчик дев-продукта. Зовётся из Initialize владеющего сервиса;
		handler обязан вернуть true, иначе чек останется в очереди Roblox.

		ОБРАБОТЧИК НЕ ИМЕЕТ ПРАВА ЙИЛДИТЬ: он вызывается внутри трансформ-функции
		UpdateAsync. Подробности — в самом Monetization.
	]]
	RegisterProduct: (Monetization, productId: number, handler: (Monetization, player: Player, receiptInfo: any) -> boolean) -> nil;
} & ServiceTemplate

export type RewardService = {
	new: () -> RewardService;

	GiveMultipleRewards: (RewardService, player: Player, rewards: {[string]: any}) -> nil;
	GiveReward: (RewardService, player: Player, rewardInfo: {FunctionName: string, Data: any}) -> nil;
} & ServiceTemplate

--[[
	Загрузчик сейва. Разделы сам не разбирает: их владельцы находятся
	по соглашению — см. SaveSectionOwner ниже. Свой раздел — Stats.

	Сессию и запись держит ProfileStore: лок на ключ делает общий DataStore
	между плейсами безопасным, а автосейв не даёт падению сервера унести
	всю сессию. Отсюда и Save/RequestSave: раньше записать сейв извне было
	нечем вовсе, и покупка жила только в памяти до выхода игрока.
]]
export type SavesLoader = {
	new: () -> SavesLoader;

	IsLoaded: (SavesLoader, player: Player) -> boolean;

	-- НЕ ЙИЛДИТ; false значит «сессии нет, писать некуда», а не «запись не удалась»
	Save: (SavesLoader, player: Player) -> boolean;

	-- НИКОГДА НЕ ЙИЛДИТ: единственный допустимый вариант внутри обработчика покупки
	RequestSave: (SavesLoader, player: Player) -> nil;

	-- стирает сейв целиком и кикает; false = сессии нет
	WipeSave: (SavesLoader, player: Player) -> boolean;
} & ServiceTemplate

--[[
	Соглашение владельца раздела сейва. SavesLoader находит такие
	сервисы по полю SaveSection, поэтому регистрировать раздел негде не надо.

	GetSave зовётся перед КАЖДОЙ записью и обязан быть неразрушающим;
	nil из него значит «сейв не читался», и раздел не трогают вовсе.
	UnloadSave необязателен и только отпускает кэш: возврат не читается.
]]
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

	TrySpentCurrency: (SoftCurrencyService, player: Player, currencyName: string, spentAmount: number, transactionType: Enum.AnalyticsEconomyTransactionType | string, itemSku: string?) -> boolean;

	-- nil = сейв не загружен
	GetCurrency: (SoftCurrencyService, player: Player, currencyName: string) -> number?;

	-- false = сейв не загружен, валюты нет или сумма не годится; копит и Earned
	AddCurrency: (SoftCurrencyService, player: Player, currencyName: string, amount: number) -> boolean;
} & ServiceTemplate

--[[
	Состояние и сигналы. Сама механика живёт в ClientCore.RagdollController:
	сервер персонажем не владеет и позу с импульсом выставить не может.
]]
export type RagdollService = {
	new: () -> RagdollService;

	-- голое переключение позы без таймеров: для сцен, которые сами решают, когда поднять
	SetRagdoll: (RagdollService, player: Player, enabled: boolean, impulse: Vector3?) -> nil;

	-- сбить с ног: толчок, таймер, иммунитет
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

--[[
	Добавил сервис — добавь его сюда. Иначе типы протухают молча: так однажды
	годами жили сервисы, которых в коде уже не было.
]]
export type Services = {
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
