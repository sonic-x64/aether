local SelfChams = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local enabled = false
local color = Color3.fromRGB(155, 125, 175)
local transparency = 0
local reflectance = 0
local material = Enum.Material.ForceField

-- MULTI SELECT TABLES
local effects = {}        -- heat
local addEffects = {}     -- stars, particles

local particleColor = Color3.fromRGB(255, 255, 255)
local particleTransparency = 0

local heatTime = 0
local heatConn
local charConn

local cached = { parts = {}, clothing = {} }

local r15Parts = {
	LeftFoot=true, LeftLowerLeg=true, LeftUpperLeg=true,
	RightFoot=true, RightLowerLeg=true, RightUpperLeg=true,
	LeftHand=true, LeftLowerArm=true, LeftUpperArm=true,
	RightHand=true, RightLowerArm=true, RightUpperArm=true,
	LowerTorso=true, UpperTorso=true, Head=true,
}

local heatMap = {
	LeftFoot=0.7, LeftLowerLeg=0.3, LeftUpperLeg=0.5,
	RightFoot=0.7, RightLowerLeg=0.3, RightUpperLeg=0.5,
	LeftHand=0.7, LeftLowerArm=0.3, LeftUpperArm=0.5,
	RightHand=0.7, RightLowerArm=0.3, RightUpperArm=0.5,
	LowerTorso=0.3, UpperTorso=0.5, Head=0.5,
}

-- ===== CACHE =====
local function cacheCharacter(char)
	cached.parts = {}
	cached.clothing = {}

	for _, p in ipairs(char:GetChildren()) do
		if r15Parts[p.Name] and p:IsA("BasePart") then
			cached.parts[p.Name] = {
				Material=p.Material,
				Color=p.Color,
				Transparency=p.Transparency,
				Reflectance=p.Reflectance,
				Texture=p:IsA("MeshPart") and p.TextureID or nil
			}
		end
	end

	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Shirt") then cached.clothing.Shirt = d.ShirtTemplate end
		if d:IsA("Pants") then cached.clothing.Pants = d.PantsTemplate end
	end
end

local function restoreCharacter(char)
	if not char then return end

	for _, p in ipairs(char:GetChildren()) do
		local data = cached.parts[p.Name]
		if data and p:IsA("BasePart") then
			p.Material = data.Material
			p.Color = data.Color
			p.Transparency = data.Transparency
			p.Reflectance = data.Reflectance
			if p:IsA("MeshPart") and data.Texture then
				p.TextureID = data.Texture
			end
		end
	end
end

-- ===== PARTICLES =====
local function clearParticles(char)
	for _, p in ipairs(char:GetChildren()) do
		if r15Parts[p.Name] then
			for _, n in ipairs({"stars","Specks"}) do
				local f = p:FindFirstChild(n)
				if f then f:Destroy() end
			end
		end
	end
end

local function applyStars(char)
	for _, p in ipairs(char:GetChildren()) do
		if r15Parts[p.Name] and p:IsA("BasePart") then
			local e = Instance.new("ParticleEmitter")
			e.Name = "stars"
			e.Color = ColorSequence.new(particleColor)
			e.Transparency = NumberSequence.new(particleTransparency)
			e.Texture = "rbxassetid://1084996976"
			e.Rate = 150
			e.Speed = NumberRange.new(0,0)
			e.Parent = p
		end
	end
end

local function applyParticles(char)
	for _, p in ipairs(char:GetChildren()) do
		if r15Parts[p.Name] and p:IsA("BasePart") then
			local e = Instance.new("ParticleEmitter")
			e.Name = "Specks"
			e.Color = ColorSequence.new(particleColor)
			e.Texture = "rbxassetid://7216849703"
			e.Rate = 100
			e.Speed = NumberRange.new(1,1)
			e.Parent = p
		end
	end
end

-- ===== CHAMS =====
local function applyChams(char, pulse)
	if not char then return end

	clearParticles(char)

	for _, p in ipairs(char:GetChildren()) do
		if r15Parts[p.Name] and p:IsA("BasePart") then
			local t = transparency

			if effects.heat and heatMap[p.Name] then
				local base = heatMap[p.Name]
				t = pulse and (base + (0.2 * pulse)) or base
			end

			p.Material = material
			p.Color = color
			p.Reflectance = reflectance
			p.Transparency = t
			if p:IsA("MeshPart") then p.TextureID = "" end
		end
	end

	if addEffects.stars then applyStars(char) end
	if addEffects.particles then applyParticles(char) end
end

-- ===== HEAT LOOP =====
local function stopHeat()
	if heatConn then heatConn:Disconnect() heatConn=nil end
	heatTime = 0
end

local function startHeat()
	stopHeat()
	heatConn = RunService.Heartbeat:Connect(function(dt)
		if not enabled or not effects.heat then stopHeat() return end
		heatTime += dt
		local pulse = math.sin(heatTime*2)*0.5+0.5
		applyChams(lp.Character, pulse)
	end)
end

-- ===== API =====
function SelfChams:SetEnabled(v)
	enabled = v
	local char = lp.Character
	if not char then return end

	if v then
		cacheCharacter(char)
		applyChams(char)
		if effects.heat then startHeat() end
	else
		stopHeat()
		restoreCharacter(char)
	end
end

function SelfChams:SetColor(c) color=c if enabled then applyChams(lp.Character) end end
function SelfChams:SetTransparency(t) transparency=t if enabled then applyChams(lp.Character) end end
function SelfChams:SetReflectance(r) reflectance=r if enabled then applyChams(lp.Character) end end
function SelfChams:SetMaterial(m) material=Enum.Material[m] or material if enabled then applyChams(lp.Character) end end

function SelfChams:SetEffects(list)
	effects={}
	for _,e in ipairs(list or {}) do effects[e]=true end
	if enabled and effects.heat then startHeat() else stopHeat() end
end

function SelfChams:SetAddEffects(list)
	addEffects={}
	for _,e in ipairs(list or {}) do addEffects[e]=true end
	if enabled then applyChams(lp.Character) end
end

function SelfChams:SetParticleColor(c) particleColor=c if enabled then applyChams(lp.Character) end end
function SelfChams:SetParticleTransparency(t) particleTransparency=t if enabled then applyChams(lp.Character) end end

return SelfChams
