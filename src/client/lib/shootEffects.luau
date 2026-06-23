local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LightningModule = require("../../../modules/LightningModule")
local remotes = require("../../shared/remotes")

local player = Players.LocalPlayer
local rng = Random.new()

local BOLT_LENGTH = 10
local BOLT_SEGMENTS = 6

local BULLET_LIGHTNING: LightningModule.LightningInputData = {
	Color = Color3.fromRGB(160, 220, 255),
	Time = 0.1,
	Width = 0.5,
	Envelope = 0.4,
	Shift = 3.5,
}

local function performRaycast(origin: Vector3, direction: Vector3)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { player.Character :: Instance }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	local rayResult = workspace:Raycast(origin, direction, rayParams)
	local hitPos = rayResult and rayResult.Position or (origin + direction)

	return hitPos, rayResult
end

local function generateBoltPoints(
	tail: Vector3,
	head: Vector3,
	inputData: LightningModule.LightningInputData,
	segments: number,
	base: number
): { Vector3 }
	local points: { Vector3 } = {}

	for index = 0, segments do
		local noiseX = math.noise(base + index)
		local noiseY = math.noise(0, base + index)
		local noiseZ = math.noise(0, 0, base + index)
		local jitter = Vector3.new(noiseX, noiseY, noiseZ) * inputData.Shift / 2

		points[index + 1] = tail + index * (head - tail) / segments + jitter
	end

	points[segments + 1] = head
	return points
end

local function randomWidth(inputData: LightningModule.LightningInputData): number
	return rng:NextNumber(inputData.Width - inputData.Envelope / 2, inputData.Width + inputData.Envelope / 2)
end

local function createMovingBolt(inputData: LightningModule.LightningInputData)
	local attachments: { Attachment } = {}
	local beams: { Beam } = {}

	for index = 1, BOLT_SEGMENTS + 1 do
		local attachment = Instance.new("Attachment")
		attachment.Parent = workspace.Terrain
		attachments[index] = attachment
	end

	for index = 1, BOLT_SEGMENTS do
		local beam = Instance.new("Beam")
		beam.Name = "BulletLightning"
		beam.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 240, 255)),
			ColorSequenceKeypoint.new(0.5, inputData.Color),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 170, 255)),
		})
		beam.Width0 = randomWidth(inputData)
		beam.Width1 = randomWidth(inputData)
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.FaceCamera = true
		beam.Brightness = 4
		beam.Transparency = NumberSequence.new(0)
		beam.TextureSpeed = 2
		beam.Parent = workspace.Terrain
		beam.Attachment0 = attachments[index]
		beam.Attachment1 = attachments[index + 1]
		beams[index] = beam
	end

	local noiseBase = rng:NextNumber() * 300

	local function update(tail: Vector3, head: Vector3)
		noiseBase += rng:NextNumber(3, 8)

		local points = generateBoltPoints(tail, head, inputData, BOLT_SEGMENTS, noiseBase)

		for index, point in points do
			attachments[index].WorldPosition = point
		end

		for _, beam in beams do
			beam.Width0 = randomWidth(inputData)
			beam.Width1 = randomWidth(inputData)
		end
	end

	local function destroy()
		for _, beam in beams do
			local fade = TweenService:Create(
				beam,
				TweenInfo.new(inputData.Time * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					Width0 = 0,
					Width1 = 0,
					Brightness = 0,
				}
			)
			fade:Play()
		end

		task.delay(inputData.Time * 0.6, function()
			for _, beam in beams do
				beam:Destroy()
			end
			for _, attachment in attachments do
				attachment:Destroy()
			end
		end)
	end

	return update, destroy
end

local function showMovingLightningBolt(origin: Vector3, unitDir: Vector3, speed: number, range: number)
	local tailPos = origin
	local headPos = tailPos + unitDir * BOLT_LENGTH
	local traveled = 0
	local updateBolt, destroyBolt = createMovingBolt(BULLET_LIGHTNING)
	local connection: RBXScriptConnection

	updateBolt(tailPos, headPos)

	connection = RunService.RenderStepped:Connect(function(dt)
		local step = math.min(speed * dt, range - traveled)
		if step <= 0 then
			connection:Disconnect()
			destroyBolt()
			return
		end

		local hitPos, rayResult = performRaycast(headPos, unitDir * step)

		if rayResult then
			updateBolt(tailPos, hitPos)
			connection:Disconnect()
			destroyBolt()
			return
		end

		tailPos += unitDir * step
		headPos = tailPos + unitDir * BOLT_LENGTH
		traveled += step

		updateBolt(tailPos, headPos)

		if traveled >= range then
			connection:Disconnect()
			destroyBolt()
		end
	end)
end

remotes.gunEffect.OnClientEvent:Connect(function(args)
	if not args or args.effect ~= "LightningShot" then
		return
	end

	local origin = args.origin
	local unitDir = args.direction
	local speed = args.bulletSpeed
	local range = args.range

	if not origin or not unitDir or not speed or not range then
		return
	end

	showMovingLightningBolt(origin, unitDir, speed, range)
end)

return {}
