local Charm = require("../../../modules/Charm")
local gameStore = require("../../shared/stores/gameStore")
local types = require("../../shared/types")

local getAccount, setAccount = Charm.signal(types.accountTemplate)

local getGameState = Charm.computed(function()
	return gameStore.getState()
end)

return {
	getAccount = getAccount,
	setAccount = setAccount,
	getGameState = getGameState,
}
