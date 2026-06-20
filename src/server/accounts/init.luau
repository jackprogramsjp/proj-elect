local objects = require("../shared/utils/objects")
local store = require("@self/store")
local types = require("../shared/types")

type Account = types.Account

local function addGold(player: Player, amount: number)
	return store:updateImmutable(player, function(account: Account)
		return objects.join(account, {
			gold = account.gold + amount,
		})
	end)
end

return {
	addGold = addGold,
}
