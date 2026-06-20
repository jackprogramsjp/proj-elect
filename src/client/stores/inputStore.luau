local UserInputService = game:GetService("UserInputService")

local Charm = require("../../../modules/Charm")

export type PreferredInput = "keyboard" | "gamepad" | "touch"

local function getInitialInput(): PreferredInput
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "touch"
	elseif UserInputService.GamepadEnabled then
		return "gamepad"
	end
	return "keyboard"
end

local getPreferredInput, setPreferredInput = Charm.signal(getInitialInput())

return {
	getPreferredInput = getPreferredInput,
	setPreferredInput = setPreferredInput,
}
