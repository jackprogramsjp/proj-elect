local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LightningModule = require("../../../modules/LightningModule")
local bulletAssets = require("../../shared/constants/bulletAssets")
local remotes = require("../../shared/remotes")

local player = Players.LocalPlayer

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

	lightningAlongPart(bullet)

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
			connection:Disconnect()
			return
		end

		bullet.CFrame = CFrame.new(nextPos, nextPos + unitDir)
		lightningAlongPart(bullet)
		traveled += step

		if traveled >= range then
			bullet:Destroy()
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
