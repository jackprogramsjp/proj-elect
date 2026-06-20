local Players = game:GetService("Players")

local CharmSync = require("../../../modules/CharmSync")
local appStore = require("../stores/appStore")
local gameStore = require("../../shared/stores/gameStore")
local remotes = require("../../shared/remotes")

CharmSync.client.addSignals({
	game = gameStore.setState,
	[`account-{Players.LocalPlayer.Name}`] = appStore.setAccount,
})

remotes.patch.OnClientEvent:Connect(function(patches)
	CharmSync.client.patch(patches)
end)
