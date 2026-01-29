local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local lib = {}
local plr = Players.LocalPlayer
local char_conn

local settings = {
	enabled = false,
	color = Color3.fromRGB(155, 125, 175),
	transparency = 0,
	reflectance = 0,
	material = Enum.Material.ForceField,
	effect = 'none', 
	pColor = Color3.fromRGB(255, 255, 255),
	pTransparency = 0
}

local cache = {
	parts = {},
	accs = {},
	clothes = {},
	colors = nil
}

local r15_lookup = {
	LeftFoot=1, LeftLowerLeg=1, LeftUpperLeg=1, RightFoot=1, RightLowerLeg=1, RightUpperLeg=1,
	LeftHand=1, LeftLowerArm=1, LeftUpperArm=1, RightHand=1, RightLowerArm=1, RightUpperArm=1,
	LowerTorso=1, UpperTorso=1, Head=1
}

local function get_parts(char)
	local t = {}
	for _, v in next, char:GetChildren() do
		if (v:IsA("BasePart") or v:IsA("MeshPart")) and r15_lookup[v.Name] then
			table.insert(t, v)
		elseif v:IsA("Accessory") and v:FindFirstChild("Handle") then
			table.insert(t, v.Handle)
		end
	end
	return t
end

local function clear_fx(char)
	if not char then return end
	for _, v in next, get_parts(char) do
		for _, c in next, v:GetChildren() do
			if c.Name == "ChamEffect" then c:Destroy() end
		end
	end
end

local function make_emitter(parent, kind)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "ChamEffect"
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(settings.pColor)
	
	if kind == 'stars' then
		pe.Texture = 'rbxassetid://1084996976'
		pe.Lifetime = NumberRange.new(0.45, 0.9)
		pe.LockedToPart = true
		pe.Rate = 150
		pe.Speed = NumberRange.new(0.001)
		pe.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.05),
			NumberSequenceKeypoint.new(1, 0)
		})
		pe.Transparency = NumberSequence.new(settings.pTransparency)
		pe.EmissionDirection = Enum.NormalId.Bottom
		pe.ZOffset = 1
	elseif kind == 'particles' then
		pe.Texture = 'rbxassetid://7216849703'
		pe.Rate = 100
		pe.Lifetime = NumberRange.new(0.22)
		pe.Speed = NumberRange.new(1)
		pe.SpreadAngle = Vector2.new(90, 90)
		pe.Size = NumberSequence.new(0.15)
		pe.Acceleration = Vector3.new(0, -15, 0)
		pe.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, settings.pTransparency),
			NumberSequenceKeypoint.new(1, 1)
		})
	end
	
	pe.Parent = parent
end

local function cache_char(char)
	if not char then return end
	cache = { parts = {}, accs = {}, clothes = {}, colors = nil } 

	for _, v in next, char:GetChildren() do
		if r15_lookup[v.Name] and v:IsA("BasePart") then
			cache.parts[v] = {
				Mat = v.Material,
				Col = v.Color,
				Trans = v.Transparency,
				Ref = v.Reflectance,
				Tex = v:IsA("MeshPart") and v.TextureID or nil
			}
		elseif v:IsA("Accessory") and v:FindFirstChild("Handle") then
			local h = v.Handle
			cache.accs[h] = {
				Mat = h.Material,
				Col = h.Color,
				Trans = h.Transparency,
				Ref = h.Reflectance,
				Tex = h:IsA("MeshPart") and h.TextureID or nil
			}
		elseif v:IsA("Clothing") then
			cache.clothes[v.ClassName] = v[v.ClassName.."Template"]
		elseif v:IsA("BodyColors") then
			cache.colors = v:Clone()
		end
	end
end

local function restore(char)
	if not char then return end
	clear_fx(char)

	for part, props in next, cache.parts do
		if part and part.Parent then
			part.Material = props.Mat
			part.Color = props.Col
			part.Transparency = props.Trans
			part.Reflectance = props.Ref
			if props.Tex then part.TextureID = props.Tex end
		end
	end

	for handle, props in next, cache.accs do
		if handle and handle.Parent then
			handle.Material = props.Mat
			handle.Color = props.Col
			handle.Transparency = props.Trans
			handle.Reflectance = props.Ref
			if props.Tex then handle.TextureID = props.Tex end
		end
	end

	if not char:FindFirstChildOfClass("Shirt") and cache.clothes.Shirt then
		local s = Instance.new("Shirt", char)
		s.ShirtTemplate = cache.clothes.Shirt
	end
	if not char:FindFirstChildOfClass("Pants") and cache.clothes.Pants then
		local p = Instance.new("Pants", char)
		p.PantsTemplate = cache.clothes.Pants
	end
end

local function update_visuals()
	local char = plr.Character
	if not char or not settings.enabled then return end

	for _, v in next, char:GetChildren() do
		if v:IsA("Clothing") then v:Destroy() end
	end

	local targets = get_parts(char)
	clear_fx(char)

	for _, p in next, targets do
		p.Material = settings.material
		p.Color = settings.color
		p.Transparency = settings.transparency
		p.Reflectance = settings.reflectance
		if p:IsA("MeshPart") then p.TextureID = "" end
		
		if settings.effect ~= 'none' then
			make_emitter(p, settings.effect)
		end
	end
end

function lib:Toggle(bool)
	settings.enabled = bool
	local char = plr.Character
	
	if bool then
		if char then
			cache_char(char)
			update_visuals()
		end
		
		if char_conn then char_conn:Disconnect() end
		char_conn = plr.CharacterAdded:Connect(function(c)
			local hum = c:WaitForChild("Humanoid", 10)
			if not hum then return end
			task.wait(0.5) 
			if settings.enabled then
				cache_char(c)
				update_visuals()
			end
		end)
	else
		if char_conn then char_conn:Disconnect() char_conn = nil end
		if char then restore(char) end
	end
end

function lib:SetProp(prop, val)
	if settings[prop] ~= nil then
		settings[prop] = val
		if settings.enabled then update_visuals() end
	end
end

function lib:setEnabled(v) lib:Toggle(v) end
function lib:setColor(v) lib:SetProp("color", v) end
function lib:setTransparency(v) lib:SetProp("transparency", v) end
function lib:setReflectance(v) lib:SetProp("reflectance", v) end
function lib:setMaterial(v) lib:SetProp("material", Enum.Material[v] or v) end
function lib:setAddEffect(v) lib:SetProp("effect", v) end
function lib:setParticleColor(v) lib:SetProp("pColor", v) end
function lib:setParticleTransparency(v) lib:SetProp("pTransparency", v) end

return lib
