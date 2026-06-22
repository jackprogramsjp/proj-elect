local Players = game:GetService("Players")

local gunController = require("./gunController")
local guns = require("../../shared/constants/guns")
local observers = require("../../shared/utils/observers")

local function connectGunTool(tool: Tool): (() -> ())?
	if not guns.getGunByName(tool.Name) then
		return nil
	end

	return gunController.connect(tool)
end

local function observeCharacterTools(character: Model): () -> ()
	local cleanup: (() -> ())?

	local function updateEquippedTool()
		if cleanup then
			cleanup()
			cleanup = nil
		end

		local tool = character:FindFirstChildWhichIsA("Tool")
		if tool then
			cleanup = connectGunTool(tool)
		end
	end

	local childAdded = character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			updateEquippedTool()
		end
	end)

	local childRemoved = character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			updateEquippedTool()
		end
	end)

	updateEquippedTool()

	return function()
		childAdded:Disconnect()
		childRemoved:Disconnect()
		if cleanup then
			cleanup()
		end
	end
end

observers.observePlayers(function(observedPlayer)
	if observedPlayer ~= Players.LocalPlayer then
		return nil
	end

	return observers.observeCharacter(observedPlayer, observeCharacterTools)
end)

return {}
