--!strict
--!native
--!optimize 2
--[[ NoobsterStudio ]]--
--[[

Lightning module for effects of lightning

]]--

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Third-party modules
local Bezier = require("../modules/Bezier")
local BoatTween = require("../modules/BoatTween")

-- Main Module
local LightningModule = {}

type LightningData = {
	Points: { Vector3 }, -- Supplied by type of lightning
	Speed: number, -- self-calculated
} & LightningInputData

export type LightningInputData = {
	Color: Color3,
	Time: number,
	Width: number,
	Envelope: number,
	Shift: number, -- How much the points can vary
}

local RNG = Random.new()

function LightningModule.Cast(data: LightningData)
	local prevA: Attachment? = nil
	local prevB: Beam? = nil
	
	for _, point in data.Points do
		local attachment = Instance.new("Attachment")
		attachment.Parent = workspace.Terrain
		attachment.Position = point
		
		if prevA then
			local dist = (attachment.Position - prevA.Position).Magnitude
			local moveTime = dist / data.Speed / 2
			
			attachment.Position = prevA.Position
			
			local beam = Instance.new("Beam")
			beam.Color = ColorSequence.new(data.Color)
			beam.Width0 = if prevB then prevB.Width1 else data.Width
			beam.Width1 = 0
			beam.LightEmission = 0
			beam.LightInfluence = 0
			beam.FaceCamera = true
			beam.Brightness = 3
			beam.Transparency = NumberSequence.new(0)
			beam.Parent = workspace.Terrain
			beam.Attachment0 = prevA
			beam.Attachment1 = attachment
			
			TweenService:Create(
				attachment,
				TweenInfo.new(moveTime, Enum.EasingStyle.Linear),
				{ Position = point }
			):Play()
			
			local boatTween = BoatTween:Create(
				beam,
				{
					Time = moveTime,
					EasingStyle = "Quad",
					EasingDirection = "Out",
					StepType = "RenderStepped",
					Goal = {
						Width0 = if prevB then prevB.Width1 else data.Width,
						Width1 = RNG:NextNumber(data.Width - data.Envelope / 2, data.Width + data.Envelope / 2)
					}
				}
			)
			boatTween:Play()
			prevB = beam
			
			task.delay(data.Time / 2, function()
				boatTween:Destroy()
				
				local boatTween = BoatTween:Create(
					beam,
					{
						Time = data.Time / 2,
						EasingStyle = "Quad",
						EasingDirection = "In",
						StepType = "RenderStepped",
						Goal = {
							Width0 = 0,
							Width1 = 0
						}
					}
				)
				boatTween:Play()
				
				task.wait(data.Time / 2)
				
				boatTween:Destroy()
				TweenService:Create(
					beam.Attachment0,
					TweenInfo.new(moveTime, Enum.EasingStyle.Linear),
					{
						Position = point,
					}
				):Play()
				
				task.wait(moveTime)
				
				beam:Destroy()
				assert(beam.Attachment0)
				beam.Attachment0:Destroy()
			end)
			task.wait(moveTime)
		end
		
		prevA = attachment
	end
	task.wait(data.Time)
	game:GetService("Debris"):AddItem(prevA, 0.01) -- Just so if prevA is nil, nothing will error lol
end

function LightningModule.Line(p1: Vector3, p2: Vector3, inputData: LightningInputData, segments: number, casts: number)
	if not segments then
		segments = (p1 - p2).Magnitude / 4
	end
	
	for i = 1, casts do
		task.spawn(function()
			local data = table.clone(inputData) :: LightningData
			local points = {}
			local dist = 0
			local base = RNG:NextNumber() * 300
			for i = 0, segments do
				local noiseX = math.noise(base + i)
				local noiseY = math.noise(0, base + i)
				local noiseZ = math.noise(0, 0, base + i)
				
				points[i + 1] =
					p1 + i * (p2 - p1) / segments +
					Vector3.new(noiseX * data.Shift / 2, noiseY * data.Shift / 2, noiseZ * data.Shift / 2)
				
				if i ~= 0 then
					dist += (points[i] - points[i + 1]).Magnitude
				end
			end
			
			points[segments + 1] = p2
			data.Points = points
			data.Speed = dist / data.Time
			
			LightningModule.Cast(data)
		end)
	end
end

return LightningModule
