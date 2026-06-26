local DEFAULT_MIN_INTERVAL_MS = 50

export type GunCadence = {
	fireRate: number,
}

local function getMinimumShotIntervalMs(gunStats: GunCadence, floorMs: number?): number
	local fireRate = gunStats.fireRate
	if fireRate <= 0 then
		return math.huge
	end

	return math.max(floorMs or DEFAULT_MIN_INTERVAL_MS, 1000 / fireRate)
end

local function canShoot(lastShotMs: number, nowMs: number, gunStats: GunCadence, floorMs: number?): boolean
	return nowMs - lastShotMs >= getMinimumShotIntervalMs(gunStats, floorMs)
end

return table.freeze({
	DEFAULT_MIN_INTERVAL_MS = DEFAULT_MIN_INTERVAL_MS,
	getMinimumShotIntervalMs = getMinimumShotIntervalMs,
	canShoot = canShoot,
})
