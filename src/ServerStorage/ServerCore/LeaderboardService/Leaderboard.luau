local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MedalsIconsConfig = require(ReplicatedStorage.Configs.MedalsIconsConfig)
local FormatTimeWithMaxSlots = require(ReplicatedStorage.Modules.Utils.FormatTimeWithMaxSlots)
local FormatNumber = require(ReplicatedStorage.Modules.Utils.FormatNumber)
--local FormatTime = require(ReplicatedStorage.Modules.Utils.FormatTime)

local Players = game:GetService("Players")

local Leaderboard = {}

local function getNewRecord(self, rank: number): Frame
	local newRecord = self._recordTemplate:Clone()
	newRecord.Parent = self._list
	newRecord.LayoutOrder = rank
	newRecord:WaitForChild("Rank").Text = MedalsIconsConfig.SpecialSigns[rank] or "#"..rank
	newRecord.Visible = true

	return newRecord
end

function Leaderboard:Update(leadersPage)
	task.spawn(function()
		for rank, data in ipairs(leadersPage) do
			if not self._records[rank] then
				self._records[rank] = getNewRecord(self, rank)
			end

			local name = "Unnamed"

			pcall(function()
				task.wait()
				name = Players:GetNameFromUserIdAsync(tonumber(data.key))
			end)

			local value = data.value

            if self._model:GetAttribute("Stat") == "TotalPlaytime" then
                value = FormatTimeWithMaxSlots(value, 2)
            else
                value = FormatNumber(value)
            end

			self._records[rank]:WaitForChild("Name").Text = name
			self._records[rank]:WaitForChild("Value").Text = value
		end
	end)
end

function Leaderboard.new(model: Model)
	local self = setmetatable({}, {__index = Leaderboard})
	self._model = model
	self._list = model:WaitForChild("GuiPart"):WaitForChild("BoardGui"):WaitForChild("LeaderboardFrame"):WaitForChild("ScrollingFrame")
	self._recordTemplate = self._list:WaitForChild("Template")
	self._records = {}

	return self
end

return Leaderboard