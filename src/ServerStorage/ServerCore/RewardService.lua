local ServiceTemplate = require(script.Parent.Parent.ServiceTemplate)

local RewardService = {} :: ServiceTemplate.Type

local rewardsFunctions = {
	Cash = function(player: Player, data: {any}, self: ServiceTemplate.Type)
		self._services.SoftCurrencyService:AddCurrency(player, "Cash", data.Amount)
	end;
}

function RewardService:GiveMultipleRewards(player: Player, rewards)
	for functionName, data in pairs(rewards) do
		if not rewardsFunctions[functionName] then
			warn("There is no reward function with name " .. functionName)

			continue
		end

		local success, value = pcall(rewardsFunctions[functionName], player, data, self)

		if not success then
			warn("An error occurred while giving rewards: " .. tostring(value))
		end
	end
end

function RewardService:GiveReward(player: Player, rewardInfo: {FunctionName: string, Data: any})
	if not rewardsFunctions[rewardInfo.FunctionName] then
		warn("There is no reward function with name " .. rewardInfo.FunctionName)

		return
	end

	rewardsFunctions[rewardInfo.FunctionName](player, rewardInfo.Data, self)
end

function RewardService.new()
	return setmetatable(RewardService, {__index = ServiceTemplate})
end

return RewardService
