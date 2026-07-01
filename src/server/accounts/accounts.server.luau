local Players = game:GetService("Players")

local accountStore = require("../stores/accountStore")
local store = require("./store")

Players.PlayerAdded:Connect(function(player)
	store:load(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local ok, err = pcall(function()
		store:unloadAsync(player)
	end)

	if not ok then
		warn(`Failed to unload account for {player.Name}: {err}`)
	end

	accountStore.removeAccount(player.Name)
end)

game:BindToClose(function()
	store:closeAsync()
end)
