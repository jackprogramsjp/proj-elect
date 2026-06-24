local Players = game:GetService("Players")

local guns = require("../../shared/constants/guns")
local remotes = require("../../shared/remotes")

local SERVER_FIRE_RATE_LIMIT = 50

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

local function getRaycastFilter(player: Player): { Instance }
	local character = player.Character
	if not character then
		return {}
	end

	return { character }
end

local function performRaycast(player: Player, origin: Vector3, direction: Vector3)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = getRaycastFilter(player)
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

local function fireGunEffect(payload: { [string]: any })
	remotes.gunEffect:FireAllClients(payload)
end

local function getEquippedGun(player: Player, gun: any): Tool?
	if typeof(gun) ~= "Instance" or not gun:IsA("Tool") then
		return nil
	end

	local character = player.Character
	if not character or not gun:IsDescendantOf(character) then
		return nil
	end

	return gun
end

local function getShootOrigin(gun: Tool): Vector3?
	local shootPart = gun:FindFirstChild("ShootPart")
	if not shootPart or not shootPart:IsA("BasePart") then
		return nil
	end

	return shootPart.Position
end

remotes.shootGun.OnServerEvent:Connect(function(player: Player, gun: any, _clientOrigin: any, targetPos: any)
	local equippedGun = getEquippedGun(player, gun)
	if not equippedGun or typeof(targetPos) ~= "Vector3" then
		return
	end

	local origin = getShootOrigin(equippedGun)
	if not origin then
		return
	end

	local gunStats = guns.getGunByName(equippedGun.Name)
	if not gunStats then
		return
	end

	local st = ensureState(player)
	local now = tick() * 1000
	if now - st.lastShot < SERVER_FIRE_RATE_LIMIT then
		return
	end
	st.lastShot = now

	playSound("Shoot", equippedGun)

	local direction = targetPos - origin
	local distanceToTarget = direction.Magnitude
	if distanceToTarget <= 0.001 then
		return
	end

	local dirUnit = direction.Unit

	if not gunStats.bulletSpeed then
		local rayDir = dirUnit * math.min(distanceToTarget, gunStats.range)
		local hitPos, rayResult = performRaycast(player, origin, rayDir)
		applyDamage(player, gunStats, rayResult)
		fireGunEffect({
			effect = "BulletTrail",
			origin = origin,
			hitPos = hitPos,
		})
		return
	end

	local bulletSpeed = gunStats.bulletSpeed
	local stepTime = 0.1
	local stepDistance = bulletSpeed * stepTime
	local traveled = 0
	local position = origin

	fireGunEffect({
		effect = "BulletShot",
		origin = origin,
		direction = dirUnit,
		bulletSpeed = bulletSpeed,
		range = gunStats.range,
	})

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
