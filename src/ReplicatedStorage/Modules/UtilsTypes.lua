local UtilsTypes = {}

export type CubicBezier = {
	new: (x1: number, y1: number, x2: number, y2: number) -> CubicBezier;
	GetValueAtTime: (CubicBezier, t: number) -> number;
}

export type Event = {
	new: () -> Event;

	Invoke: (Event, ...any) -> nil;
	Subscribe: (Event, key: any,  callback: (...any) -> nil, ...any) -> nil;
	Unsubscribe: (Event, key: any) -> nil;

	_callbacks: {[any]: {
		Action: (any) -> nil;
		Args: {any};
	}}
}

export type Timer = {
	new: () -> Timer;

	Start: (Timer, countTime: number?) -> nil;
	GetLeftTime: (Timer) -> number;
	ForceFinish: (Timer) -> nil;
	Reset: (Timer) -> nil;
	Stop: (Timer) -> nil;

	IsFinished: boolean;
	Updated: Event;
	Finished: Event;

	_leftTime: number;
	_countTask: thread;
}

--[[ everything LoadModules collects from Modules.Utils; a utility missing here makes the types go stale silently ]]
export type Utils = {
	CharacterUtils: {
		GetAlive: (player: Player) -> (Model?, BasePart?, Humanoid?);
		GetAliveRoot: (player: Player) -> BasePart?;
		-- UpperTorso -> Torso -> HumanoidRootPart, whichever exists first
		GetTorso: (character: Model) -> BasePart?;
	};
	CubicBezier: CubicBezier;
	EvaluateGradient: (sequence: ColorSequence, time: number) -> Color3;
	FlatVector: {
		Mask: Vector3;
		Distance: (a: Vector3, b: Vector3) -> number;
		Flatten: (vector: Vector3, fallback: Vector3?) -> Vector3;
		Direction: (from: Vector3, to: Vector3, fallback: Vector3?) -> Vector3;
	};
	-- failed modules only warn
	LoadModules: (folder: Instance) -> {[string]: any};
	TweenPivot: (model: Model, cframe: CFrame, duration: number, easingStyle: Enum.EasingStyle?, easingDirection: Enum.EasingDirection?) -> Tween;
	-- water and ground are separate functions on purpose: a ground cast excludes water, a water cast includes only it
	WorldQuery: {
		RaycastWater: (origin: Vector3, direction: Vector3) -> RaycastResult?;
		IsOverWater: (position: Vector3, height: number?) -> boolean;
		RaycastGround: (origin: Vector3, direction: Vector3, ignore: {Instance}?) -> RaycastResult?;
		GetWorldFolder: (name: string) -> Folder;
		CollectTaggedAndFoldered: (tag: string, folderName: string) -> {BasePart};
	};
	DeepCopy: (initialTable: {any}) -> {any};
	Event: Event;
	FormatNumber: (value: number) -> string;
	FormatTime: (seconds: number, minSlotsAmount: number) -> string;
	GenerateGuid: (blacklist: {[string]: any}?) -> string;
	GetChancedRewardIndex: (rewardsConfig: {Chance: number}) -> number;
	---@diagnostic disable-next-line: undefined-type
	GetKeys: (t: {[key]: value}) -> {key};
	GetPlayerProfileIcon: (userId: number) -> string;
	Lerp: (min: number, max: number, alpha: number) -> number;
	MakeNumberDividers: (number: number, divider: string) -> string;
	Timer: Timer;
	TranslateRange: (oldMin: number, oldMax: number, newMin: number, newMax: number, oldValue: number) -> number;
	TryGetProductInfo: (id: number, infoType: Enum.InfoType) -> {any}?;

	TimeUtils: {
		TimeReferencePoint: number;
		Week: number;
		Day: number;

		IsWeekExpired: (timeStamp: number) -> boolean;
		GetWeekEnd: () -> number;
		IsDayExpired: (timeStamp: number) -> boolean;
		GetDayEnd: () -> number;
	}
}

return UtilsTypes