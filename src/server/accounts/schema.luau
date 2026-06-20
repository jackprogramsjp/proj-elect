local gt = require("../../../modules/gt")
local types = require("../../shared/types")

type Account = types.Account

local accountSchema: Account = gt.table({
	gold = gt.number(),
})

return gt.build(accountSchema)
