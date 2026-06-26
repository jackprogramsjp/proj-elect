local test = require("../../tests/test")

test.describe("example", function()
	require("@self/example.test")
end)

test.describe("shotCadence", function()
	require("@self/shotCadence.test")
end)

return {}
