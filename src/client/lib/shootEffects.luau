local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LightningModule = require("../../../modules/LightningModule")
local bulletAssets = require("../../shared/constants/bulletAssets")
local remotes = require("../../shared/remotes")

local player = Players.LocalPlayer
local rng = Random.new()

local PROJECTILE_BOLT_SEGMENTS = 4

local BULLET_LIGHTNING: LightningModule.LightningInputData = {
	Color = Color3.fromRGB(160, 220, 255),
	Time = 0.12,
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

local function getPartEndpoints(part: BasePart): (Vector3, Vector3)
	local halfLength = part.Size.Z / 2
	local tail = (part.CFrame * CFrame.new(0, 0, -halfLength)).Position
	local head = (part.CFrame * CFrame.new(0, 0, halfLength)).Position
	return tail, head
end

local function bulletCFrameAtTail(tail: Vector3, unitDir: Vector3, halfLength: number): CFrame
	local center = tail + unitDir * halfLength
	return CFrame.new(center, center + unitDir)
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

local function createProjectileBolt(inputData: LightningModule.LightningInputData)
	local attachments: { Attachment } = {}
	local beams: { Beam } = {}

	for index = 1, PROJECTILE_BOLT_SEGMENTS + 1 do
		local attachment = Instance.new("Attachment")
		attachment.Parent = workspace.Terrain
		attachments[index] = attachment
	end

	for index = 1, PROJECTILE_BOLT_SEGMENTS do
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
	local destroyed = false

	local function update(tail: Vector3, head: Vector3)
		if destroyed then
			return
		end

		noiseBase += rng:NextNumber(3, 8)
		local points = generateBoltPoints(tail, head, inputData, PROJECTILE_BOLT_SEGMENTS, noiseBase)

		for index, point in points do
			attachments[index].WorldPosition = point
		end

		for _, beam in beams do
			beam.Width0 = randomWidth(inputData)
			beam.Width1 = randomWidth(inputData)
		end
	end

	local function destroy()
		if destroyed then
			return
		end
		destroyed = true

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

local function lightningAlongPart(part: BasePart)
	local tail, head = getPartEndpoints(part)
	local distance = (head - tail).Magnitude
	if distance < 0.001 then
		return
	end

	local segments = math.clamp(math.floor(distance / 2), 2, 8)
	task.spawn(LightningModule.Line, tail, head, BULLET_LIGHTNING, segments, 1)
end

local function showBulletTrail(origin: Vector3, hitPos: Vector3)
	local trail = bulletAssets.createBulletTrail()
	trail.Parent = workspace

	local midPoint = (origin + hitPos) / 2
	trail.CFrame = CFrame.new(midPoint, hitPos)

	local distance = (hitPos - origin).Magnitude
	trail.Size = Vector3.new(trail.Size.X, trail.Size.Y, distance)

	lightningAlongPart(trail)
	trail:Destroy()
end

local function showBulletShot(origin: Vector3, unitDir: Vector3, speed: number, range: number)
	local bullet = bulletAssets.createBullet()
	local halfLength = bullet.Size.Z / 2
	bullet.CFrame = bulletCFrameAtTail(origin, unitDir, halfLength)
	bullet.Parent = workspace

	local updateBolt, destroyBolt = createProjectileBolt(BULLET_LIGHTNING)
	updateBolt(getPartEndpoints(bullet))

	local traveled = 0
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt)
		local step = speed * dt
		local currentPos = bullet.Position
		local nextPos = currentPos + unitDir * step
		local direction = nextPos - currentPos
		local _, rayResult = performRaycast(currentPos, direction)

		if rayResult then
			bullet:Destroy()
			destroyBolt()
			connection:Disconnect()
			return
		end

		bullet.CFrame = CFrame.new(nextPos, nextPos + unitDir)
		updateBolt(getPartEndpoints(bullet))
		traveled += step

		if traveled >= range then
			bullet:Destroy()
			destroyBolt()
			connection:Disconnect()
		end
	end)
end

remotes.gunEffect.OnClientEvent:Connect(function(args)
	if not args then
		return
	end

	if args.effect == "BulletTrail" then
		local origin = args.origin
		local hitPos = args.hitPos
		if origin and hitPos then
			showBulletTrail(origin, hitPos)
		end
	elseif args.effect == "BulletShot" then
		local origin = args.origin
		local direction = args.direction
		local bulletSpeed = args.bulletSpeed
		local range = args.range
		if origin and direction and bulletSpeed and range then
			showBulletShot(origin, direction, bulletSpeed, range)
		end
	end
end)

return {}
