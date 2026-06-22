local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local bulletAssets = require("../../shared/constants/bulletAssets")
local remotes = require("../../shared/remotes")

local bulletTrail = bulletAssets.createBulletTrail()
local bulletTemplate = bulletAssets.createBullet()
local player = Players.LocalPlayer

local function performRaycast(origin: Vector3, direction: Vector3)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { player.Character :: Instance }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	local rayResult = workspace:Raycast(origin, direction, rayParams)
	local hitPos = rayResult and rayResult.Position or (origin + direction)

	return hitPos, rayResult
end

remotes.gunEffect.OnClientEvent:Connect(function(args)
	if not args then
		return
	end

	if args.effect == "BulletTrail" then
		local hitPos = args.hitPos
		local origin = args.origin
		if not origin or not hitPos then
			return
		end

		local trail = bulletTrail:Clone()
		trail.Parent = workspace

		local direction = hitPos - origin
		local distance = direction.Magnitude
		local midPoint = (origin + hitPos) / 2
		trail.CFrame = CFrame.new(midPoint, hitPos)
		trail.Size = Vector3.new(trail.Size.X, trail.Size.Y, distance)

		local tween = TweenService:Create(trail, TweenInfo.new(0.2), {
			Transparency = 1,
		})
		tween:Play()

		Debris:AddItem(trail, 0.3)
	elseif args.effect == "BulletShot" then
		local origin = args.origin
		local unitDir = args.direction
		local speed = args.bulletSpeed
		local range = args.range

		if not origin or not unitDir or not speed or not range then
			return
		end

		local newBullet = bulletTemplate:Clone()
		newBullet.CFrame = CFrame.new(origin, origin + unitDir)
		newBullet.Parent = workspace

		local traveled = 0
		local connection: RBXScriptConnection
		connection = RunService.RenderStepped:Connect(function(dt)
			local step = speed * dt
			local currentPos = newBullet.Position
			local nextPos = currentPos + unitDir * step
			local direction = nextPos - currentPos
			local _, rayResult = performRaycast(currentPos, direction)

			if rayResult then
				newBullet:Destroy()
				connection:Disconnect()
				return
			end

			newBullet.CFrame = CFrame.new(nextPos, nextPos + unitDir)
			traveled += step

			if traveled >= range then
				newBullet:Destroy()
				connection:Disconnect()
			end
		end)
	end
end)

return {}
