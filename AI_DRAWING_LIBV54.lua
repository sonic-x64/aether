-- Services
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- Container
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DrawingLib_Optimized"
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 0x7FFFFFFF
ScreenGui.Parent = CoreGui

-- State Management
local DrawingLib = {}
local ActiveDrawings = {} -- Holds all active drawing objects to update loop
local FrameCount = 0

-- Fonts
local FONT_MAP = {
    [0] = Font.fromEnum(Enum.Font.Roboto),
    [1] = Font.fromEnum(Enum.Font.Legacy),
    [2] = Font.fromEnum(Enum.Font.SourceSans),
    [3] = Font.fromEnum(Enum.Font.RobotoMono),
}

-- Utility: Fast Transparency conversion
local function getTrans(val)
    return 1 - math.clamp(val, 0, 1)
end

--[[ 
    RENDER LOOP
    This is the FPS Saver. It iterates through objects once per frame
    and applies changes in bulk, rather than on every property set.
]]
RunService.RenderStepped:Connect(function()
    for obj, updateFunc in pairs(ActiveDrawings) do
        if obj.Visible then
            updateFunc()
        else
            -- If invisible, strictly hide the instance and skip math
            if obj._instance and obj._instance.Visible then
                obj._instance.Visible = false
            end
        end
    end
end)

local function CreateBase(typeStr)
    return {
        Visible = true,
        ZIndex = 1,
        Transparency = 1,
        Color = Color3.fromRGB(255, 255, 255),
        _type = typeStr,
        _instance = nil
    }
end

--[[ PRIMITIVES ]]

-- 1. LINE
local function CreateLine()
    local props = CreateBase("Line")
    props.From = Vector2.zero
    props.To = Vector2.zero
    props.Thickness = 1

    local Frame = Instance.new("Frame")
    Frame.Name = "L"
    Frame.BorderSizePixel = 0
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.Parent = ScreenGui
    props._instance = Frame

    local function Update()
        Frame.Visible = true
        Frame.ZIndex = props.ZIndex
        Frame.BackgroundColor3 = props.Color
        Frame.BackgroundTransparency = getTrans(props.Transparency)

        local p1, p2 = props.From, props.To
        local center = (p1 + p2) / 2
        local vec = p2 - p1
        local len = vec.Magnitude
        local rot = math.atan2(vec.Y, vec.X)

        Frame.Position = UDim2.fromOffset(center.X, center.Y)
        Frame.Rotation = math.deg(rot)
        Frame.Size = UDim2.fromOffset(len, props.Thickness)
    end
    return props, Update
end

-- 2. TEXT
local function CreateText()
    local props = CreateBase("Text")
    props.Text = ""
    props.Size = 18
    props.Center = false
    props.Outline = false
    props.OutlineColor = Color3.new()
    props.Position = Vector2.zero
    props.Font = 0

    local Label = Instance.new("TextLabel")
    Label.Name = "T"
    Label.BackgroundTransparency = 1
    Label.Parent = ScreenGui
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = Label
    props._instance = Label

    local function Update()
        Label.Visible = true
        Label.ZIndex = props.ZIndex
        Label.Text = props.Text
        Label.TextColor3 = props.Color
        Label.TextTransparency = getTrans(props.Transparency)
        Label.TextSize = props.Size
        Label.FontFace = FONT_MAP[props.Font] or FONT_MAP[0]

        Stroke.Enabled = props.Outline
        Stroke.Color = props.OutlineColor
        Stroke.Transparency = getTrans(props.Transparency)

        local bounds = Label.TextBounds
        Label.Size = UDim2.fromOffset(bounds.X, bounds.Y)

        local pos = props.Position
        if props.Center then
            pos = pos - (bounds / 2)
        end
        Label.Position = UDim2.fromOffset(math.floor(pos.X), math.floor(pos.Y)) -- Pixel snap
    end
    return props, Update
end

-- 3. SQUARE (The Box)
local function CreateSquare()
    local props = CreateBase("Square")
    props.Size = Vector2.zero
    props.Position = Vector2.zero
    props.Thickness = 1
    props.Filled = false

    local Frame = Instance.new("Frame")
    Frame.Name = "S"
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local Stroke = Instance.new("UIStroke")
    Stroke.LineJoinMode = Enum.LineJoinMode.Miter -- Makes corners sharp, not round
    Stroke.Parent = Frame
    props._instance = Frame

    local function Update()
        Frame.Visible = true
        Frame.ZIndex = props.ZIndex
        Frame.Position = UDim2.fromOffset(math.floor(props.Position.X), math.floor(props.Position.Y))
        Frame.Size = UDim2.fromOffset(math.floor(props.Size.X), math.floor(props.Size.Y))

        local trans = getTrans(props.Transparency)
        
        if props.Filled then
            Frame.BackgroundColor3 = props.Color
            Frame.BackgroundTransparency = trans
            Stroke.Enabled = false
        else
            Frame.BackgroundTransparency = 1
            Stroke.Enabled = true
            Stroke.Color = props.Color
            Stroke.Thickness = props.Thickness
            Stroke.Transparency = trans
        end
    end
    return props, Update
end

-- 4. CIRCLE
local function CreateCircle()
    local props = CreateBase("Circle")
    props.Radius = 20
    props.Position = Vector2.zero
    props.Thickness = 1
    props.Filled = false
    props.NumSides = 0

    local Frame = Instance.new("Frame")
    Frame.Name = "C"
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(1, 0)
    Corner.Parent = Frame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = Frame
    props._instance = Frame

    local function Update()
        Frame.Visible = true
        Frame.ZIndex = props.ZIndex
        
        local dia = props.Radius * 2
        Frame.Size = UDim2.fromOffset(dia, dia)
        Frame.Position = UDim2.fromOffset(props.Position.X, props.Position.Y)
        
        local trans = getTrans(props.Transparency)
        
        if props.Filled then
            Frame.BackgroundColor3 = props.Color
            Frame.BackgroundTransparency = trans
            Stroke.Enabled = false
        else
            Frame.BackgroundTransparency = 1
            Stroke.Enabled = true
            Stroke.Color = props.Color
            Stroke.Thickness = props.Thickness
            Stroke.Transparency = trans
        end
    end
    return props, Update
end

-- 5. QUAD (4 Lines, Wireframe)
local function CreateQuad()
    local props = CreateBase("Quad")
    props.PointA = Vector2.zero
    props.PointB = Vector2.zero
    props.PointC = Vector2.zero
    props.PointD = Vector2.zero
    props.Thickness = 1
    props.Filled = false 

    -- Internal lines
    local L1 = DrawingLib.new("Line")
    local L2 = DrawingLib.new("Line")
    local L3 = DrawingLib.new("Line")
    local L4 = DrawingLib.new("Line")
    local Lines = {L1, L2, L3, L4}

    local function Update()
        -- Pass properties to lines
        local v = props.Visible
        local c = props.Color
        local t = props.Transparency
        local th = props.Thickness
        local z = props.ZIndex

        L1.Visible, L2.Visible, L3.Visible, L4.Visible = v, v, v, v
        
        -- Optimization: Don't set other props if not visible
        if not v then return end

        L1.Color, L2.Color, L3.Color, L4.Color = c, c, c, c
        L1.Transparency, L2.Transparency, L3.Transparency, L4.Transparency = t, t, t, t
        L1.Thickness, L2.Thickness, L3.Thickness, L4.Thickness = th, th, th, th
        L1.ZIndex, L2.ZIndex, L3.ZIndex, L4.ZIndex = z, z, z, z

        L1.From = props.PointA; L1.To = props.PointB
        L2.From = props.PointB; L2.To = props.PointC
        L3.From = props.PointC; L3.To = props.PointD
        L4.From = props.PointD; L4.To = props.PointA
    end

    local function Cleanup()
        for _, l in pairs(Lines) do l:Remove() end
    end

    return props, Update, Cleanup
end

--[[ CONSTRUCTOR ]]
function DrawingLib.new(typeStr)
    local props, updateFunc, cleanupFunc
    
    if typeStr == "Line" then props, updateFunc = CreateLine()
    elseif typeStr == "Text" then props, updateFunc = CreateText()
    elseif typeStr == "Square" then props, updateFunc = CreateSquare()
    elseif typeStr == "Circle" then props, updateFunc = CreateCircle()
    elseif typeStr == "Quad" then props, updateFunc, cleanupFunc = CreateQuad()
    else return nil end

    -- Metatable to handle user input
    local obj = setmetatable({}, {
        __index = props,
        __newindex = function(self, k, v)
            if props[k] ~= nil then
                props[k] = v
                -- Note: We DO NOT call updateFunc() here. 
                -- We let the RenderStepped loop handle it.
            end
        end,
        __tostring = function() return "Drawing" end
    })

    -- Helpers
    function obj:Remove()
        ActiveDrawings[obj] = nil -- Remove from render loop
        if props._instance then props._instance:Destroy() end
        if cleanupFunc then cleanupFunc() end
        setmetatable(obj, nil)
    end
    obj.Destroy = obj.Remove

    -- Add to render loop
    ActiveDrawings[obj] = updateFunc

    return obj
end

-- Injections
getgenv().Drawing = DrawingLib
return DrawingLib
