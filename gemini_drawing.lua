-- Services
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- Container Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DrawingLib_Base"
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 0x7FFFFFFF
ScreenGui.Parent = CoreGui

-- Type Definitions & Constants
local DrawingLib = {}
local Objects = {}

DrawingLib.Fonts = {
    UI = 0,
    System = 1,
    Plex = 2,
    Monospace = 3
}

local FONT_MAP = {
    [0] = Font.fromEnum(Enum.Font.Roboto),
    [1] = Font.fromEnum(Enum.Font.Legacy),
    [2] = Font.fromEnum(Enum.Font.SourceSans),
    [3] = Font.fromEnum(Enum.Font.RobotoMono),
}

-- Utility: Convert Drawing Transparency (1=Visible) to Roblox Transparency (0=Visible)
local function getRobloxTransparency(val)
    return 1 - math.clamp(val, 0, 1)
end

-- Base Class Helper
local function CreateBaseProperties(objType)
    return {
        Visible = true,
        ZIndex = 1,
        Transparency = 1,
        Color = Color3.fromRGB(255, 255, 255),
        _type = objType,
        _instance = nil -- The main GUI object
    }
end

--[[ 
    PRIMITIVE CREATORS 
    Each function returns the State table and the Interface Metatable
]]

-- 1. LINE
local function CreateLine()
    local props = CreateBaseProperties("Line")
    props.From = Vector2.zero
    props.To = Vector2.zero
    props.Thickness = 1

    local Frame = Instance.new("Frame")
    Frame.Name = "Line"
    Frame.BorderSizePixel = 0
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.Parent = ScreenGui
    
    props._instance = Frame

    local function Update()
        if not props.Visible then 
            Frame.Visible = false 
            return 
        end
        Frame.Visible = true
        Frame.ZIndex = props.ZIndex
        Frame.BackgroundColor3 = props.Color
        Frame.BackgroundTransparency = getRobloxTransparency(props.Transparency)

        local startPos, endPos = props.From, props.To
        local direction = endPos - startPos
        local center = (startPos + endPos) / 2
        local distance = direction.Magnitude
        local theta = math.atan2(direction.Y, direction.X)

        Frame.Position = UDim2.fromOffset(center.X, center.Y)
        Frame.Rotation = math.deg(theta)
        Frame.Size = UDim2.fromOffset(distance, props.Thickness)
    end

    return props, Update
end

-- 2. TEXT
local function CreateText()
    local props = CreateBaseProperties("Text")
    props.Text = ""
    props.Size = 18
    props.Center = false
    props.Outline = false
    props.OutlineColor = Color3.new(0, 0, 0)
    props.Position = Vector2.zero
    props.Font = 0

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Name = "Text"
    TextLabel.BackgroundTransparency = 1
    TextLabel.BorderSizePixel = 0
    TextLabel.Parent = ScreenGui
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Thickness = 1
    UIStroke.Parent = TextLabel

    props._instance = TextLabel

    local function Update()
        if not props.Visible then
            TextLabel.Visible = false
            return
        end
        TextLabel.Visible = true
        TextLabel.ZIndex = props.ZIndex
        
        local fontObj = FONT_MAP[props.Font] or FONT_MAP[0]
        TextLabel.FontFace = fontObj
        TextLabel.Text = props.Text
        TextLabel.TextColor3 = props.Color
        TextLabel.TextSize = props.Size
        TextLabel.TextTransparency = getRobloxTransparency(props.Transparency)
        
        UIStroke.Enabled = props.Outline
        UIStroke.Color = props.OutlineColor
        UIStroke.Transparency = getRobloxTransparency(props.Transparency)

        -- Auto-resize to fit text
        TextLabel.Size = UDim2.fromOffset(TextLabel.TextBounds.X, TextLabel.TextBounds.Y)
        
        local finalPos = props.Position
        if props.Center then
            finalPos = finalPos - (TextLabel.TextBounds / 2)
        end
        
        TextLabel.Position = UDim2.fromOffset(finalPos.X, finalPos.Y)
    end

    return props, Update
end

-- 3. CIRCLE
local function CreateCircle()
    local props = CreateBaseProperties("Circle")
    props.Radius = 20
    props.Position = Vector2.zero
    props.Thickness = 1
    props.Filled = false
    props.NumSides = 0 -- Unused in Frame-based, kept for API compat

    local Frame = Instance.new("Frame")
    Frame.Name = "Circle"
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Frame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Frame
    
    props._instance = Frame

    local function Update()
        if not props.Visible then Frame.Visible = false; return end
        Frame.Visible = true
        Frame.ZIndex = props.ZIndex

        local diameter = props.Radius * 2
        Frame.Size = UDim2.fromOffset(diameter, diameter)
        Frame.Position = UDim2.fromOffset(props.Position.X, props.Position.Y)

        local rTransparency = getRobloxTransparency(props.Transparency)

        if props.Filled then
            Frame.BackgroundColor3 = props.Color
            Frame.BackgroundTransparency = rTransparency
            UIStroke.Enabled = false
        else
            Frame.BackgroundTransparency = 1
            UIStroke.Enabled = true
            UIStroke.Color = props.Color
            UIStroke.Transparency = rTransparency
            UIStroke.Thickness = props.Thickness
        end
    end

    return props, Update
end

-- 4. SQUARE
local function CreateSquare()
    local props = CreateBaseProperties("Square")
    props.Size = Vector2.zero
    props.Position = Vector2.zero
    props.Thickness = 1
    props.Filled = false

    local Frame = Instance.new("Frame")
    Frame.Name = "Square"
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local UIStroke = Instance.new("UIStroke")
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.LineJoinMode = Enum.LineJoinMode.Miter
    UIStroke.Parent = Frame

    props._instance = Frame

    local function Update()
        if not props.Visible then Frame.Visible = false; return end
        Frame.Visible = true
        Frame.ZIndex = props.ZIndex

        Frame.Position = UDim2.fromOffset(props.Position.X, props.Position.Y)
        Frame.Size = UDim2.fromOffset(props.Size.X, props.Size.Y)

        local rTransparency = getRobloxTransparency(props.Transparency)

        if props.Filled then
            Frame.BackgroundColor3 = props.Color
            Frame.BackgroundTransparency = rTransparency
            UIStroke.Enabled = false
        else
            Frame.BackgroundTransparency = 1
            UIStroke.Enabled = true
            UIStroke.Color = props.Color
            UIStroke.Transparency = rTransparency
            UIStroke.Thickness = props.Thickness
        end
    end

    return props, Update
end

-- 5. QUAD & TRIANGLE (Composite Shapes)
-- These use existing "Line" objects to form the shape (Wireframe only for reliability)
local function CreatePoly(isQuad)
    local props = CreateBaseProperties(isQuad and "Quad" or "Triangle")
    props.Thickness = 1
    props.Filled = false -- Filling arbitrary polys in ScreenGui is complex, defaulting to wireframe
    
    -- Points
    props.PointA = Vector2.zero
    props.PointB = Vector2.zero
    props.PointC = Vector2.zero
    if isQuad then props.PointD = Vector2.zero end

    -- Internal Lines
    local Lines = {}
    local lineCount = isQuad and 4 or 3
    for i = 1, lineCount do
        Lines[i] = DrawingLib.new("Line")
    end

    -- We do NOT return a single instance, but we need a Cleanup function
    props._instance = nil 

    local function Update()
        local rTransparency = props.Transparency
        local vis = props.Visible
        local th = props.Thickness
        local col = props.Color
        local z = props.ZIndex

        -- Update internal lines
        local points = {props.PointA, props.PointB, props.PointC}
        if isQuad then table.insert(points, props.PointD) end

        for i = 1, #Lines do
            local line = Lines[i]
            local p1 = points[i]
            local p2 = points[(i % #points) + 1] -- Connect last point to first

            line.Visible = vis
            line.Transparency = rTransparency
            line.Color = col
            line.Thickness = th
            line.ZIndex = z
            line.From = p1
            line.To = p2
        end
    end

    -- Custom cleanup for composite shapes
    local function Cleanup()
        for _, line in ipairs(Lines) do
            line:Remove()
        end
    end

    return props, Update, Cleanup
end

--[[ 
    MAIN CONSTRUCTOR 
]]

function DrawingLib.new(typeStr)
    local props, updateFunc, cleanupFunc
    
    if typeStr == "Line" then props, updateFunc = CreateLine()
    elseif typeStr == "Text" then props, updateFunc = CreateText()
    elseif typeStr == "Circle" then props, updateFunc = CreateCircle()
    elseif typeStr == "Square" then props, updateFunc = CreateSquare()
    elseif typeStr == "Triangle" then props, updateFunc, cleanupFunc = CreatePoly(false)
    elseif typeStr == "Quad" then props, updateFunc, cleanupFunc = CreatePoly(true)
    else error("Invalid Drawing type: " .. tostring(typeStr)) end

    -- Initial Update
    updateFunc()

    -- Metatable Wrapper
    local obj = setmetatable({}, {
        __index = props,
        __newindex = function(self, key, value)
            if props[key] ~= nil then
                props[key] = value
                updateFunc() -- Reactively update on property change
            end
        end,
        __tostring = function() return "Drawing" end
    })

    -- Attach Remove/Destroy methods
    props.Remove = function()
        if props._instance then props._instance:Destroy() end
        if cleanupFunc then cleanupFunc() end
        -- Break metatable
        setmetatable(obj, nil)
    end
    props.Destroy = props.Remove

    -- Add convenience getter for TextBounds on Text objects
    if typeStr == "Text" then
        rawset(props, "TextBounds", Vector2.zero) -- Placeholder, logic handled inside Update usually or via getter
    end

    return obj
end

-- Global Injection (Standard Practice)
getgenv().Drawing = DrawingLib
return DrawingLib
