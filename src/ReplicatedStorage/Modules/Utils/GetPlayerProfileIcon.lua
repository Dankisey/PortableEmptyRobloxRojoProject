local Players = game:GetService("Players")
local baseImage = "http://www.roblox.com/asset/?id=14592693718"

local function getPlayerIcon(userId: number) : string
	local imageId = nil
	local tries = 0

	repeat 
		local success, result = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

		if not success then
			warn("Player thumbnnail failed: " .. tostring(result))
            task.wait(2 * (tries + 1))
        else
            imageId = result
        end

		tries +=1
	until success or tries == 3

    if not imageId then
        imageId = baseImage
    end

	return imageId
end

return getPlayerIcon