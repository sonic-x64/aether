local Aura = {}

--// services / references
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

--// state
local enabled = false
local auraColors = {
ColorSequenceKeypoint.new(0, Color3.fromRGB(96, 120, 190)),
ColorSequenceKeypoint.new(0.499, Color3.fromRGB(112, 138, 219)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(54, 94, 217)),
}
local auraTypes = {}
local attachments = {}
local particles = {}
local charConnection

--// utils
local function clearAll()
	for _, att in ipairs(attachments) do
		if att and att.Parent then
			att:Destroy()
		end
	end
	attachments = {}
	particles = {}
end

local function updateColors()
  for _, p in ipairs(particles) do
    if p and p.Parent then
    p.Color = ColorSequence.new(auraColors)
    end
  end
end

--// aura creators
local function createAngelic()
	local character = lp.Character
	if not character then return end

	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if not torso then return end

	local function wing(cf, direction)
		local attachment = Instance.new("Attachment")
		attachment.CFrame = cf
		attachment.Parent = torso
		table.insert(attachments, attachment)

		local emitter = Instance.new("ParticleEmitter")
		emitter.Lifetime = NumberRange.new(1)
		emitter.LockedToPart = true
		emitter.LightEmission = 1
		emitter.Color = auraColors
		emitter.Speed = NumberRange.new(0.05)
		emitter.Size = NumberSequence.new(2.75, 3.5)
		emitter.Rate = 4
		emitter.Texture = "rbxassetid://13267054240"
		emitter.EmissionDirection = direction
		emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		emitter.Rotation = NumberRange.new(-15)
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.944),
			NumberSequenceKeypoint.new(0.2, 0),
			NumberSequenceKeypoint.new(0.8, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		emitter.Parent = attachment

		table.insert(particles, emitter)
	end

	wing(
		CFrame.new(-1.012, 0.5, 0.852, 0.966, 0, 0.259, 0, 1, 0, -0.259, 0, 0.966),
		Enum.NormalId.Back
	)

	wing(
		CFrame.new(1.167, 0.5, 0.852, 0.966, 0, -0.259, 0, 1, 0, 0.259, 0, 0.966),
		Enum.NormalId.Front
	)
end

local function createAmbient()
	local character = lp.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.new(0, -2.75, 0)
	attachment.Parent = hrp
	table.insert(attachments, attachment)

	local function ring(texture, sizeSeq, rot)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Lifetime = NumberRange.new(2)
		emitter.LockedToPart = true
		emitter.LightEmission = 1
		emitter.Color = auraColors
		emitter.Speed = NumberRange.new(0.001)
		emitter.Brightness = 2
		emitter.Size = sizeSeq
		emitter.RotSpeed = rot
		emitter.Texture = texture
		emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Parent = attachment
		table.insert(particles, emitter)
	end

	ring("rbxassetid://12713358087",
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 6),
		}),
		NumberRange.new(-600, 600)
	)
end

local function createNimb()
	local character = lp.Character
	if not character then return end

	local head = character:FindFirstChild("Head")
	if not head then return end

	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.new(-0.25, 0.933, 0.259)
	attachment.Parent = head
	table.insert(attachments, attachment)

	for i = 1, 2 do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Lifetime = NumberRange.new(1)
		emitter.LockedToPart = true
		emitter.LightEmission = 1
		emitter.Color = auraColors
		emitter.Speed = NumberRange.new(0.001)
		emitter.Brightness = 2
		emitter.Size = NumberSequence.new(2.5, 3)
		emitter.RotSpeed = NumberRange.new(-400, 400)
		emitter.Rate = 7
		emitter.Texture = "rbxassetid://8819682608"
		emitter.Parent = attachment
		table.insert(particles, emitter)
	end
end

local function createTornado()
	local character = lp.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.new(0, -3, 0)
	attachment.Parent = hrp
	table.insert(attachments, attachment)

	local emitter = Instance.new("ParticleEmitter")
	emitter.LockedToPart = true
	emitter.LightEmission = 1
	emitter.Color = auraColors
	emitter.Speed = NumberRange.new(0.01)
	emitter.Size = NumberSequence.new(6, 10)
	emitter.RotSpeed = NumberRange.new(360)
	emitter.Rate = 1
	emitter.Texture = "rbxassetid://8553497052"
	emitter.Parent = attachment

	table.insert(particles, emitter)
end

--// refresh
local function refreshAuras()
	clearAll()
	if not enabled then return end

	if auraTypes.Angelic then createAngelic() end
	if auraTypes.Ambient then createAmbient() end
	if auraTypes.Nimb then createNimb() end
	if auraTypes.Tornado then createTornado() end
end

local function onCharacterAdded()
	if enabled then
		task.wait(0.5)
		refreshAuras()
	end
end

--// public API
function Aura.setEnabled(val)
	enabled = val

	if val then
		if not charConnection then
			charConnection = lp.CharacterAdded:Connect(onCharacterAdded)
		end
		if lp.Character then
			task.delay(0.5, refreshAuras)
		end
	else
		if charConnection then
			charConnection:Disconnect()
			charConnection = nil
		end
		clearAll()
	end
end

function Aura.setAuraTypes(types)
	auraTypes = {}
	for _, t in ipairs(types or {}) do
		auraTypes[t] = true
	end
	refreshAuras()
end

function Aura.setAuraColor(index, color)
    auraColors[index] = ColorSequenceKeypoint.new(
      auraColors[index].Time,
      color
    )
  updateColors()
end

return Aura
