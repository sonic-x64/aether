local coreGui = game:GetService("CoreGui")
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CustomDrawing = {}
local drawingIndex = 0

function CustomDrawing.new(drawingType)
    drawingIndex += 1
    if drawingType ~= "Circle" then error("Only Circle supported") end

    local drawingUI = coreGui:FindFirstChild("DrawingLibUI") or Instance.new("ScreenGui", coreGui)
    drawingUI.Name = "DrawingLibUI"
    drawingUI.IgnoreGuiInset = true
    drawingUI.DisplayOrder = 100

    local circleFrame = Instance.new("Frame")
    local uiCorner = Instance.new("UICorner", circleFrame)
    local uiStroke = Instance.new("UIStroke", circleFrame)
    local uiGradient = Instance.new("UIGradient", circleFrame)

    circleFrame.Name = "CustomCircle_" .. drawingIndex
    circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    circleFrame.BorderSizePixel = 0
    circleFrame.Parent = drawingUI

    uiCorner.CornerRadius = UDim.new(1, 0)
    
  
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.LineJoinMode = Enum.LineJoinMode.Round
    uiGradient.Enabled = false

    local properties = {
        Radius = 150,
        Position = Vector2.zero,
        Thickness = 1,
        Filled = false,
        Color = Color3.new(1, 1, 1),
        Transparency = 1, 
        FilledTransparency = 0.5,
        Visible = true,
        ZIndex = 0,
        Gradient = nil 
    }

    local function update()
        local robloxTrans = math.clamp(1 - (properties.Transparency or 1), 0, 1)
        
        circleFrame.Size = UDim2.fromOffset(properties.Radius * 2, properties.Radius * 2)
        circleFrame.Position = UDim2.fromOffset(properties.Position.X, properties.Position.Y)
        circleFrame.Visible = properties.Visible
        circleFrame.ZIndex = properties.ZIndex
        
        uiStroke.Thickness = properties.Thickness
        uiStroke.Color = properties.Color
        uiStroke.Transparency = robloxTrans

        if properties.Filled then
            circleFrame.BackgroundTransparency = math.clamp(1 - (properties.FilledTransparency or 1), 0, 1)
            if properties.Gradient and typeof(properties.Gradient) == "table" then
                uiGradient.Enabled = true
                uiGradient.Color = properties.Gradient.Color
                uiGradient.Rotation = properties.Gradient.Rotation or 0
                uiGradient.Transparency = NumberSequence.new(0)
                circleFrame.BackgroundColor3 = Color3.new(1, 1, 1)
            else
                uiGradient.Enabled = false
                circleFrame.BackgroundColor3 = properties.Color
            end
        else
            circleFrame.BackgroundTransparency = 1
            uiGradient.Enabled = false
        end
    end

    return setmetatable({}, {
        __newindex = function(_, key, value)
            properties[key] = value
            update()
        end,
        __index = function(_, key)
            if key == "Remove" or key == "Destroy" then
                return function() circleFrame:Destroy() end
            end
            return properties[key]
        end
    })
end

return CustomDrawing
