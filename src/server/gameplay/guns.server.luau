local Players = game:GetService("Players")

local guns = require("../../shared/constants/guns")
local remotes = require("../../shared/remotes")

local SERVER_FIRE_RATE_LIMIT = 50
local HITSCAN_VISUAL_SPEED = 1200

type PlayerState = {
	lastShot: number,
}

local playerState: { [Player]: PlayerState } = {}

local function ensureState(player: Player): PlayerState
	local state = playerState[player]
	if not state then
		state = { lastShot = 0 }
		playerState[player] = state
	end
	return state
end

local function playSound(name: string, gun: Tool)
	local handle = gun:FindFirstChild("Handle")
	if not handle then
		return
	end

	local soundTemplate = handle:FindFirstChild(name)
	if not soundTemplate then
		return
	end

	local sound = soundTemplate:Clone()
	sound.Parent = handle
	sound:Destroy()
end

local function performRaycast(player: Player, origin: Vector3, direction: Vector3)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { player.Character :: Instance }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	local rayResult = workspace:Raycast(origin, direction, rayParams)
	local hitPos = rayResult and rayResult.Position or (origin + direction)

	return hitPos, rayResult
end

local function applyDamage(player: Player, gunStats: guns.GunInfo, rayResult: RaycastResult?)
	if not rayResult then
		return
	end

	local hitPart = rayResult.Instance
	local targetModel = hitPart and hitPart:FindFirstAncestorOfClass("Model")
	local humanoid = targetModel and targetModel:FindFirstChildOfClass("Humanoid")

	if humanoid and humanoid.Parent ~= player.Character then
		local damage = gunStats.damage
		if hitPart.Name == "Head" then
			damage *= gunStats.headshotMultiplier
		end
		humanoid:TakeDamage(damage)
	end
end

local function fireLightningShot(origin: Vector3, direction: Vector3, bulletSpeed: number, range: number)
	remotes.gunEffect:FireAllClients({
		effect = "LightningShot",
		origin = origin,
		direction = direction,
		bulletSpeed = bulletSpeed,
		range = range,
	})
end

remotes.shootGun.OnServerEvent:Connect(function(player: Player, gun: Tool, origin: Vector3, targetPos: Vector3)
	if not gun or not origin or not targetPos then
		return
	end

	local st = ensureState(player)
	local now = tick() * 1000
	if now - st.lastShot < SERVER_FIRE_RATE_LIMIT then
		return
	end
	st.lastShot = now

	playSound("Shoot", gun)

	local gunStats = guns.getGunByName(gun.Name)
	if not gunStats then
		return
	end

	local direction = targetPos - origin
	local distanceToTarget = direction.Magnitude
	if distanceToTarget <= 0.001 then
		return
	end

	local dirUnit = direction.Unit

	if not gunStats.bulletSpeed then
		local travelRange = math.min(distanceToTarget, gunStats.range)
		local rayDir = dirUnit * travelRange
		local _, rayResult = performRaycast(player, origin, rayDir)
		applyDamage(player, gunStats, rayResult)
		fireLightningShot(origin, dirUnit, HITSCAN_VISUAL_SPEED, travelRange)
		return
	end

	local bulletSpeed = gunStats.bulletSpeed
	local stepTime = 0.1
	local stepDistance = bulletSpeed * stepTime
	local traveled = 0
	local position = origin

	fireLightningShot(origin, dirUnit, bulletSpeed, gunStats.range)

	while traveled < gunStats.range do
		local nextDir = dirUnit * stepDistance
		local _, rayResult = performRaycast(player, position, nextDir)

		if rayResult then
			applyDamage(player, gunStats, rayResult)
			break
		end

		position += nextDir
		traveled += stepDistance
	end
end)

Players.PlayerRemoving:Connect(function(player)
	playerState[player] = nil
end)
