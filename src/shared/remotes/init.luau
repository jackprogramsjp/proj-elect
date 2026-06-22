local gt = require("../../modules/gt")
local lib = require("@self/lib")

return {
	assert = lib.assert,
	patch = lib.event(gt.anyTable()),
	shootGun = lib.event(gt.isA.Tool(), gt.Vector3(), gt.Vector3()),
	gunEffect = lib.event(gt.anyTable()),
}
