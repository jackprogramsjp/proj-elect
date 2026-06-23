local Vide = require("../../../modules/Vide")
local WeldFrame = require("./WeldFrame")
local fonts = require("../utils/fonts")
local px = require("../utils/px")

local create = Vide.create
local source = Vide.source
local spring = Vide.spring

export type Props = {
	text: string,
	color: Color3,
	size: UDim2 | () -> UDim2,
	position: (UDim2 | () -> UDim2)?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	zIndex: number?,
	gradient: boolean?,
	cornerRadius: (UDim | () -> UDim)?,
	stroke: WeldFrame.StrokeProps?,
	onActivated: ((inputObject: InputObject, clickCount: number) -> ())?,
}

local function WeldButton(props: Props)
	px.usePx()

	local hovered = source(false)
	local buttonScale = spring(function()
		return if hovered() then 1.08 else 1
	end, 0.28, 0.65)

	return WeldFrame.WeldFrame({
		color = props.color,
		size = props.size,
		position = props.position,
		anchorPoint = props.anchorPoint,
		layoutOrder = props.layoutOrder,
		zIndex = props.zIndex,
		name = props.text,
		gradient = props.gradient,
		cornerRadius = props.cornerRadius,
		stroke = props.stroke,
		scale = buttonScale,
		children = {
			create("TextButton")({
				Name = "Button",
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = true,
				Text = "",
				ZIndex = 1000,

				MouseEnter = function()
					hovered(true)
				end,
				MouseLeave = function()
					hovered(false)
				end,
				Activated = props.onActivated,

				create("TextLabel")({
					Name = "Label",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = props.text,
					FontFace = fonts.inter.bold,
					TextScaled = true,
					TextColor3 = Color3.new(1, 1, 1),
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					ZIndex = 1,

					create("UIStroke")({
						ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
						Color = Color3.new(0, 0, 0),
						Thickness = px(2),
						Transparency = 0,
					}),
				}),
			}),
		},
	})
end

return WeldButton
