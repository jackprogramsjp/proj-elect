local attribute = require("../utils/attribute")

export type GunInfo = {
	name: string,
	description: string,
	damage: number,
	headshotMultiplier: number,
	range: number,
	bulletSpeed: number?,
	automatic: boolean,
	fireRate: number,
	maxAmmo: number?,
	reloadTime: number,
}

local gunsById: { [string]: GunInfo } = {
	pistol = {
		name = "Pistol",
		description = "A reliable sidearm for close-range encounters.",
		damage = 15,
		headshotMultiplier = 2,
		range = 200,
		bulletSpeed = 150,
		automatic = false,
		fireRate = 10,
		maxAmmo = 0,
		reloadTime = 1.8,
	},
	mp4 = {
		name = "MP4",
		description = "A compact SMG with a high fire rate.",
		damage = 12,
		headshotMultiplier = 1.5,
		range = 150,
		bulletSpeed = 200,
		automatic = true,
		fireRate = 12,
		maxAmmo = 40,
		reloadTime = 2.2,
	},
	ak47 = {
		name = "AK-47",
		description = "A powerful rifle with strong damage at range.",
		damage = 22,
		headshotMultiplier = 2,
		range = 300,
		bulletSpeed = nil,
		automatic = true,
		fireRate = 6,
		maxAmmo = 30,
		reloadTime = 2.5,
	},
}

local starterGunIds = { "pistol", "mp4", "ak47" }

local gunIdAttribute = attribute<<string?>>("GunId")

local function getGun(gunId: string): GunInfo
	return assert(gunsById[gunId], `Failed to get gun {gunId}`)
end

local function getGunByName(toolName: string): GunInfo?
	for _, gun in gunsById do
		if gun.name == toolName then
			return gun
		end
	end
	return nil
end

local function hasAmmoLimit(gun: GunInfo): boolean
	return gun.maxAmmo ~= nil and gun.maxAmmo > 0
end

local function getGunIdFromTool(tool: Tool): string?
	local gunId = gunIdAttribute.get(tool)
	return if type(gunId) == "string" and gunsById[gunId] then gunId else nil
end

local function getGunIdFromCharacter(character: Model): string?
	local tool = character and character:FindFirstChildWhichIsA("Tool")
	return tool and getGunIdFromTool(tool)
end

return {
	gunsById = gunsById,
	starterGunIds = starterGunIds,
	getGun = getGun,
	getGunByName = getGunByName,
	hasAmmoLimit = hasAmmoLimit,
	getGunIdFromTool = getGunIdFromTool,
	getGunIdFromCharacter = getGunIdFromCharacter,
}
