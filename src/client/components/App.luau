local Vide = require("../../../modules/Vide")
local useGun = require("../hooks/useGun")

local create = Vide.create

local function App()
	local getGun = useGun()

	return create("ScreenGui")({
		Name = "App",

		create("TextLabel")({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(260, 50),
			BackgroundTransparency = 1,
			Text = Vide.derive(function()
				local gun = getGun()
				return if gun then `Equipped: {gun.name}` else "proj-elect"
			end),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 24,
			Font = Enum.Font.GothamBold,
		}),
	})
end

return App
