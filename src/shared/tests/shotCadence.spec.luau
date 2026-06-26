local assert = require("@std/test/assert")
local test = require("@std/test")

local shotCadence = require("../../server/gameplay/shotCadence")

test.case("blocks shots before configured gun fire rate allows them", function()
	local ak47 = { fireRate = 6 }
	local firstShotMs = 1_000

	assert.eq(shotCadence.canShoot(firstShotMs, firstShotMs + 100, ak47, 50), false)
	assert.eq(shotCadence.canShoot(firstShotMs, firstShotMs + 167, ak47, 50), true)
end)

test.case("keeps global floor for very fast fire rates", function()
	local fastGun = { fireRate = 100 }
	local firstShotMs = 1_000

	assert.eq(shotCadence.getMinimumShotIntervalMs(fastGun, 50), 50)
	assert.eq(shotCadence.canShoot(firstShotMs, firstShotMs + 49, fastGun, 50), false)
	assert.eq(shotCadence.canShoot(firstShotMs, firstShotMs + 50, fastGun, 50), true)
end)
