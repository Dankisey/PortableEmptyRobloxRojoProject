--[[
    Usage:
    local Gizmos = require(Path.To.Gizmos)
    -- anywhere in the code:
    Gizmos:SetColor('red')
    Gizmos:DrawLine(Vector3.zero, Vector3.yAxis)

    Supports:
        - SetColor()
        - SetTransparency()
        - DrawLine()
        - DrawRay()
        - DrawPath()
        - DrawPoint()
        - DrawCube()
        - DrawCircle()
        - DrawSphere()
        - DrawPyramid()
        - DrawCFrame()
        - DrawText()
        - DrawRaycast()
        - DrawSpherecast()
        - DrawBlockcast()
        - AddToPath()
]]

local Gizmos = {}

local wfh: WireframeHandleAdornment = nil
local commands = {}
local trailers = {}

local hitColor, missColor = 'green', 'red'

Gizmos.Clear = true

local colors = {
	red     = Color3.new(1, 0, 0),
	green   = Color3.new(0, 1, 0),
	blue    = Color3.new(0, 0, 1),
	yellow  = Color3.new(1, 1, 0),
	cyan    = Color3.new(0, 1, 1),
	magenta = Color3.new(1, 0, 1),
	orange  = Color3.new(1, 0.5, 0),
	purple  = Color3.new(0.5, 0, 1),
	white   = Color3.new(1, 1, 1),
	gray    = Color3.new(0.5, 0.5, 0.5),
	black   = Color3.new(0, 0, 0),
}

local function findOrMakeGizmos()
	wfh = wfh or workspace:FindFirstChild('Gizmos')
	if not wfh then
		wfh = Instance.new('WireframeHandleAdornment')
		wfh.Name = 'Gizmos'
		wfh.Parent = workspace
		assert(workspace.WorldPivot:FuzzyEq(CFrame.identity), 'workspace is expected to have identity CFrame')
		wfh.Color3 = Color3.new(1, 1, 1)
		wfh.Adornee = workspace
		wfh.AlwaysOnTop = true
	end
end

local function helper_getGui()
	local localPlayer = game:GetService('Players').LocalPlayer
	if localPlayer then -- client
		return localPlayer:WaitForChild('PlayerGui', 3)
	else -- server
		return game:GetService('StarterGui')
	end
end

----------

-- This class is used to store the last N added elements, useful for trailing values like plots and paths.
local Trailer = {}
Trailer.__index = Trailer

function Trailer.new(limit)
	local defaultLimit = 300
	local self = setmetatable({}, Trailer)
	self.limit = limit or defaultLimit
	self.values = {}
	return self
end

function Trailer:addValue(value)
	table.insert(self.values, value)
	if #self.values > self.limit then
		table.remove(self.values, 1)
	end
end

function Trailer:getValues()
	return self.values
end

------------------------------------- PRIVATE

local function setColor(color: string | Color3)
	local color3 = if typeof(color) == 'string' then colors[color] else color
	wfh.Color3 = color3
end

local function setTransparency(value: number)
	wfh.Transparency = value
end

local function drawLine(from: Vector3, to: Vector3)
	wfh:AddLine(from, to)
end

local function helper_getPerpendicularVector(v: Vector3): Vector3
	local perp: Vector3 = Vector3.new(-v.y, v.x, 0)
	if perp.Magnitude == 0 then
		perp = Vector3.new(0, -v.z, v.y)
	end
	return perp.Unit
end

local function drawRay(origin: Vector3, direction: Vector3)
	local endPoint = origin + direction
	wfh:AddLine(origin, endPoint)
    
	local arrowLength, arrowAngle = direction.Magnitude/20, math.rad(30)

	local dir = direction.Unit
	local perp = helper_getPerpendicularVector(dir)
	local left  = endPoint - dir * arrowLength + perp * arrowLength * math.tan(arrowAngle)
	local right = endPoint - dir * arrowLength - perp * arrowLength * math.tan(arrowAngle)
	wfh:AddLine(endPoint, left)
	wfh:AddLine(endPoint, right)
end

local function drawPoint(pos: Vector3, size: number?)
	size = size or 0.1
	wfh:AddLines({
		pos - Vector3.xAxis * size, pos + Vector3.xAxis * size, 
		pos - Vector3.yAxis * size, pos + Vector3.yAxis * size, 
		pos - Vector3.zAxis * size, pos + Vector3.zAxis * size})
end

local function drawCube(pos: Vector3 | CFrame, size: Vector3)
	local cf = if typeof(pos) == 'Vector3' then CFrame.new(pos) else pos
	local halfSize = size * 0.5
	local min = -halfSize
	local max = halfSize
	local v = {
		cf * min,
		cf * Vector3.new(max.x, min.y, min.z),
		cf * Vector3.new(max.x, min.y, max.z),
		cf * Vector3.new(min.x, min.y, max.z),
		cf * Vector3.new(min.x, max.y, min.z),
		cf * Vector3.new(max.x, max.y, min.z),
		cf * max,
		cf * Vector3.new(min.x, max.y, max.z),
	}
	wfh:AddLines({
		v[1], v[2],
		v[2], v[3],
		v[3], v[4],
		v[4], v[1],
		v[5], v[6],
		v[6], v[7],
		v[7], v[8],
		v[8], v[5],
		v[1], v[5],
		v[2], v[6],
		v[3], v[7],
		v[4], v[8],
	})
end

local function drawPath(points: {Vector3}, closed: boolean?, dotsSize: number?)
	closed = closed or false
	dotsSize = dotsSize or 0
	wfh:AddPath(points, closed)
	if dotsSize > 0 then
		for _, point in ipairs(points) do
			drawCube(point, Vector3.one * dotsSize)
		end
	end
end

local function drawCircle(pos: Vector3, radius: number, normal: Vector3?)
	local segments = 16
	normal = normal or Vector3.yAxis
	local cf = CFrame.lookAlong(pos, normal)
	local angle = 2 * math.pi / segments

	local points = {}
	for i = 1, segments do
		local localpoint = Vector3.new(math.cos(i * angle), math.sin(i * angle), 0) * radius
		local point = cf:PointToWorldSpace(localpoint)
		table.insert(points, point)
	end
	wfh:AddPath(points, true)
end

local function drawSphere(pos: Vector3 | CFrame, radius: number)
	local cf = if typeof(pos) == 'Vector3' then CFrame.new(pos) else pos
	drawCircle(cf.Position, radius, cf.Rotation * Vector3.xAxis)
	drawCircle(cf.Position, radius, cf.Rotation * Vector3.yAxis)
	drawCircle(cf.Position, radius, cf.Rotation * Vector3.zAxis)
end

local function drawPyramid(pos: Vector3 | CFrame, size: number, height: number)
	local cf = if typeof(pos) == 'Vector3' then CFrame.new(pos) else pos
	local hsize = size/2
	local points = {
		cf * Vector3.new( hsize, 0,  hsize),
		cf * Vector3.new(-hsize, 0,  hsize),
		cf * Vector3.new(-hsize, 0, -hsize),
		cf * Vector3.new( hsize, 0, -hsize),
		cf * Vector3.new(0, height, 0),
	}
	wfh:AddPath({points[1], points[2], points[3], points[4], points[1], points[5], points[2]}, false)
	wfh:AddPath({points[3], points[5], points[4]}, false)
end

local function drawCFrame(cf: CFrame, size: number, color: Color3)
	size = size or 1
	local color3 = wfh.Color3
	local pos = cf.Position
	if color ~= nil then
		setColor(color)
		drawLine(pos, pos + cf.RightVector * size)
		drawLine(pos, pos + cf.UpVector * size)
		drawLine(pos, pos + -cf.LookVector * size)
	else
		setColor('red')
		drawLine(pos, pos + cf.RightVector * size)
		setColor('green')
		drawLine(pos, pos + cf.UpVector * size)
		setColor('blue')
		drawLine(pos, pos + -cf.LookVector * size)
	end
	wfh.Color3 = color3
end

local function helper_formatText(...)
	local args = {...}
	local text = ''
	for _, v in ipairs(args) do
		local str
		if typeof(v) == 'string' then
			str = v
		elseif typeof(v) == 'number' then
			str = string.format('%.3f', v)
		elseif typeof(v) == 'Vector3' then
			str = string.format('(%.3f, %.3f, %.3f)', v.x, v.y, v.z)
		elseif typeof(v) == 'CFrame' then
			local rx,ry,rz = v:ToOrientation()
			rx, ry, rz = math.deg(rx), math.deg(ry), math.deg(rz)
			local pos = v.Position
			str = string.format('pos=(%.3f, %.3f, %.3f) rot=(%.3f, %.3f, %.3f)', pos.x, pos.y, pos.z, rx, ry, rz)
		else
			str = tostring(v)
		end
		text = text .. ' ' .. str
	end
	return text
end

local function drawText(position: Vector3, ...) -- size: number
	local args = {...}
	local text = helper_formatText(unpack(args))
	local size = nil
	wfh:AddText(position, text, size)
end

local function helper_drawHit(hit: RaycastResult)
	drawCircle(hit.Position, 0.15, hit.Normal)
	drawRay(hit.Position, hit.Normal * 0.3)
end

local function helper_drawRaycast(cf: CFrame, direction: Vector3, result: RaycastResult, shape: number, size: number | Vector3)
	local color3 = wfh.Color3
	local travel
	if result then
		setColor(hitColor)
		travel = direction.Unit * result.Distance
		helper_drawHit(result)
	else
		setColor(missColor)
		travel = direction
	end
	if shape == 1 then -- sphere
		drawSphere(cf, size)
		drawSphere(cf + travel, size)
	elseif shape == 2 then -- block
		drawCube(cf, size)
		drawCube(cf + travel, size)
	end
	drawRay(cf.Position, travel)
	wfh.Color3 = color3
end

local function drawRaycast(origin: Vector3, direction: Vector3, result: RaycastResult)
	helper_drawRaycast(CFrame.new(origin), direction, result, 0)
end

local function drawSpherecast(origin: Vector3, radius: number, direction: Vector3, result: RaycastResult)
	helper_drawRaycast(CFrame.lookAlong(origin, direction), direction, result, 1, radius)
end

local function drawBlockcast(cf: CFrame, size: Vector3, direction: Vector3, result: RaycastResult)
	helper_drawRaycast(cf, direction, result, 2, size)
end

------------------------------------- PUBLIC

function Gizmos:SetColor(color: string | Color3)
	table.insert(commands, function()
		setColor(color)
	end)
end

function Gizmos:SetTransparency(value: number)
	table.insert(commands, function()
		setTransparency(value)
	end)
end

function Gizmos:DrawLine(from: Vector3, to: Vector3)
	table.insert(commands, function()
		drawLine(from, to)
	end)
end

function Gizmos:DrawRay(origin: Vector3, direction: Vector3)
	table.insert(commands, function()
		drawRay(origin, direction)
	end)
end

function Gizmos:DrawPath(points: {Vector3}, closed: boolean?, dotsSize: number?)
	table.insert(commands, function()
		drawPath(points, closed, dotsSize)
	end)
end

function Gizmos:DrawPoint(position: Vector3, size: number?)
	table.insert(commands, function()
		drawPoint(position, size)
	end)
end

function Gizmos:DrawCube(position: Vector3 | CFrame, size: Vector3)
	table.insert(commands, function()
		drawCube(position, size)
	end)
end

function Gizmos:DrawCircle(position: Vector3, radius: number, normal: Vector3?)
	table.insert(commands, function()
		drawCircle(position, radius, normal)
	end)
end

function Gizmos:DrawSphere(position: Vector3 | CFrame, radius: number)
	table.insert(commands, function()
		drawSphere(position, radius)
	end)
end

function Gizmos:DrawPyramid(position: Vector3 | CFrame, size: number, height: number)
	table.insert(commands, function()
		drawPyramid(position, size, height)
	end)
end

function Gizmos:DrawCFrame(cf: CFrame, size: number?, color: Color3?)
	table.insert(commands, function()
		drawCFrame(cf, size, color)
	end)
end

function Gizmos:DrawText(position: Vector3, ...) -- text: string, size: number?)
	local args = {...}
	table.insert(commands, function()
		drawText(position, unpack(args))
	end)
end

function Gizmos:DrawRaycast(origin: Vector3, direction: Vector3, result: RaycastResult)
	table.insert(commands, function()
		drawRaycast(origin, direction, result)
	end)
end

function Gizmos:DrawSpherecast(origin: Vector3, radius: number, direction: Vector3, result: RaycastResult)
	table.insert(commands, function()
		drawSpherecast(origin, radius, direction, result)
	end)
end

function Gizmos:DrawBlockcast(cf: CFrame, size: Vector3, direction: Vector3, result: RaycastResult)
	table.insert(commands, function()
		drawBlockcast(cf, size, direction, result)
	end)
end

function Gizmos:AddToPath(name: string, position: Vector3, dotsSize: number?)
	if not trailers[name] then
		trailers[name] = Trailer.new()
	end
	trailers[name]:addValue(position)
	table.insert(commands, function()
		drawPath(trailers[name]:getValues(), false, dotsSize)
	end)
end

----------------------------------------------

findOrMakeGizmos()

local function Update(dt)
	local t = tick()
	if t ~= wfh:GetAttribute('lastUpdateTime') then
		wfh:SetAttribute('lastUpdateTime', t)
		if Gizmos.Clear then
			wfh:Clear()
		end
	end
	for _, command in ipairs(commands) do
		command()
	end
	commands = {}
end

function Gizmos:ForceUpdate()
	wfh:Clear()

	for _, command in ipairs(commands) do
		command()
	end
	
	commands = {}
end

function Gizmos:Test()
	local p = Vector3.new(0, 0, 10)
	local x, y, z = Vector3.xAxis, Vector3.yAxis, Vector3.zAxis
	local function n() p += Vector3.xAxis*2 end

	-- all API
	Gizmos:SetColor('white')
	Gizmos:SetTransparency(0)
	Gizmos:DrawLine(p, p + y) n()
	Gizmos:DrawRay(p, y) n()
	Gizmos:DrawPath({ p+Vector3.new(-0.3,0,-0.3), p+Vector3.new(0.4,0,0), p+Vector3.new(0.1,0,0.5), p+Vector3.new(0.6,0,0.9)}) n()
	Gizmos:DrawPoint(p) n()
	Gizmos:DrawCube(p + y*0.5, Vector3.one) n()
	Gizmos:DrawCircle(p, 0.5) n()
	Gizmos:DrawSphere(p+y*0.5, 0.5) n()
	Gizmos:DrawPyramid(p, 1, 1) n()
	Gizmos:DrawCFrame(CFrame.new(p)) n()
	Gizmos:DrawText(p, 'Hello') n()
	Gizmos:DrawRaycast(p, z, nil) n()
	Gizmos:DrawSpherecast(p, 0.3, z, nil) n()
	Gizmos:DrawBlockcast(CFrame.new(p), Vector3.one*0.6, z, nil) n()

	local colors = {'red', 'orange', 'yellow', 'green', 'cyan', 'blue', 'purple', 'magenta', 'black', 'gray', 'white'}
	p = Vector3.new(0, 0, 12)
	for _, color in ipairs(colors) do
		Gizmos:SetColor(color)
		Gizmos:DrawCircle(p, 0.15)
		p += Vector3.xAxis*1
	end
end

local RunService = game:GetService('RunService')
if RunService:IsRunning() then
	RunService:BindToRenderStep('name', Enum.RenderPriority.Camera.Value-1, Update)
end

return Gizmos