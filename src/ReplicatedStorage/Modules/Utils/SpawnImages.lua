local TweenService = game:GetService("TweenService")

return function (position: Vector3, emojiImageId: string, imagesCount : number, duration : number, offsetRange : number, minSize : number, maxSize : number, floatUp: boolean)
	local part = Instance.new("Part")
	part.Position = position
	part.Size = Vector3.one
	part.CanCollide = false
	part.Transparency = 1
	part.CanTouch = false
	part.CanQuery = false
	part.Anchored = true
	part.Parent = workspace.Debris

	local timePerHeart = duration / imagesCount
	local heartLifetime = duration / 2

	task.spawn(function()
		for _ = 1, imagesCount do
			task.spawn(function()
				local gui = Instance.new("BillboardGui")
				gui.AlwaysOnTop = true
				gui.Size = UDim2.fromScale(1.5, 1.5)

				local offsetX = math.random(-offsetRange * 10, offsetRange * 10) / 10
				local offsetY = math.random(-offsetRange * 10, offsetRange * 10) / 10
				local offsetZ = math.random(-offsetRange * 10, offsetRange * 10) / 10
				gui.StudsOffset = Vector3.new(offsetX, offsetY, offsetZ)

				local imageLabel = Instance.new("ImageLabel")
				imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				imageLabel.Position = UDim2.fromScale(0.5, 0.5)
				imageLabel.Size = UDim2.fromScale(0, 0)
				imageLabel.BackgroundTransparency = 1
				imageLabel.Image = emojiImageId
				imageLabel.Parent = gui
				gui.Parent = part

				local heartSize = math.random(minSize * 100, maxSize * 100) / 100

				imageLabel:TweenSize(UDim2.fromScale(heartSize * 1.2, heartSize * 1.2), "InOut", "Back", heartLifetime / 6, true)
				task.wait(heartLifetime / 6)
				imageLabel:TweenSize(UDim2.fromScale(heartSize, heartSize), "InOut", "Back", heartLifetime / 6, true)

				local finalStudsOffset = gui.StudsOffset

				if floatUp then
					finalStudsOffset = finalStudsOffset + Vector3.yAxis * 5
				end

				local rotationTween = TweenService:Create(imageLabel, TweenInfo.new(heartLifetime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 10})
				local pulseTween = TweenService:Create(imageLabel, TweenInfo.new(heartLifetime / 3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, -1), {Size = UDim2.fromScale(heartSize * 1.1, heartSize * 1.1)})

				local tweenInfo = TweenInfo.new(heartLifetime * 2 / 3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
				local guiUpTween = TweenService:Create(gui, tweenInfo, {StudsOffset = finalStudsOffset})
				local imageFadeTween = TweenService:Create(imageLabel, tweenInfo, {ImageTransparency = 1})

				guiUpTween:Play()
				imageFadeTween:Play()
				rotationTween:Play()
				pulseTween:Play()

				task.wait(heartLifetime)
				gui:Destroy()
			end)

			task.wait(timePerHeart)
		end
	end)

	task.delay(duration * 2, function()
		part:Destroy()
	end)
end