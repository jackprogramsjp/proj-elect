local bulletTemplate = Instance.new("Part")
bulletTemplate.Name = "Bullet"
bulletTemplate.Shape = Enum.PartType.Block
bulletTemplate.Size = Vector3.new(0.1, 0.1, 6)
bulletTemplate.Color = Color3.fromRGB(254, 183, 24)
bulletTemplate.Material = Enum.Material.Neon
bulletTemplate.Anchored = true
bulletTemplate.CanCollide = false
bulletTemplate.CanQuery = false
bulletTemplate.CastShadow = false

local bulletTrailTemplate = Instance.new("Part")
bulletTrailTemplate.Name = "BulletTrail"
bulletTrailTemplate.Shape = Enum.PartType.Block
bulletTrailTemplate.Size = Vector3.new(0.1, 0.1, 20.9)
bulletTrailTemplate.Color = Color3.fromRGB(255, 255, 255)
bulletTrailTemplate.Material = Enum.Material.Neon
bulletTrailTemplate.Anchored = true
bulletTrailTemplate.CanCollide = false
bulletTrailTemplate.CanQuery = false
bulletTrailTemplate.CastShadow = false

local function createBullet(): Part
	return bulletTemplate:Clone()
end

local function createBulletTrail(): Part
	return bulletTrailTemplate:Clone()
end

return {
	createBullet = createBullet,
	createBulletTrail = createBulletTrail,
}
