local guns = require("../../shared/constants/guns")

export type State = {
	ammo: number,
	reloading: boolean,
	reloadToken: number,
}

local function getMaxAmmo(gunStats: guns.GunInfo): number
	return gunStats.maxAmmo or 0
end

local function new(gunStats: guns.GunInfo): State
	return {
		ammo = getMaxAmmo(gunStats),
		reloading = false,
		reloadToken = 0,
	}
end

local function recordShot(state: State, gunStats: guns.GunInfo): boolean
	if not guns.hasAmmoLimit(gunStats) then
		return true
	end

	if state.reloading or state.ammo <= 0 then
		return false
	end

	state.ammo -= 1
	return true
end

local function beginReload(state: State, gunStats: guns.GunInfo): number?
	if not guns.hasAmmoLimit(gunStats) then
		return nil
	end

	if state.reloading or state.ammo >= getMaxAmmo(gunStats) then
		return nil
	end

	state.reloading = true
	state.reloadToken += 1

	return state.reloadToken
end

local function finishReload(state: State, gunStats: guns.GunInfo, reloadToken: number): boolean
	if state.reloadToken ~= reloadToken then
		return false
	end

	state.ammo = getMaxAmmo(gunStats)
	state.reloading = false

	return true
end

return {
	new = new,
	recordShot = recordShot,
	beginReload = beginReload,
	finishReload = finishReload,
}
