local test = require("../../../tests/test")

local shotCadence = require("../../server/gameplay/shotCadence")

test("blocks shots before configured gun fire rate allows them", function()
	local ak47 = { fireRate = 6 }
	local firstShotMs = 1_000

	if shotCadence.canShoot(firstShotMs, firstShotMs + 100, ak47, 50) then
		error("expected shot before configured interval to be blocked")
	end

	if not shotCadence.canShoot(firstShotMs, firstShotMs + 167, ak47, 50) then
		error("expected shot after configured interval to be allowed")
	end
end)

test("keeps global floor for very fast fire rates", function()
	local fastGun = { fireRate = 100 }
	local firstShotMs = 1_000

	if shotCadence.getMinimumShotIntervalMs(fastGun, 50) ~= 50 then
		error("expected global floor to cap very fast fire rates")
	end

	if shotCadence.canShoot(firstShotMs, firstShotMs + 49, fastGun, 50) then
		error("expected shot before global floor to be blocked")
	end

	if not shotCadence.canShoot(firstShotMs, firstShotMs + 50, fastGun, 50) then
		error("expected shot at global floor to be allowed")
	end
end)

return {}
