local SharedTypes = {}

export type BoostsSave = {
    TemporaryBoosts: {
        [string]: TemporaryBoostData;
    };
    PermanentBoosts: {
        [string]: boolean;
    };
}

export type Quest = {
	IsRewardClaimed: boolean;
	IsCompleted: boolean;
	Description: string;
	QuestType: string;
	RewardData: {
        Icon: string;
        Rewards: {[string]: any};
    };
	Goal: number;
}

export type TemporaryBoostData = {
    ModifiedStats: {[string]: number};
    Duration: number;
}

return SharedTypes