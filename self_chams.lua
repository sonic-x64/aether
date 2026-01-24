local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration / State
local lp = Players.LocalPlayer
local selfChams = {}
local enabled = false
local color = Color3.fromRGB(155, 125, 175)
local transparency = 0
local reflectance = 0
local material = 'ForceField'
local effect = 'none'
local addEffect = 'none'
local particleColor = Color3.fromRGB(255, 255, 255)
local particleTransparency = 0
local heatTime = 0
local charConnection
local heatConnection

local cachedData = {
	parts = {},
	accessories = {}, -- New cache for hats/hair
	clothing = {},
	bodyColors = nil,
}

local r15Parts = {
	'LeftFoot', 'LeftLowerLeg', 'LeftUpperLeg',
	'RightFoot', 'RightLowerLeg', 'RightUpperLeg',
	'LeftHand', 'LeftLowerArm', 'LeftUpperArm',
	'RightHand', 'RightLowerArm', 'RightUpperArm',
	'LowerTorso', 'UpperTorso', 'Head',
}

local heatMap = {
	LeftFoot = 0.7, LeftLowerLeg = 0.3, LeftUpperLeg = 0.5,
	RightFoot = 0.7, RightLowerLeg = 0.3, RightUpperLeg = 0.5,
	LeftHand = 0.7, LeftLowerArm = 0.3, LeftUpperArm = 0.5,
	RightHand = 0.7, RightLowerArm = 0.3, RightUpperArm = 0.5,
	LowerTorso = 0.3, UpperTorso = 0.5, Head = 0.5,
}

local partSet = {}
for _, name in ipairs(r15Parts) do
	partSet[name] = true
end

-- Helpers
local function isR15Part(name)
	return partSet[name] == true
end

local function cacheCharacter(char)
	if not char then return end

	cachedData.parts = {}
	cachedData.accessories = {}
	cachedData.clothing = {}
	cachedData.bodyColors = nil

	for _, child in ipairs(char:GetChildren()) do
		-- Cache R15 Body Parts
		if isR15Part(child.Name) and (child:IsA('MeshPart') or child:IsA('BasePart')) then
			cachedData.parts[child.Name] = {
				Material = child.Material,
				Color = child.Color,
				Transparency = child.Transparency,
				Reflectance = child.Reflectance,
				TextureID = child:IsA('MeshPart') and child.TextureID or nil,
			}
		-- Cache Accessories (Hair, Hats, etc.)
		elseif child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle and (handle:IsA("MeshPart") or handle:IsA("BasePart")) then
				-- We use the accessory instance itself as the key
				cachedData.accessories[child] = {
					Material = handle.Material,
					Color = handle.Color,
					Transparency = handle.Transparency,
					Reflectance = handle.Reflectance,
					TextureID = handle:IsA('MeshPart') and handle.TextureID or nil,
				}
			end
		end
	end

	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA('Shirt') then
			cachedData.clothing.Shirt = desc.ShirtTemplate
		elseif desc:IsA('Pants') then
			cachedData.clothing.Pants = desc.PantsTemplate
		elseif desc:IsA('BodyColors') then
			cachedData.bodyColors = {
				HeadColor3 = desc.HeadColor3,
				LeftArmColor3 = desc.LeftArmColor3,
				LeftLegColor3 = desc.LeftLegColor3,
				RightArmColor3 = desc.RightArmColor3,
				RightLegColor3 = desc.RightLegColor3,
				TorsoColor3 = desc.TorsoColor3,
			}
		end
	end
end

local function removeParticles(char)
	if not char then return end
	for _, part in ipairs(char:GetChildren()) do
		if isR15Part(part.Name) then
			local stars = part:FindFirstChild('stars')
			local specks = part:FindFirstChild('Specks')
			if stars then pcall(function() stars:Destroy() end) end
			if specks then pcall(function() specks:Destroy() end) end
		end
	end
end

local function applyStars(char)
	if not char then return end
	for _, part in ipairs(char:GetChildren()) do
		if isR15Part(part.Name) and (part:IsA('MeshPart') or part:IsA('BasePart')) then
			local existing = part:FindFirstChild('stars')
			if existing then existing:Destroy() end

			pcall(function()
				local stars = Instance.new('ParticleEmitter')
				stars.Name = 'stars'
				stars.Lifetime = NumberRange.new(0.45, 0.9)
				stars.LockedToPart = true
				stars.LightEmission = 1
				stars.Drag = 5
				stars.Squash = NumberSequence.new(-0.1)
				stars.Speed = NumberRange.new(0.001, 0.001)
				stars.Brightness = 3
				stars.ZOffset = 1
				stars.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.508, 0.05, 0.05),
					NumberSequenceKeypoint.new(1, 0),
				})
				stars.Rate = 150
				stars.Texture = 'rbxassetid://1084996976'
				stars.EmissionDirection = Enum.NormalId.Bottom
				stars.Color = ColorSequence.new(particleColor)
				stars.Transparency = NumberSequence.new(particleTransparency)
				stars.Parent = part
			end)
		end
	end
end

local function applyParticles(char)
	if not char then return end
	for _, part in ipairs(char:GetChildren()) do
		if isR15Part(part.Name) and (part:IsA('MeshPart') or part:IsA('BasePart')) then
			local existing = part:FindFirstChild('Specks')
			if existing then existing:Destroy() end

			pcall(function()
				local specks = Instance.new('ParticleEmitter')
				specks.Name = 'Specks'
				specks.Lifetime = NumberRange.new(0.22, 0.22)
				specks.SpreadAngle = Vector2.new(90, 90)
				local t = particleTransparency
				specks.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, math.min(1, t + 0.8)),
					NumberSequenceKeypoint.new(0.25, math.max(0, t - 0.1)),
					NumberSequenceKeypoint.new(1, math.min(1, t + 0.8)),
				})
				specks.LightEmission = 1
				specks.Color = ColorSequence.new(particleColor)
				specks.Drag = 5
				specks.Squash = NumberSequence.new(0)
				specks.Speed = NumberRange.new(1, 1)
				specks.Brightness = 4.2
				specks.Size = NumberSequence.new(0.15)
				specks.Acceleration = Vector3.new(0, -15, 0)
				specks.RotSpeed = NumberRange.new(-45, 45)
				specks.Rate = 100
				specks.Texture = 'rbxassetid://7216849703'
				specks.Parent = part
			end)
		end
	end
end

local function applyChams(char, heatPulse, skipParticles)
	if not char then return end

	-- Helper to apply properties to any part (body part or accessory handle)
	local function applyPropsToPart(p, finalTransparency)
		p.Material = Enum.Material[material]
		p.Color = color
		if p:IsA('MeshPart') then p.TextureID = '' end
		p.Reflectance = reflectance
		-- Only apply transparency if the part exists normally
		if p.Transparency < 1 then
			p.Transparency = finalTransparency
		end
	end

	-- Remove clothing textures
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA('Pants') or desc:IsA('Shirt') then
			pcall(function() desc:Destroy() end)
		end
	end

	for _, child in ipairs(char:GetChildren()) do
		-- Handle R15 Body Parts (Includes Heat Logic)
		if isR15Part(child.Name) then
			local trans = transparency
			if effect == 'heat' and heatMap[child.Name] then
				local base = heatMap[child.Name]
				if heatPulse then
					trans = base + (math.min(base + 0.2, 1) - base) * heatPulse
				else
					trans = base
				end
			end

			if child:IsA('MeshPart') or child:IsA('BasePart') then
				pcall(function() applyPropsToPart(child, trans) end)
			end

		-- Handle Accessories (Hats, hair, etc.) - No heat logic applies here
		elseif child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle and (handle:IsA("MeshPart") or handle:IsA("BasePart")) then
				pcall(function() applyPropsToPart(handle, transparency) end)
			end
		end
	end

	if not skipParticles then
		if addEffect == 'stars' then
			applyStars(char)
		elseif addEffect == 'particles' then
			applyParticles(char)
		else
			removeParticles(char)
		end
	end
end

local function restoreCharacter(char)
	if not char then return end
	removeParticles(char)

	-- Restore Body Parts
	for _, part in ipairs(char:GetChildren()) do
		if isR15Part(part.Name) and cachedData.parts[part.Name] then
			local data = cachedData.parts[part.Name]
			pcall(function()
				part.Material = data.Material
				part.Color = data.Color
				part.Transparency = data.Transparency
				part.Reflectance = data.Reflectance
				if part:IsA('MeshPart') and data.TextureID then
					part.TextureID = data.TextureID
				end
			end)
		end
	end

	-- Restore Accessories
	for acc, data in pairs(cachedData.accessories) do
		if acc and acc.Parent == char then -- Ensure accessory still exists on char
			local handle = acc:FindFirstChild("Handle")
			if handle then
				pcall(function()
					handle.Material = data.Material
					handle.Color = data.Color
					handle.Transparency = data.Transparency
					handle.Reflectance = data.Reflectance
					if handle:IsA('MeshPart') and data.TextureID then
						handle.TextureID = data.TextureID
					end
				end)
			end
		end
	end

	-- Restore Clothing templates
	if cachedData.clothing.Shirt then
		pcall(function()
			local shirt = Instance.new('Shirt')
			shirt.ShirtTemplate = cachedData.clothing.Shirt
			shirt.Parent = char
		end)
	end
	if cachedData.clothing.Pants then
		pcall(function()
			local pants = Instance.new('Pants')
			pants.PantsTemplate = cachedData.clothing.Pants
			pants.Parent = char
		end)
	end
end

-- Logic Loops
local lastHeatTick = 0

local function stopHeatLoop()
	if heatConnection then
		heatConnection:Disconnect()
		heatConnection = nil
	end
	heatTime = 0
	lastHeatTick = 0
end

local function startHeatLoop()
	stopHeatLoop()
	lastHeatTick = tick()

	heatConnection = RunService.Heartbeat:Connect(function()
		if not enabled or effect ~= 'heat' then
			stopHeatLoop()
			return
		end

		local char = lp.Character
		if not char then return end

		local now = tick()
		local dt = now - lastHeatTick
		lastHeatTick = now
		heatTime = heatTime + dt
		local pulse = math.sin(heatTime * 2) * 0.5 + 0.5
		applyChams(char, pulse, true)
	end)
end

-- Public Interface
function selfChams:setEnabled(val)
	enabled = val
	local char = lp.Character

	if enabled then
		cacheCharacter(char)
		applyChams(char)

		if effect == 'heat' then
			startHeatLoop()
		end
		if charConnection then
			charConnection:Disconnect()
		end

		charConnection = lp.CharacterAdded:Connect(function(newChar)
			newChar:WaitForChild('Humanoid')
			task.wait(1.1) -- Wait for accessories to load
			if enabled then
				cacheCharacter(newChar)
				applyChams(newChar)
				if effect == 'heat' then startHeatLoop() end
				task.wait(0.5)
				applyChams(newChar)
			end
		end)
	else
		stopHeatLoop()
		if charConnection then
			charConnection:Disconnect()
			charConnection = nil
		end
		restoreCharacter(char)
	end
end

function selfChams:setColor(c)
	color = c
	if enabled then applyChams(lp.Character) end
end

function selfChams:setTransparency(t)
	transparency = t
	if enabled then applyChams(lp.Character) end
end

function selfChams:setReflectance(r)
	reflectance = r
	if enabled then applyChams(lp.Character) end
end

function selfChams:setMaterial(m)
	material = m
	if enabled then applyChams(lp.Character) end
end

function selfChams:setEffect(e)
	effect = e
	if enabled then
		if e == 'heat' then
			startHeatLoop()
		else
			stopHeatLoop()
			applyChams(lp.Character)
		end
	end
end

function selfChams:setAddEffect(e)
	addEffect = e
	if enabled then
		removeParticles(lp.Character)
		if e == 'stars' then
			applyStars(lp.Character)
		elseif e == 'particles' then
			applyParticles(lp.Character)
		end
	end
end

function selfChams:setParticleColor(c)
	particleColor = c
	if enabled then selfChams:setAddEffect(addEffect) end
end

function selfChams:setParticleTransparency(t)
	particleTransparency = t
	if enabled then selfChams:setAddEffect(addEffect) end
end

return selfChams
