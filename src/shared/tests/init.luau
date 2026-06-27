local test = require("../../tests/test")

test.describe("example", function()
	require("@self/example.test")
end)

test.describe("gunAmmoState", function()
	require("@self/gunAmmoState.test")
end)

return {}
