local random = Random.new()

local function getChancedRewardIndex(rewardsConfig)
	local total = 0
	
	for i, reward in ipairs(rewardsConfig) do
		total += reward.Chance
	end
	
	local randomNumber = random:NextNumber(0, total)
	local rewardIndex = 0

	for i, reward in ipairs(rewardsConfig) do
		rewardIndex = i

		if randomNumber - reward.Chance <= 0 then
			break
		end

		randomNumber -= reward.Chance
	end

	return rewardIndex
end

return getChancedRewardIndex
