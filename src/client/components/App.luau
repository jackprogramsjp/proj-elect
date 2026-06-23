local Vide = require("../../../modules/Vide")
local WeldButton = require("./WeldButton")
local px = require("../utils/px")

local create = Vide.create

local function App()
	px.usePx()

	return create("ScreenGui")({
		Name = "App",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		create("Frame")({
			Name = "TopBar",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.03),
			Size = UDim2.fromScale(0.48, 0.1),
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0.03, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			WeldButton({
				text = "Loadout",
				color = Color3.fromRGB(72, 168, 83),
				layoutOrder = 1,
				size = UDim2.fromScale(0.3, 0.92),
				onActivated = function() end,
			}),

			WeldButton({
				text = "Launch",
				color = Color3.fromRGB(139, 90, 43),
				layoutOrder = 2,
				size = UDim2.fromScale(0.3, 0.92),
				onActivated = function() end,
			}),

			WeldButton({
				text = "Guns",
				color = Color3.fromRGB(232, 185, 35),
				layoutOrder = 3,
				size = UDim2.fromScale(0.3, 0.92),
				onActivated = function() end,
			}),
		}),
	})
end

return App
