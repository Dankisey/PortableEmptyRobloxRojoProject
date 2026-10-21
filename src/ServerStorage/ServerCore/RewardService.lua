local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local SoundRequested = Remotes.SoundRequested

local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)
local RewardService = {} :: ServiceTemplate.Type

local rewardsFunctions = {
	Cash = function(player: Player, data: {any}, self: ServiceTemplate.Type)
		self._services.SoftCurrencyService:AddCurrency(player, "Cash", data.Amount)

		--[[
			Поп-ап монет отменён совсем — выглядел плохо. Сама машинерия
			PopupsGui остаётся под будущие поп-апы, но деньги её не зовут.

			Строка Analytics остаётся закомментированной как была: её включение —
			отдельное решение, не часть отказа от поп-апа.
		]]
		--self._services.Analytics:LogCurrencyIncome(player, "Cash", data.Amount, data.TransactionType, data.Sku)
	end;
}

function RewardService:GiveMultipleRewards(player: Player, rewards)
	for functionName, data in pairs(rewards) do
		if not rewardsFunctions[functionName] then
			warn("There is not reward function with name ".. functionName)

			continue
		end

		local success, value = pcall(rewardsFunctions[functionName], player, data, self)

		if not success then
			warn("An error occured while giving rewards: " .. tostring(value))
		end
	end
end

function RewardService:GiveReward(player: Player, rewardInfo: {FunctionName: string, Data: any})
	if not rewardsFunctions[rewardInfo.FunctionName] then
		warn("There is not reward function with name ".. rewardInfo.FunctionName)

		return
	end

	rewardsFunctions[rewardInfo.FunctionName](player, rewardInfo.Data, self)
end

function RewardService.new()
	local self = setmetatable(RewardService, {__index = ServiceTemplate})

	return self
end

return RewardService