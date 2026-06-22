local Charm = require("../../../modules/Charm")

export type AmmoState = {
	current: number,
	max: number,
	reloading: boolean,
	visible: boolean,
}

local ammoTemplate: AmmoState = {
	current = 0,
	max = 0,
	reloading = false,
	visible = false,
}

local getAmmoState, setAmmoState = Charm.signal(ammoTemplate)

return {
	getAmmoState = getAmmoState,
	setAmmoState = setAmmoState,
}
