local GenerateViewport = {}

function GenerateViewport:GenerateViewport(Viewport : ViewportFrame, PetModel)
	-- Removing previous model and camera
	if not PetModel.PrimaryPart then
		warn("WARNING!!!! This pet doesnt have set primary part : "..PetModel.Name)
		return
	end
	for _, v in pairs(Viewport:GetChildren()) do
		if v:IsA("Model") or v:IsA("MeshPart") or v:IsA('Camera') then
			v:Destroy()
		end
	end

	Viewport.CurrentCamera = nil

	-- Import New
	PetModel:PivotTo(CFrame.new() * CFrame.Angles(0, math.rad(205), 0))
	PetModel.Parent = Viewport


	local Camera = Instance.new("Camera",Viewport)
	Viewport.CurrentCamera = Camera

	Camera.CFrame = CFrame.new(Vector3.new(0, 0, 3),PetModel.PrimaryPart.Position)

end

return GenerateViewport