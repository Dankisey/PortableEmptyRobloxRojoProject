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

export type Utils = {
    CubicBezier: CubicBezier;
    DeepCopy: (ititialTable: {any}) -> {any};
    Event: Event;
    FormatNumber: (value: number, decimals: number?) -> string;
    FormatTime: (seconds: number, minSlotsAmount: number) -> string;
    GenerateGuid: (blacklist: {string}?) -> string;
    GetChancedRewardIndex: (rewardsConfig: {Chance: number}) -> number;
    ---@diagnostic disable-next-line: undefined-type
    GetKeys: (t: {[key]: value}) -> {key};
    GetPlayerProfileIcon: (userId: number) -> string;
    Lerp: (min: number, max: number, alpha: number) -> number;
    MakeNumberDividers: (number: number, divider: string) -> string;
    SpawnImages: (position: Vector3, emojiImageId: string, imagesCount : number, duration : number, offsetRange : number, minSize : number, maxSize : number, floatUp: boolean) -> nil;
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