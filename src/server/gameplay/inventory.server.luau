local ServerStorage = game:GetService("ServerStorage")

local attribute = require("../../shared/utils/attribute")
local guns = require("../../shared/constants/guns")
local observers = require("../../shared/utils/observers")

local gunIdAttribute = attribute<<string?>>("GunId")

local function cloneGunTool(gunId: string): Tool?
	local gun = guns.getGun(gunId)
	local gunTools = ServerStorage:WaitForChild("GunTools")
	local template = gunTools:FindFirstChild(gun.name)

	if not template or not template:IsA("Tool") then
		warn(`Missing gun tool template in ServerStorage.GunTools: {gun.name}`)
		return nil
	end

	local tool = template:Clone()
	gunIdAttribute.set(tool, gunId)
	return tool
end

observers.observePlayers(function(player)
	return observers.observeChildWhichIsA(player, "Backpack", function(backpack: Backpack)
		local tools: { Tool } = {}

		for _, gunId in guns.starterGunIds do
			local tool = cloneGunTool(gunId)
			if tool then
				tool.Parent = backpack
				table.insert(tools, tool)
			end
		end

		return function()
			for _, tool in tools do
				tool:Destroy()
			end
		end
	end)
end)
