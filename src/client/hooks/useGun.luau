local Vide = require("../../../modules/Vide")
local guns = require("../../shared/constants/guns")
local useCharacter = require("./useCharacter")
local useEventListener = require("./useEventListener")

local function useGun(): () -> guns.GunInfo?
	local currentGun = Vide.source(nil :: guns.GunInfo?)
	local getCharacter = useCharacter()

	Vide.effect(function()
		local character = getCharacter()

		if not character then
			return
		end

		local function updateCurrentGun()
			local tool = character:FindFirstChildWhichIsA("Tool")
			local gun = tool and guns.getGunByName(tool.Name)
			currentGun(gun)
		end

		useEventListener(character.ChildAdded, function(child: Instance)
			if child:IsA("Tool") then
				updateCurrentGun()
			end
		end)

		useEventListener(character.ChildRemoved, function(child: Instance)
			if child:IsA("Tool") then
				updateCurrentGun()
			end
		end)

		updateCurrentGun()

		Vide.cleanup(function()
			currentGun(nil)
		end)
	end)

	return currentGun
end

return useGun
