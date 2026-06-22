local Vide = require("../../../modules/Vide")
local VideCharm = require("../../../modules/VideCharm")
local ammoStore = require("../stores/ammoStore")
local fonts = require("../utils/fonts")
local px = require("../utils/px")

local create = Vide.create
local useAtom = VideCharm.useAtom

local function AmmoHud()
	px.usePx()

	local ammoState = useAtom(ammoStore.getAmmoState)

	return create("ScreenGui")({
		Name = "AmmoHud",
		ResetOnSpawn = false,
		DisplayOrder = 10,
		Enabled = Vide.derive(function()
			return ammoState().visible
		end),

		create("TextLabel")({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = px.udim2(0.5, 0, 1, -24),
			Size = px.offset(180, 36),
			BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = px(20),
			FontFace = fonts.inter.semibold,
			TextStrokeTransparency = 0.5,
			Visible = Vide.derive(function()
				return ammoState().visible
			end),
			Text = Vide.derive(function()
				local state = ammoState()
				if state.reloading then
					return "reloading..."
				end
				return `{state.current} / {state.max}`
			end),
		}),
	})
end

return AmmoHud
