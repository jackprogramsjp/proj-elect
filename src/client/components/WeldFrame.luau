local Vide = require("../../../modules/Vide")

local create = Vide.create

export type StrokeProps = {
	color: Color3?,
	thickness: number?,
	transparency: number?,
	applyStrokeMode: Enum.ApplyStrokeMode?,
	lineJoinMode: Enum.LineJoinMode?,
	borderStrokePosition: Enum.BorderStrokePosition?,
}

export type Props = {
	color: Color3,
	size: UDim2 | () -> UDim2,
	position: (UDim2 | () -> UDim2)?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	zIndex: number?,
	name: string?,
	gradient: boolean?,
	cornerRadius: (UDim | () -> UDim)?,
	stroke: StrokeProps?,
	scale: (() -> number)?,
	children: { Instance }?,
}

local WELD_IMAGE = "rbxassetid://132672788984843"
local DEFAULT_CORNER_RADIUS = UDim.new(0.18, 0)

-- Weld tile image: oversized relative to frame so ClippedDescendantsFrame clips the overflow.
local WELD_SIZE = UDim2.fromScale(15, 15)
local WELD_TILE_SIZE = UDim2.fromScale(0.200000003, 0.300000012)

local DEFAULT_STROKE_COLOR = Color3.new(0.0784314, 0.0784314, 0.0784314)
local DEFAULT_STROKE_THICKNESS = 2.5
local DEFAULT_STROKE_TRANSPARENCY = 0.25

local function brighten(color: Color3, amount: number): Color3
	return Color3.new(math.min(color.R + amount, 1), math.min(color.G + amount, 1), math.min(color.B + amount, 1))
end

local function darken(color: Color3, amount: number): Color3
	return Color3.new(math.max(color.R - amount, 0), math.max(color.G - amount, 0), math.max(color.B - amount, 0))
end

local function createStroke(stroke: StrokeProps?)
	return create("UIStroke")({
		Name = "UIStroke",
		ApplyStrokeMode = if stroke and stroke.applyStrokeMode
			then stroke.applyStrokeMode
			else Enum.ApplyStrokeMode.Contextual,
		Color = if stroke and stroke.color then stroke.color else DEFAULT_STROKE_COLOR,
		Thickness = if stroke and stroke.thickness ~= nil then stroke.thickness else DEFAULT_STROKE_THICKNESS,
		Transparency = if stroke and stroke.transparency ~= nil
			then stroke.transparency
			else DEFAULT_STROKE_TRANSPARENCY,
		LineJoinMode = if stroke and stroke.lineJoinMode then stroke.lineJoinMode else Enum.LineJoinMode.Round,
		StrokeSizingMode = Enum.StrokeSizingMode.FixedSize,
		BorderStrokePosition = if stroke and stroke.borderStrokePosition
			then stroke.borderStrokePosition
			else Enum.BorderStrokePosition.Outer,
		ZIndex = 1,
	})
end

local function createGradient(color: Color3)
	return create("UIGradient")({
		Name = "UIGradient",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, brighten(color, 0.24)),
			ColorSequenceKeypoint.new(0.5, brighten(color, 0.06)),
			ColorSequenceKeypoint.new(1, darken(color, 0.08)),
		}),
		Rotation = 90,
	})
end

local function createWeldPattern()
	return create("ImageLabel")({
		Name = "Weld",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = WELD_SIZE,
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		BackgroundTransparency = 1,
		Transparency = 1,
		Image = WELD_IMAGE,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = WELD_TILE_SIZE,
		ImageTransparency = 0.6,
		ZIndex = 1,

		create("UIAspectRatioConstraint")({
			AspectRatio = 2.5,
			AspectType = Enum.AspectType.FitWithinMaxSize,
			DominantAxis = Enum.DominantAxis.Width,
		}),
	})
end

local function createClippedDescendantsFrame()
	return create("Frame")({
		Name = "ClippedDescendantsFrame",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,

		createWeldPattern(),
	})
end

local function WeldFrame(props: Props)
	local color = props.color
	local cornerRadius = props.cornerRadius or DEFAULT_CORNER_RADIUS
	if type(cornerRadius) == "number" then
		cornerRadius = UDim.new(cornerRadius, 0)
	end

	local useGradient = if props.gradient == nil then true else props.gradient

	return create("Frame")({
		Name = props.name or "WeldFrame",
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		Position = props.position or UDim2.fromScale(0.5, 0.5),
		Size = props.size,
		BackgroundColor3 = color,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex or 1,

		create("UICorner")({
			CornerRadius = cornerRadius,
		}),

		if useGradient then createGradient(color) else nil,

		createStroke(props.stroke),

		if props.scale
			then create("UIScale")({
				Scale = props.scale,
			})
			else nil,

		createClippedDescendantsFrame(),

		if props.children then table.unpack(props.children) else nil,
	})
end

return {
	WeldFrame = WeldFrame,
	createStroke = createStroke,
	createClippedDescendantsFrame = createClippedDescendantsFrame,
	DEFAULT_CORNER_RADIUS = DEFAULT_CORNER_RADIUS,
}
