local gunAmmoState = require("../../server/gameplay/gunAmmoState")
local guns = require("../constants/guns")
local test = require("../../../tests/test")

local limitedGun: guns.GunInfo = {
	name = "Test Rifle",
	description = "Test",
	damage = 1,
	headshotMultiplier = 1,
	range = 100,
	automatic = false,
	fireRate = 1,
	maxAmmo = 2,
	reloadTime = 1,
}

local unlimitedGun: guns.GunInfo = {
	name = "Test Pistol",
	description = "Test",
	damage = 1,
	headshotMultiplier = 1,
	range = 100,
	automatic = false,
	fireRate = 1,
	maxAmmo = 0,
	reloadTime = 1,
}

test("should consume ammo and block empty magazines", function()
	local state = gunAmmoState.new(limitedGun)

	if not gunAmmoState.recordShot(state, limitedGun) then
		error("expected first shot to be accepted")
	end
	if state.ammo ~= 1 then
		error(`expected 1 ammo, got {state.ammo}`)
	end

	if not gunAmmoState.recordShot(state, limitedGun) then
		error("expected second shot to be accepted")
	end
	if state.ammo ~= 0 then
		error(`expected 0 ammo, got {state.ammo}`)
	end

	if gunAmmoState.recordShot(state, limitedGun) then
		error("expected empty magazine shot to be rejected")
	end
end)

test("should block shots while reloading and refill on matching token", function()
	local state = gunAmmoState.new(limitedGun)
	gunAmmoState.recordShot(state, limitedGun)

	local reloadToken = gunAmmoState.beginReload(state, limitedGun)
	if not reloadToken then
		error("expected reload to start")
	end
	if gunAmmoState.recordShot(state, limitedGun) then
		error("expected reloading shot to be rejected")
	end

	if gunAmmoState.finishReload(state, limitedGun, reloadToken + 1) then
		error("expected stale reload token to be rejected")
	end
	if state.ammo ~= 1 or not state.reloading then
		error("expected stale reload to leave state unchanged")
	end

	if not gunAmmoState.finishReload(state, limitedGun, reloadToken) then
		error("expected reload to finish")
	end
	if state.ammo ~= 2 or state.reloading then
		error("expected magazine to be refilled")
	end
end)

test("should allow unlimited-ammo guns without consuming ammo", function()
	local state = gunAmmoState.new(unlimitedGun)

	if not gunAmmoState.recordShot(state, unlimitedGun) then
		error("expected unlimited-ammo shot to be accepted")
	end
	if state.ammo ~= 0 then
		error(`expected unlimited ammo state to stay 0, got {state.ammo}`)
	end
	if gunAmmoState.beginReload(state, unlimitedGun) ~= nil then
		error("expected unlimited-ammo gun not to reload")
	end
end)

return {}
