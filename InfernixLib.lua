--[[
    InfernixLib - Modern UI Library for Roblox
    Created: January 18, 2026
    
    A powerful, feature-rich UI library for Roblox with:
    - Clean, modern design
    - Smooth animations
    - Configuration saving/loading
    - Multiple themes
    - Comprehensive component library
]]

local InfernixLib = {}
InfernixLib.__index = InfernixLib
InfernixLib._version = "1.0.0"

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Utility Functions
local function Tween(instance, properties, duration, style, direction)
    duration = duration or 0.3
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    
    local tween = TweenService:Create(instance, TweenInfo.new(duration, style, direction), properties)
    tween:Play()
    return tween
end

local function MakeDraggable(frame, dragFrame)
    dragFrame = dragFrame or frame
    
    local dragging = false
    local dragInput, mousePos, framePos
    
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            Tween(frame, {
                Position = UDim2.new(
                    framePos.X.Scale,
                    framePos.X.Offset + delta.X,
                    framePos.Y.Scale,
                    framePos.Y.Offset + delta.Y
                )
            }, 0.1)
        end
    end)
end

local function CreateRipple(button, x, y)
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.BorderSizePixel = 0
    ripple.Position = UDim2.new(0, x - 5, 0, y - 5)
    ripple.Size = UDim2.new(0, 10, 0, 10)
    ripple.ZIndex = button.ZIndex + 1
    ripple.Parent = button
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    
    Tween(ripple, {
        Size = UDim2.new(0, size, 0, size),
        Position = UDim2.new(0, x - size/2, 0, y - size/2),
        BackgroundTransparency = 1
    }, 0.5)
    
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

-- Create static gradient (for compatibility)
local function CreateGradient(parent, rotation, colorKeypoints)
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = rotation or 0
    
    local colorSequence = {}
    for _, keypoint in ipairs(colorKeypoints) do
        table.insert(colorSequence, ColorSequenceKeypoint.new(keypoint[1], keypoint[2]))
    end
    gradient.Color = ColorSequence.new(colorSequence)
    gradient.Parent = parent
    
    return gradient
end

-- Create animated gradient
local function CreateAnimatedGradient(parent, colors, speed)
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 45
    
    -- Convert colors array to color sequence keypoints
    local colorSequence = {}
    for i, colorData in ipairs(colors) do
        local position = colorData[1]
        local color = colorData[2]
        table.insert(colorSequence, ColorSequenceKeypoint.new(position, color))
    end
    gradient.Color = ColorSequence.new(colorSequence)
    gradient.Parent = parent
    
    -- Animate rotation
    task.spawn(function()
        while gradient and gradient.Parent do
            local startRotation = gradient.Rotation
            Tween(gradient, {Rotation = startRotation + 360}, speed or 8, Enum.EasingStyle.Linear)
            task.wait(speed or 8)
        end
    end)
    
    return gradient
end

-- Acrylic Blur System (Fluent-style)
local Acrylic = {}

-- Utils
local function map(value, inMin, inMax, outMin, outMax)
	return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

local function viewportPointToWorld(location, distance)
	local unitRay = Workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
	return unitRay.Origin + unitRay.Direction * distance
end

local function getOffset()
	local viewportSizeY = Workspace.CurrentCamera.ViewportSize.Y
	return map(viewportSizeY, 0, 2560, 8, 56)
end

-- Create Acrylic Glass Part
local function createAcrylic()
	local Part = Instance.new("Part")
	Part.Name = "AcrylicGlass"
	Part.Color = Color3.fromRGB(0, 0, 0)
	Part.Material = Enum.Material.Glass
	Part.Size = Vector3.new(1, 1, 0)
	Part.Anchored = true
	Part.CanCollide = false
	Part.Locked = true
	Part.CastShadow = false
	Part.Transparency = 0.98
	
	local Mesh = Instance.new("SpecialMesh")
	Mesh.MeshType = Enum.MeshType.Brick
	Mesh.Offset = Vector3.new(0, 0, -0.000001)
	Mesh.Parent = Part
	
	return Part
end

-- Initialize DepthOfField
local DepthOfField = Instance.new("DepthOfFieldEffect")
DepthOfField.FarIntensity = 0
DepthOfField.InFocusRadius = 0.1
DepthOfField.NearIntensity = 1
DepthOfField.Parent = game:GetService("Lighting")

local BlurFolder = Instance.new("Folder")
BlurFolder.Name = "InfernixAcrylicBlur"
BlurFolder.Parent = Workspace.CurrentCamera

-- Create Acrylic Blur
local function createAcrylicBlur(distance)
	local cleanups = {}

	distance = distance or 0.001
	local positions = {
		topLeft = Vector2.new(),
		topRight = Vector2.new(),
		bottomRight = Vector2.new(),
	}
	local model = createAcrylic()
	model.Parent = BlurFolder

	local function updatePositions(size, position)
		positions.topLeft = position
		positions.topRight = position + Vector2.new(size.X, 0)
		positions.bottomRight = position + size
	end

	local function render()
		local res = Workspace.CurrentCamera
		if res then
			res = res.CFrame
		end
		local cond = res
		if not cond then
			cond = CFrame.new()
		end

		local camera = cond
		local topLeft = positions.topLeft
		local topRight = positions.topRight
		local bottomRight = positions.bottomRight

		local topLeft3D = viewportPointToWorld(topLeft, distance)
		local topRight3D = viewportPointToWorld(topRight, distance)
		local bottomRight3D = viewportPointToWorld(bottomRight, distance)

		local width = (topRight3D - topLeft3D).Magnitude
		local height = (topRight3D - bottomRight3D).Magnitude

		model.CFrame =
			CFrame.fromMatrix((topLeft3D + bottomRight3D) / 2, camera.XVector, camera.YVector, camera.ZVector)
		model.Mesh.Scale = Vector3.new(width, height, 0)
	end

	local function onChange(rbx)
		local offset = getOffset()
		local size = rbx.AbsoluteSize - Vector2.new(offset, offset)
		local position = rbx.AbsolutePosition + Vector2.new(offset / 2, offset / 2)

		updatePositions(size, position)
		task.spawn(render)
	end

	local function renderOnChange()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		table.insert(cleanups, camera:GetPropertyChangedSignal("CFrame"):Connect(render))
		table.insert(cleanups, camera:GetPropertyChangedSignal("ViewportSize"):Connect(render))
		table.insert(cleanups, camera:GetPropertyChangedSignal("FieldOfView"):Connect(render))
		task.spawn(render)
	end

	model.Destroying:Connect(function()
		for _, item in cleanups do
			pcall(function()
				item:Disconnect()
			end)
		end
	end)

	renderOnChange()

	return onChange, model
end

-- AcrylicBlur constructor
Acrylic.AcrylicBlur = function(distance)
	local Blur = {}
	local onChange, model = createAcrylicBlur(distance)

	local comp = Instance.new("Frame")
	comp.BackgroundTransparency = 1
	comp.Size = UDim2.fromScale(1, 1)

	comp:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		onChange(comp)
	end)

	comp:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		onChange(comp)
	end)

	Blur.AddParent = function(Parent)
		Parent:GetPropertyChangedSignal("Visible"):Connect(function()
			Blur.SetVisibility(Parent.Visible)
		end)
	end

	Blur.SetVisibility = function(Value)
		model.Transparency = Value and 0.98 or 1
	end

	Blur.Frame = comp
	Blur.Model = model

	return Blur
end

Acrylic.DepthOfField = DepthOfField

-- Create animated particles
local function CreateParticles(parent, count, color)
    local particles = {}
    
    for i = 1, count do
        local particle = Instance.new("Frame")
        particle.Name = "Particle"
        particle.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = color or Color3.fromRGB(138, 80, 255)
        particle.BackgroundTransparency = math.random(30, 70) / 100
        particle.BorderSizePixel = 0
        particle.ZIndex = 2
        particle.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
        
        table.insert(particles, particle)
        
        -- Animate particle
        task.spawn(function()
            while particle and particle.Parent do
                local randomX = math.random(-50, 50) / 100
                local randomY = math.random(-50, 50) / 100
                local duration = math.random(3, 6)
                
                Tween(particle, {
                    Position = UDim2.new(
                        math.clamp(particle.Position.X.Scale + randomX, 0, 1),
                        0,
                        math.clamp(particle.Position.Y.Scale + randomY, 0, 1),
                        0
                    ),
                    BackgroundTransparency = math.random(30, 80) / 100
                }, duration, Enum.EasingStyle.Sine)
                
                task.wait(duration)
            end
        end)
    end
    
    return particles
end

-- Icon library with actual Roblox asset IDs
InfernixLib.Icons = {
    Home = "rbxassetid://10723434711",
    Settings = "rbxassetid://10734950309",
    User = "rbxassetid://10747374131",
    Shield = "rbxassetid://10723407389",
    Eye = "rbxassetid://10747374131",
    Gamepad = "rbxassetid://10709790537",
    Sparkles = "rbxassetid://10709791437",
    Code = "rbxassetid://10709769841",
    Info = "rbxassetid://10723434711",
    Check = "rbxassetid://10709818534",
    X = "rbxassetid://10747384394",
    Search = "rbxassetid://10734898355",
    Zap = "rbxassetid://10747372992"
}

-- Themes - Premium color schemes with gradients
InfernixLib.Themes = {
    Dark = {
        Background = Color3.fromRGB(32, 32, 32),
        SecondaryBackground = Color3.fromRGB(43, 43, 43),
        TertiaryBackground = Color3.fromRGB(54, 54, 54),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(200, 200, 200),
        Accent = Color3.fromRGB(70, 70, 70), -- Dark Gray
        AccentGradient = {
            Color3.fromRGB(70, 70, 70),
            Color3.fromRGB(90, 90, 90),
            Color3.fromRGB(0, 90, 158)
        },
        ElementBackground = Color3.fromRGB(45, 45, 45),
        ElementBorder = Color3.fromRGB(60, 60, 60),
        ElementHover = Color3.fromRGB(55, 55, 55),
        Success = Color3.fromRGB(16, 185, 129),
        Warning = Color3.fromRGB(245, 158, 11),
        Error = Color3.fromRGB(239, 68, 68)
    },
    Light = {
        Background = Color3.fromRGB(255, 255, 255),
        SecondaryBackground = Color3.fromRGB(249, 250, 251),
        TertiaryBackground = Color3.fromRGB(243, 244, 246),
        Text = Color3.fromRGB(17, 24, 39),
        SubText = Color3.fromRGB(107, 114, 128),
        Accent = Color3.fromRGB(147, 51, 234),
        AccentGradient = {
            Color3.fromRGB(147, 51, 234),
            Color3.fromRGB(219, 39, 119),
            Color3.fromRGB(236, 72, 153)
        },
        ElementBackground = Color3.fromRGB(255, 255, 255),
        ElementBorder = Color3.fromRGB(229, 231, 235),
        ElementHover = Color3.fromRGB(243, 244, 246),
        Success = Color3.fromRGB(16, 185, 129),
        Warning = Color3.fromRGB(245, 158, 11),
        Error = Color3.fromRGB(239, 68, 68)
    },
    Midnight = {
        Background = Color3.fromRGB(5, 10, 20),
        SecondaryBackground = Color3.fromRGB(10, 15, 28),
        TertiaryBackground = Color3.fromRGB(15, 22, 36),
        Text = Color3.fromRGB(220, 235, 255),
        SubText = Color3.fromRGB(140, 170, 210),
        Accent = Color3.fromRGB(59, 130, 246), -- Blue
        AccentGradient = {
            Color3.fromRGB(59, 130, 246),
            Color3.fromRGB(99, 102, 241),
            Color3.fromRGB(139, 92, 246)
        },
        ElementBackground = Color3.fromRGB(12, 18, 32),
        ElementBorder = Color3.fromRGB(30, 40, 62),
        ElementHover = Color3.fromRGB(18, 25, 42),
        Success = Color3.fromRGB(52, 211, 153),
        Warning = Color3.fromRGB(251, 191, 36),
        Error = Color3.fromRGB(248, 113, 113)
    },
    Sunset = {
        Background = Color3.fromRGB(18, 8, 15),
        SecondaryBackground = Color3.fromRGB(25, 12, 20),
        TertiaryBackground = Color3.fromRGB(32, 16, 26),
        Text = Color3.fromRGB(255, 240, 250),
        SubText = Color3.fromRGB(210, 170, 195),
        Accent = Color3.fromRGB(244, 63, 94), -- Pink/Red
        AccentGradient = {
            Color3.fromRGB(244, 63, 94),
            Color3.fromRGB(251, 113, 133),
            Color3.fromRGB(253, 164, 175)
        },
        ElementBackground = Color3.fromRGB(22, 10, 18),
        ElementBorder = Color3.fromRGB(48, 22, 38),
        ElementHover = Color3.fromRGB(32, 14, 26),
        Success = Color3.fromRGB(52, 211, 153),
        Warning = Color3.fromRGB(251, 191, 36),
        Error = Color3.fromRGB(248, 113, 113)
    }
}

-- Main Library Functions
function InfernixLib:CreateWindow(config)
    config = config or {}
    local Window = {
        Name = config.Name or "InfernixLib",
        Icon = config.Icon,
        LoadingTitle = config.LoadingTitle or "InfernixLib",
        LoadingSubtitle = config.LoadingSubtitle or "Loading...",
        Theme = InfernixLib.Themes[config.Theme] or InfernixLib.Themes.Dark,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl,
        ConfigSaving = config.ConfigSaving or {},
        Tabs = {},
        CurrentTab = nil,
        Visible = false
    }
    
    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InfernixLib_" .. HttpService:GenerateGUID(false)
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    
    if gethui then
        ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = CoreGui
    end
    
    Window.ScreenGui = ScreenGui
    
    -- Main Frame with proper Fluent-style layout
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 580, 0, 460)
    MainFrame.Position = UDim2.new(0.5, -290, 0.5, -230)
    MainFrame.BackgroundTransparency = 1
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = false
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui
    
    -- Professional acrylic background (Fluent-style with REAL 3D blur)
    local Background = Instance.new("Frame")
    Background.Name = "Background"
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.Position = UDim2.new(0, 0, 0, 0)
    Background.BackgroundColor3 = Window.Theme.Background
    Background.BackgroundTransparency = 1
    Background.BorderSizePixel = 0
    Background.ZIndex = 0
    Background.Parent = MainFrame
    
    local BackgroundCorner = Instance.new("UICorner")
    BackgroundCorner.CornerRadius = UDim.new(0, 12)
    BackgroundCorner.Parent = Background
    
    -- Create REAL 3D acrylic blur for the background
    local AcrylicBlur = Acrylic.AcrylicBlur(0.001)
    AcrylicBlur.Frame.Parent = Background
    AcrylicBlur.AddParent(MainFrame)
    Window.AcrylicBlur = AcrylicBlur
    
    -- Premium border with subtle glow
    local BorderStroke = Instance.new("UIStroke")
    BorderStroke.Color = Color3.fromRGB(120, 120, 120)
    BorderStroke.Thickness = 2
    BorderStroke.Transparency = 0.6
    BorderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    BorderStroke.Parent = Background
    
    Window.MainFrame = MainFrame
    
    -- Top Bar (Fluent-style header)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 50)
    TopBar.BackgroundTransparency = 1
    TopBar.BorderSizePixel = 0
    TopBar.ZIndex = 10
    TopBar.Parent = MainFrame
    
    -- Separator line under TopBar
    local TopBarSeparator = Instance.new("Frame")
    TopBarSeparator.Name = "Separator"
    TopBarSeparator.Size = UDim2.new(1, -24, 0, 1)
    TopBarSeparator.Position = UDim2.new(0, 12, 1, 0)
    TopBarSeparator.BackgroundColor3 = Window.Theme.ElementBorder
    TopBarSeparator.BackgroundTransparency = 0.5
    TopBarSeparator.BorderSizePixel = 0
    TopBarSeparator.ZIndex = 10
    TopBarSeparator.Parent = TopBar
    
    -- Logo (clean, professional)
    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.Size = UDim2.new(0, 20, 0, 20)
    Logo.Position = UDim2.new(0, 16, 0, 15)
    Logo.BackgroundTransparency = 1
    Logo.Image = Window.Icon or InfernixLib.Icons.Sparkles
    Logo.ImageColor3 = Window.Theme.Accent
    Logo.ZIndex = 10
    Logo.Parent = TopBar
    
    -- Title (Fluent-style typography)
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -160, 0, 20)
    Title.Position = UDim2.new(0, 44, 0, 15)
    Title.BackgroundTransparency = 1
    Title.Text = Window.Name
    Title.TextColor3 = Window.Theme.Text
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamSemibold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.ZIndex = 10
    Title.Parent = TopBar
    
    -- Minimize Button (Fluent-style)
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Size = UDim2.new(0, 32, 0, 32)
    MinimizeButton.Position = UDim2.new(1, -76, 0, 9)
    MinimizeButton.BackgroundColor3 = Window.Theme.ElementBackground
    MinimizeButton.BackgroundTransparency = 1
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Text = ""
    MinimizeButton.AutoButtonColor = false
    MinimizeButton.ZIndex = 10
    MinimizeButton.Parent = TopBar
    
    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(0, 6)
    MinimizeCorner.Parent = MinimizeButton
    
    local MinimizeIcon = Instance.new("TextLabel")
    MinimizeIcon.Size = UDim2.new(1, 0, 1, 0)
    MinimizeIcon.BackgroundTransparency = 1
    MinimizeIcon.Text = "─"
    MinimizeIcon.TextColor3 = Window.Theme.SubText
    MinimizeIcon.TextSize = 14
    MinimizeIcon.Font = Enum.Font.GothamSemibold
    MinimizeIcon.ZIndex = 10
    MinimizeIcon.Parent = MinimizeButton
    
    MinimizeButton.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)
    
    MinimizeButton.MouseEnter:Connect(function()
        Tween(MinimizeButton, {BackgroundTransparency = 0.7})
    end)
    
    MinimizeButton.MouseLeave:Connect(function()
        Tween(MinimizeButton, {BackgroundTransparency = 1})
    end)
    
    -- Close Button (Fluent-style with hover effect)
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 32, 0, 32)
    CloseButton.Position = UDim2.new(1, -38, 0, 9)
    CloseButton.BackgroundColor3 = Window.Theme.ElementBackground
    CloseButton.BackgroundTransparency = 1
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = ""
    CloseButton.AutoButtonColor = false
    CloseButton.ZIndex = 10
    CloseButton.Parent = TopBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseButton
    
    local CloseIcon = Instance.new("TextLabel")
    CloseIcon.Size = UDim2.new(1, 0, 1, 0)
    CloseIcon.BackgroundTransparency = 1
    CloseIcon.Text = "X"
    CloseIcon.TextColor3 = Window.Theme.SubText
    CloseIcon.TextSize = 16
    CloseIcon.Font = Enum.Font.GothamBold
    CloseIcon.ZIndex = 10
    CloseIcon.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        -- Clean up acrylic blur
        if Window.AcrylicBlur and Window.AcrylicBlur.Model then
            Window.AcrylicBlur.Model:Destroy()
        end
        if Acrylic.DepthOfField then
            Acrylic.DepthOfField:Destroy()
        end
        Tween(MainFrame, {Size = UDim2.new(0, 580, 0, 0)}, 0.3, Enum.EasingStyle.Quint).Completed:Connect(function()
            ScreenGui:Destroy()
        end)
    end)
    
    CloseButton.MouseEnter:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(196, 43, 28), BackgroundTransparency = 0})
        Tween(CloseIcon, {TextColor3 = Color3.fromRGB(255, 255, 255)})
    end)
    
    CloseButton.MouseLeave:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Window.Theme.ElementBackground, BackgroundTransparency = 1})
        Tween(CloseIcon, {TextColor3 = Window.Theme.SubText})
    end)
    
    MakeDraggable(MainFrame, TopBar)
    
    -- Horizontal Tab Container (Fluent-style)
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -24, 0, 42)
    TabContainer.Position = UDim2.new(0, 12, 0, 58)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.ScrollBarThickness = 0
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 42)
    TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
    TabContainer.ScrollingDirection = Enum.ScrollingDirection.X
    TabContainer.ZIndex = 5
    TabContainer.Parent = MainFrame
    
    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 8)
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.VerticalAlignment = Enum.VerticalAlignment.Center
    TabList.Parent = TabContainer
    
    Window.TabContainer = TabContainer
    
    -- Content Container (below tabs)
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -24, 1, -112)
    ContentContainer.Position = UDim2.new(0, 12, 0, 108)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.BorderSizePixel = 0
    ContentContainer.ClipsDescendants = true
    ContentContainer.ZIndex = 5
    ContentContainer.Parent = MainFrame
    
    Window.ContentContainer = ContentContainer
    
    -- Toggle UI with smooth animation
    function Window:Toggle()
        self.Visible = not self.Visible
        if self.Visible then
            MainFrame.Visible = true
            MainFrame.Size = UDim2.new(0, 580, 0, 0)
            if self.AcrylicBlur then
                self.AcrylicBlur.SetVisibility(true)
            end
            Tween(MainFrame, {Size = UDim2.new(0, 580, 0, 460)}, 0.35, Enum.EasingStyle.Quint)
        else
            if self.AcrylicBlur then
                self.AcrylicBlur.SetVisibility(false)
            end
            Tween(MainFrame, {Size = UDim2.new(0, 580, 0, 0)}, 0.25, Enum.EasingStyle.Quint).Completed:Connect(function()
                MainFrame.Visible = false
            end)
        end
    end
    
    -- Minimize UI (collapse to titlebar)
    function Window:Minimize()
        self.Minimized = not self.Minimized
        if self.Minimized then
            TabContainer.Visible = false
            ContentContainer.Visible = false
            Tween(MainFrame, {Size = UDim2.new(0, 580, 0, 50)}, 0.25, Enum.EasingStyle.Quint)
        else
            Tween(MainFrame, {Size = UDim2.new(0, 580, 0, 460)}, 0.25, Enum.EasingStyle.Quint).Completed:Connect(function()
                TabContainer.Visible = true
                ContentContainer.Visible = true
            end)
        end
    end
    
    -- Keybind toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Window.ToggleKey then
            Window:Toggle()
        end
    end)
    
    -- Configuration System
    Window.ConfigFlags = {}
    
    function Window:SaveConfig()
        if not self.ConfigSaving.Enabled then return end
        
        local configData = {}
        for flag, value in pairs(self.ConfigFlags) do
            configData[flag] = value
        end
        
        local success, result = pcall(function()
            local folderName = self.ConfigSaving.FolderName or "InfernixLib"
            local fileName = self.ConfigSaving.FileName or "config"
            
            if not isfolder(folderName) then
                makefolder(folderName)
            end
            
            local filePath = folderName .. "/" .. fileName .. ".json"
            local jsonData = HttpService:JSONEncode(configData)
            writefile(filePath, jsonData)
        end)
        
        if not success then
            warn("InfernixLib: Failed to save configuration - " .. tostring(result))
        end
    end
    
    function Window:LoadConfig()
        if not self.ConfigSaving.Enabled then return end
        
        local success, result = pcall(function()
            local folderName = self.ConfigSaving.FolderName or "InfernixLib"
            local fileName = self.ConfigSaving.FileName or "config"
            local filePath = folderName .. "/" .. fileName .. ".json"
            
            if isfile(filePath) then
                local fileData = readfile(filePath)
                local configData = HttpService:JSONDecode(fileData)
                
                -- Apply loaded config
                for flag, value in pairs(configData) do
                    self.ConfigFlags[flag] = value
                end
                
                return true
            end
            return false
        end)
        
        if not success then
            warn("InfernixLib: Failed to load configuration - " .. tostring(result))
            return false
        end
        
        return result
    end
    
    function Window:RegisterFlag(flag, value, callback)
        if flag then
            self.ConfigFlags[flag] = value
            
            -- Auto-save on flag change
            if self.ConfigSaving.Enabled and self.ConfigSaving.AutoSave then
                task.spawn(function()
                    task.wait(0.5) -- Debounce
                    self:SaveConfig()
                end)
            end
        end
    end
    
    -- Start visible
    Window:Toggle()
    
    -- Create Tab function
    function Window:CreateTab(name, icon)
        local Tab = {
            Name = name,
            Icon = icon,
            Elements = {},
            Window = self
        }
        
        -- Horizontal Tab Button (Fluent-style)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = name
        TabButton.Size = UDim2.new(0, 0, 0, 36)
        TabButton.AutomaticSize = Enum.AutomaticSize.X
        TabButton.BackgroundColor3 = Window.Theme.ElementBackground
        TabButton.BackgroundTransparency = 1
        TabButton.BorderSizePixel = 0
        TabButton.Text = ""
        TabButton.AutoButtonColor = false
        TabButton.ZIndex = 6
        TabButton.Parent = TabContainer
        
        local TabButtonCorner = Instance.new("UICorner")
        TabButtonCorner.CornerRadius = UDim.new(0, 6)
        TabButtonCorner.Parent = TabButton
        
        local TabButtonPadding = Instance.new("UIPadding")
        TabButtonPadding.PaddingLeft = UDim.new(0, 12)
        TabButtonPadding.PaddingRight = UDim.new(0, 12)
        TabButtonPadding.Parent = TabButton
        
        -- Tab content container (horizontal layout with icon + text)
        local TabButtonContent = Instance.new("Frame")
        TabButtonContent.Name = "Content"
        TabButtonContent.Size = UDim2.new(1, 0, 1, 0)
        TabButtonContent.BackgroundTransparency = 1
        TabButtonContent.Parent = TabButton
        
        local TabButtonLayout = Instance.new("UIListLayout")
        TabButtonLayout.FillDirection = Enum.FillDirection.Horizontal
        TabButtonLayout.Padding = UDim.new(0, 8)
        TabButtonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        TabButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        TabButtonLayout.Parent = TabButtonContent
        
        -- Tab Icon (smaller, inline with text)
        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Name = "Icon"
        TabIcon.Size = UDim2.new(0, 16, 0, 16)
        TabIcon.BackgroundTransparency = 1
        TabIcon.Image = icon or InfernixLib.Icons.Home
        TabIcon.ImageColor3 = Window.Theme.SubText
        TabIcon.ZIndex = 8
        TabIcon.Parent = TabButtonContent
        
        -- Tab Text (inline with icon)
        local TabText = Instance.new("TextLabel")
        TabText.Name = "Label"
        TabText.Size = UDim2.new(0, 0, 1, 0)
        TabText.AutomaticSize = Enum.AutomaticSize.X
        TabText.BackgroundTransparency = 1
        TabText.Text = name
        TabText.TextColor3 = Window.Theme.SubText
        TabText.TextSize = 13
        TabText.Font = Enum.Font.GothamSemibold
        TabText.ZIndex = 8
        TabText.Parent = TabButtonContent
        
        -- Active indicator (bottom border - Fluent style)
        local ActiveBar = Instance.new("Frame")
        ActiveBar.Name = "ActiveBar"
        ActiveBar.Size = UDim2.new(1, -16, 0, 2)
        ActiveBar.Position = UDim2.new(0, 8, 1, -3)
        ActiveBar.BackgroundColor3 = Window.Theme.Accent
        ActiveBar.BackgroundTransparency = 1
        ActiveBar.BorderSizePixel = 0
        ActiveBar.ZIndex = 7
        ActiveBar.Parent = TabButton
        
        local BarCorner = Instance.new("UICorner")
        BarCorner.CornerRadius = UDim.new(1, 0)
        BarCorner.Parent = ActiveBar
        
        Tab.Button = TabButton
        Tab.Icon = TabIcon
        Tab.Text = TabText
        Tab.ActiveBar = ActiveBar
        
        -- Tab Content
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = name .. "_Content"
        TabContent.Size = UDim2.new(1, -10, 1, 0)
        TabContent.Position = UDim2.new(0, 0, 0, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 4
        TabContent.ScrollBarImageColor3 = Window.Theme.Accent
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabContent.Visible = false
        TabContent.Parent = ContentContainer
        
        local ContentList = Instance.new("UIListLayout")
        ContentList.Padding = UDim.new(0, 10)
        ContentList.SortOrder = Enum.SortOrder.LayoutOrder
        ContentList.Parent = TabContent
        
        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.PaddingTop = UDim.new(0, 8)
        ContentPadding.PaddingBottom = UDim.new(0, 8)
        ContentPadding.PaddingRight = UDim.new(0, 8)
        ContentPadding.Parent = TabContent
        
        Tab.Content = TabContent
        
        -- Select tab with Fluent-style animations
        local function SelectTab()
            for _, tab in pairs(Window.Tabs) do
                Tween(tab.Button, {BackgroundTransparency = 1})
                Tween(tab.Icon, {ImageColor3 = Window.Theme.SubText})
                Tween(tab.Text, {TextColor3 = Window.Theme.SubText})
                Tween(tab.ActiveBar, {BackgroundTransparency = 1}, 0.2)
                tab.Content.Visible = false
            end
            
            Tween(TabButton, {BackgroundTransparency = 0.9})
            Tween(TabIcon, {ImageColor3 = Window.Theme.Accent})
            Tween(TabText, {TextColor3 = Window.Theme.Accent})
            Tween(ActiveBar, {BackgroundTransparency = 0}, 0.3, Enum.EasingStyle.Quint)
            TabContent.Visible = true
            Window.CurrentTab = Tab
        end
        
        TabButton.MouseButton1Click:Connect(function()
            SelectTab()
        end)
        
        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, {BackgroundTransparency = 0.85})
                Tween(TabIcon, {ImageColor3 = Window.Theme.Text})
                Tween(TabText, {TextColor3 = Window.Theme.Text})
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, {BackgroundTransparency = 1})
                Tween(TabIcon, {ImageColor3 = Window.Theme.SubText})
                Tween(TabText, {TextColor3 = Window.Theme.SubText})
            end
        end)
        
        table.insert(Window.Tabs, Tab)
        
        -- Select first tab
        if #Window.Tabs == 1 then
            SelectTab()
        end
        
        -- Section
        function Tab:CreateSection(name)
            local Section = Instance.new("TextLabel")
            Section.Name = "Section"
            Section.Size = UDim2.new(1, 0, 0, 30)
            Section.BackgroundTransparency = 1
            Section.Text = name
            Section.TextColor3 = Window.Theme.Text
            Section.TextSize = 16
            Section.Font = Enum.Font.GothamBold
            Section.TextXAlignment = Enum.TextXAlignment.Left
            Section.Parent = TabContent
            
            local SectionPadding = Instance.new("UIPadding")
            SectionPadding.PaddingLeft = UDim.new(0, 10)
            SectionPadding.Parent = Section
            
            local SectionObj = {Element = Section}
            
            function SectionObj:Set(text)
                Section.Text = text
            end
            
            return SectionObj
        end
        
        -- Button
        function Tab:CreateButton(config)
            config = config or {}
            local Button = {
                Name = config.Name or "Button",
                Callback = config.Callback or function() end
            }
            
            local ButtonFrame = Instance.new("Frame")
            ButtonFrame.Name = "Button"
            ButtonFrame.Size = UDim2.new(1, 0, 0, 40)
            ButtonFrame.BackgroundColor3 = Window.Theme.ElementBackground
            ButtonFrame.BackgroundTransparency = 0.5
            ButtonFrame.BorderSizePixel = 0
            ButtonFrame.Parent = TabContent
            
            local ButtonCorner = Instance.new("UICorner")
            ButtonCorner.CornerRadius = UDim.new(0, 8)
            ButtonCorner.Parent = ButtonFrame
            
            -- Professional border
            local ButtonBorder = Instance.new("UIStroke")
            ButtonBorder.Color = Window.Theme.ElementBorder
            ButtonBorder.Transparency = 0.5
            ButtonBorder.Thickness = 1
            ButtonBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            ButtonBorder.Parent = ButtonFrame
            
            local ButtonButton = Instance.new("TextButton")
            ButtonButton.Name = "ButtonButton"
            ButtonButton.Size = UDim2.new(1, 0, 1, 0)
            ButtonButton.BackgroundTransparency = 1
            ButtonButton.Text = ""
            ButtonButton.ZIndex = 2
            ButtonButton.Parent = ButtonFrame
            
            local ButtonLabel = Instance.new("TextLabel")
            ButtonLabel.Name = "Label"
            ButtonLabel.Size = UDim2.new(1, -24, 1, 0)
            ButtonLabel.Position = UDim2.new(0, 12, 0, 0)
            ButtonLabel.BackgroundTransparency = 1
            ButtonLabel.Text = Button.Name
            ButtonLabel.TextColor3 = Window.Theme.Text
            ButtonLabel.TextSize = 13
            ButtonLabel.Font = Enum.Font.GothamSemibold
            ButtonLabel.TextXAlignment = Enum.TextXAlignment.Center
            ButtonLabel.ZIndex = 3
            ButtonLabel.Parent = ButtonFrame
            
            -- Click icon indicator
            local ClickIcon = Instance.new("TextLabel")
            ClickIcon.Name = "ClickIcon"
            ClickIcon.Size = UDim2.new(0, 16, 0, 16)
            ClickIcon.Position = UDim2.new(1, -24, 0.5, -8)
            ClickIcon.BackgroundTransparency = 1
            ClickIcon.Text = "▶"
            ClickIcon.TextColor3 = Window.Theme.SubText
            ClickIcon.TextSize = 10
            ClickIcon.Font = Enum.Font.GothamBold
            ClickIcon.ZIndex = 3
            ClickIcon.Parent = ButtonFrame
            
            ButtonButton.MouseButton1Click:Connect(function()
                -- Professional click animation
                Tween(ButtonFrame, {BackgroundTransparency = 0.2}, 0.1)
                Tween(ButtonBorder, {Color = Window.Theme.Accent, Transparency = 0}, 0.1)
                Tween(ButtonLabel, {TextColor3 = Window.Theme.Accent}, 0.1)
                
                task.wait(0.15)
                
                Tween(ButtonFrame, {BackgroundTransparency = 0.5}, 0.2)
                Tween(ButtonBorder, {Color = Window.Theme.ElementBorder, Transparency = 0.5}, 0.2)
                Tween(ButtonLabel, {TextColor3 = Window.Theme.Text}, 0.2)
                
                pcall(Button.Callback)
            end)
            
            ButtonButton.MouseEnter:Connect(function()
                Tween(ButtonFrame, {BackgroundTransparency = 0.3}, 0.15)
                Tween(ButtonBorder, {Transparency = 0.2}, 0.15)
                Tween(ClickIcon, {TextColor3 = Window.Theme.Accent}, 0.15)
            end)
            
            ButtonButton.MouseLeave:Connect(function()
                Tween(ButtonFrame, {BackgroundTransparency = 0.5}, 0.15)
                Tween(ButtonBorder, {Transparency = 0.5}, 0.15)
                Tween(ClickIcon, {TextColor3 = Window.Theme.SubText}, 0.15)
            end)
            
            Button.Element = ButtonFrame
            
            function Button:Set(name)
                ButtonLabel.Text = name
                self.Name = name
            end
            
            return Button
        end
        
        -- Toggle
        function Tab:CreateToggle(config)
            config = config or {}
            local Toggle = {
                Name = config.Name or "Toggle",
                CurrentValue = config.CurrentValue or false,
                Flag = config.Flag,
                Callback = config.Callback or function() end
            }
            
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Name = "Toggle"
            ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
            ToggleFrame.BackgroundColor3 = Window.Theme.ElementBackground
            ToggleFrame.BackgroundTransparency = 0.5
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Parent = TabContent
            
            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 8)
            ToggleCorner.Parent = ToggleFrame
            
            local ToggleBorder = Instance.new("UIStroke")
            ToggleBorder.Color = Window.Theme.ElementBorder
            ToggleBorder.Transparency = 0.5
            ToggleBorder.Thickness = 1
            ToggleBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            ToggleBorder.Parent = ToggleFrame
            
            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Name = "Label"
            ToggleLabel.Size = UDim2.new(1, -70, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 12, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = Toggle.Name
            ToggleLabel.TextColor3 = Window.Theme.Text
            ToggleLabel.TextSize = 13
            ToggleLabel.Font = Enum.Font.GothamSemibold
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.ZIndex = 2
            ToggleLabel.Parent = ToggleFrame
            
            -- Professional toggle switch
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Name = "ToggleButton"
            ToggleButton.Size = UDim2.new(0, 44, 0, 24)
            ToggleButton.Position = UDim2.new(1, -54, 0.5, -12)
            ToggleButton.BackgroundColor3 = Window.Theme.ElementBorder
            ToggleButton.BackgroundTransparency = 0
            ToggleButton.BorderSizePixel = 0
            ToggleButton.Text = ""
            ToggleButton.AutoButtonColor = false
            ToggleButton.ZIndex = 2
            ToggleButton.Parent = ToggleFrame
            
            local ToggleButtonCorner = Instance.new("UICorner")
            ToggleButtonCorner.CornerRadius = UDim.new(1, 0)
            ToggleButtonCorner.Parent = ToggleButton
            
            local ToggleIndicator = Instance.new("Frame")
            ToggleIndicator.Name = "Indicator"
            ToggleIndicator.Size = UDim2.new(0, 18, 0, 18)
            ToggleIndicator.Position = UDim2.new(0, 3, 0.5, -9)
            ToggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleIndicator.BorderSizePixel = 0
            ToggleIndicator.ZIndex = 3
            ToggleIndicator.Parent = ToggleButton
            
            local IndicatorCorner = Instance.new("UICorner")
            IndicatorCorner.CornerRadius = UDim.new(1, 0)
            IndicatorCorner.Parent = ToggleIndicator
            
            -- Shadow for indicator
            local IndicatorShadow = Instance.new("ImageLabel")
            IndicatorShadow.Size = UDim2.new(1, 4, 1, 4)
            IndicatorShadow.Position = UDim2.new(0.5, 0, 0.5, 1)
            IndicatorShadow.AnchorPoint = Vector2.new(0.5, 0.5)
            IndicatorShadow.BackgroundTransparency = 1
            IndicatorShadow.Image = "rbxassetid://5028857084"
            IndicatorShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
            IndicatorShadow.ImageTransparency = 0.7
            IndicatorShadow.ZIndex = 2
            IndicatorShadow.Parent = ToggleIndicator
            
            local function UpdateToggle(value, skipCallback)
                Toggle.CurrentValue = value
                
                if value then
                    Tween(ToggleButton, {BackgroundColor3 = Window.Theme.Accent}, 0.2)
                    Tween(ToggleIndicator, {Position = UDim2.new(1, -21, 0.5, -9)}, 0.2, Enum.EasingStyle.Quint)
                    Tween(ToggleBorder, {Color = Window.Theme.Accent, Transparency = 0.3}, 0.2)
                else
                    Tween(ToggleButton, {BackgroundColor3 = Window.Theme.ElementBorder}, 0.2)
                    Tween(ToggleIndicator, {Position = UDim2.new(0, 3, 0.5, -9)}, 0.2, Enum.EasingStyle.Quint)
                    Tween(ToggleBorder, {Color = Window.Theme.ElementBorder, Transparency = 0.5}, 0.2)
                end
                
                Window:RegisterFlag(Toggle.Flag, value)
                if not skipCallback then
                    pcall(Toggle.Callback, value)
                end
            end
            
            ToggleButton.MouseButton1Click:Connect(function()
                UpdateToggle(not Toggle.CurrentValue)
            end)
            
            ToggleFrame.MouseEnter:Connect(function()
                Tween(ToggleFrame, {BackgroundTransparency = 0.3}, 0.15)
            end)
            
            ToggleFrame.MouseLeave:Connect(function()
                Tween(ToggleFrame, {BackgroundTransparency = 0.5}, 0.15)
            end)
            
            Toggle.Element = ToggleFrame
            
            function Toggle:SetValue(value)
                UpdateToggle(value, true)
            end
            
            function Toggle:Set(value)
                UpdateToggle(value)
            end
            
            -- Initialize with current value
            if Toggle.CurrentValue then
                UpdateToggle(true, true)
            end
            
            return Toggle
        end
        
        -- Slider
        function Tab:CreateSlider(config)
            config = config or {}
            local Slider = {
                Name = config.Name or "Slider",
                Min = config.Min or 0,
                Max = config.Max or 100,
                Increment = config.Increment or 1,
                CurrentValue = config.CurrentValue or config.Min or 0,
                Flag = config.Flag,
                Callback = config.Callback or function() end
            }
            
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Name = "Slider"
            SliderFrame.Size = UDim2.new(1, 0, 0, 55)
            SliderFrame.BackgroundColor3 = Window.Theme.ElementBackground
            SliderFrame.BorderSizePixel = 0
            SliderFrame.Parent = TabContent
            
            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UDim.new(0, 8)
            SliderCorner.Parent = SliderFrame
            
            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Name = "Label"
            SliderLabel.Size = UDim2.new(1, -70, 0, 20)
            SliderLabel.Position = UDim2.new(0, 10, 0, 8)
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.Text = Slider.Name
            SliderLabel.TextColor3 = Window.Theme.Text
            SliderLabel.TextSize = 14
            SliderLabel.Font = Enum.Font.Gotham
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            SliderLabel.Parent = SliderFrame
            
            local SliderValue = Instance.new("TextLabel")
            SliderValue.Name = "Value"
            SliderValue.Size = UDim2.new(0, 60, 0, 20)
            SliderValue.Position = UDim2.new(1, -70, 0, 8)
            SliderValue.BackgroundTransparency = 1
            SliderValue.Text = tostring(Slider.CurrentValue)
            SliderValue.TextColor3 = Window.Theme.Accent
            SliderValue.TextSize = 14
            SliderValue.Font = Enum.Font.GothamBold
            SliderValue.TextXAlignment = Enum.TextXAlignment.Right
            SliderValue.Parent = SliderFrame
            
            local SliderBackground = Instance.new("Frame")
            SliderBackground.Name = "SliderBackground"
            SliderBackground.Size = UDim2.new(1, -20, 0, 6)
            SliderBackground.Position = UDim2.new(0, 10, 1, -16)
            SliderBackground.BackgroundColor3 = Window.Theme.ElementBorder
            SliderBackground.BorderSizePixel = 0
            SliderBackground.Parent = SliderFrame
            
            local SliderBackgroundCorner = Instance.new("UICorner")
            SliderBackgroundCorner.CornerRadius = UDim.new(1, 0)
            SliderBackgroundCorner.Parent = SliderBackground
            
            local SliderFill = Instance.new("Frame")
            SliderFill.Name = "Fill"
            SliderFill.Size = UDim2.new(0, 0, 1, 0)
            SliderFill.BackgroundColor3 = Window.Theme.Accent
            SliderFill.BorderSizePixel = 0
            SliderFill.Parent = SliderBackground
            
            local SliderFillCorner = Instance.new("UICorner")
            SliderFillCorner.CornerRadius = UDim.new(1, 0)
            SliderFillCorner.Parent = SliderFill
            
            local SliderButton = Instance.new("TextButton")
            SliderButton.Name = "SliderButton"
            SliderButton.Size = UDim2.new(1, 0, 1, 0)
            SliderButton.BackgroundTransparency = 1
            SliderButton.Text = ""
            SliderButton.Parent = SliderBackground
            
            local dragging = false
            
            local function UpdateSlider(value)
                value = math.clamp(value, Slider.Min, Slider.Max)
                value = math.floor(value / Slider.Increment + 0.5) * Slider.Increment
                value = math.clamp(value, Slider.Min, Slider.Max)
                
                Slider.CurrentValue = value
                SliderValue.Text = tostring(value)
                
                local percent = (value - Slider.Min) / (Slider.Max - Slider.Min)
                Tween(SliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
                
                Window:RegisterFlag(Slider.Flag, value)
                pcall(Slider.Callback, value)
            end
            
            SliderButton.MouseButton1Down:Connect(function()
                dragging = true
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            SliderButton.MouseButton1Click:Connect(function()
                local mousePos = Mouse.X
                local sliderPos = SliderBackground.AbsolutePosition.X
                local sliderSize = SliderBackground.AbsoluteSize.X
                local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
                local value = Slider.Min + (Slider.Max - Slider.Min) * percent
                UpdateSlider(value)
            end)
            
            RunService.RenderStepped:Connect(function()
                if dragging then
                    local mousePos = Mouse.X
                    local sliderPos = SliderBackground.AbsolutePosition.X
                    local sliderSize = SliderBackground.AbsoluteSize.X
                    local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
                    local value = Slider.Min + (Slider.Max - Slider.Min) * percent
                    UpdateSlider(value)
                end
            end)
            
            Slider.Element = SliderFrame
            
            function Slider:Set(value)
                UpdateSlider(value)
            end
            
            -- Initialize
            UpdateSlider(Slider.CurrentValue)
            
            return Slider
        end
        
        -- Input
        function Tab:CreateInput(config)
            config = config or {}
            local Input = {
                Name = config.Name or "Input",
                PlaceholderText = config.PlaceholderText or "Enter text...",
                CurrentValue = config.CurrentValue or "",
                Flag = config.Flag,
                Callback = config.Callback or function() end
            }
            
            local InputFrame = Instance.new("Frame")
            InputFrame.Name = "Input"
            InputFrame.Size = UDim2.new(1, 0, 0, 65)
            InputFrame.BackgroundColor3 = Window.Theme.ElementBackground
            InputFrame.BorderSizePixel = 0
            InputFrame.Parent = TabContent
            
            local InputCorner = Instance.new("UICorner")
            InputCorner.CornerRadius = UDim.new(0, 8)
            InputCorner.Parent = InputFrame
            
            local InputLabel = Instance.new("TextLabel")
            InputLabel.Name = "Label"
            InputLabel.Size = UDim2.new(1, -20, 0, 20)
            InputLabel.Position = UDim2.new(0, 10, 0, 8)
            InputLabel.BackgroundTransparency = 1
            InputLabel.Text = Input.Name
            InputLabel.TextColor3 = Window.Theme.Text
            InputLabel.TextSize = 14
            InputLabel.Font = Enum.Font.Gotham
            InputLabel.TextXAlignment = Enum.TextXAlignment.Left
            InputLabel.Parent = InputFrame
            
            local InputBox = Instance.new("TextBox")
            InputBox.Name = "InputBox"
            InputBox.Size = UDim2.new(1, -20, 0, 30)
            InputBox.Position = UDim2.new(0, 10, 1, -38)
            InputBox.BackgroundColor3 = Window.Theme.TertiaryBackground
            InputBox.BorderSizePixel = 0
            InputBox.Text = Input.CurrentValue
            InputBox.PlaceholderText = Input.PlaceholderText
            InputBox.TextColor3 = Window.Theme.Text
            InputBox.PlaceholderColor3 = Window.Theme.SubText
            InputBox.TextSize = 13
            InputBox.Font = Enum.Font.Gotham
            InputBox.ClearTextOnFocus = false
            InputBox.Parent = InputFrame
            
            local InputBoxCorner = Instance.new("UICorner")
            InputBoxCorner.CornerRadius = UDim.new(0, 6)
            InputBoxCorner.Parent = InputBox
            
            local InputBoxPadding = Instance.new("UIPadding")
            InputBoxPadding.PaddingLeft = UDim.new(0, 8)
            InputBoxPadding.PaddingRight = UDim.new(0, 8)
            InputBoxPadding.Parent = InputBox
            
            InputBox.FocusLost:Connect(function()
                Window:RegisterFlag(Input.Flag, InputBox.Text)
                Input.CurrentValue = InputBox.Text
                pcall(Input.Callback, InputBox.Text)
            end)
            
            Input.Element = InputFrame
            
            function Input:Set(text)
                InputBox.Text = text
                self.CurrentValue = text
            end
            
            return Input
        end
        
        -- Dropdown
        function Tab:CreateDropdown(config)
            config = config or {}
            local Dropdown = {
                Name = config.Name or "Dropdown",
                Options = config.Options or {},
                CurrentOption = config.CurrentOption or config.Options[1] or "",
                Flag = config.Flag,
                Callback = config.Callback or function() end,
                Expanded = false
            }
            
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Name = "Dropdown"
            DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
            DropdownFrame.BackgroundColor3 = Window.Theme.ElementBackground
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.ClipsDescendants = true
            DropdownFrame.Parent = TabContent
            
            local DropdownCorner = Instance.new("UICorner")
            DropdownCorner.CornerRadius = UDim.new(0, 8)
            DropdownCorner.Parent = DropdownFrame
            
            local DropdownLabel = Instance.new("TextLabel")
            DropdownLabel.Name = "Label"
            DropdownLabel.Size = UDim2.new(1, -20, 0, 40)
            DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
            DropdownLabel.BackgroundTransparency = 1
            DropdownLabel.Text = Dropdown.Name
            DropdownLabel.TextColor3 = Window.Theme.Text
            DropdownLabel.TextSize = 14
            DropdownLabel.Font = Enum.Font.Gotham
            DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            DropdownLabel.Parent = DropdownFrame
            
            local DropdownValue = Instance.new("TextLabel")
            DropdownValue.Name = "Value"
            DropdownValue.Size = UDim2.new(0, 150, 0, 40)
            DropdownValue.Position = UDim2.new(1, -170, 0, 0)
            DropdownValue.BackgroundTransparency = 1
            DropdownValue.Text = Dropdown.CurrentOption
            DropdownValue.TextColor3 = Window.Theme.Accent
            DropdownValue.TextSize = 13
            DropdownValue.Font = Enum.Font.Gotham
            DropdownValue.TextXAlignment = Enum.TextXAlignment.Right
            DropdownValue.TextTruncate = Enum.TextTruncate.AtEnd
            DropdownValue.Parent = DropdownFrame
            
            local DropdownArrow = Instance.new("TextLabel")
            DropdownArrow.Name = "Arrow"
            DropdownArrow.Size = UDim2.new(0, 20, 0, 40)
            DropdownArrow.Position = UDim2.new(1, -25, 0, 0)
            DropdownArrow.BackgroundTransparency = 1
            DropdownArrow.Text = "▼"
            DropdownArrow.TextColor3 = Window.Theme.Text
            DropdownArrow.TextSize = 10
            DropdownArrow.Font = Enum.Font.Gotham
            DropdownArrow.Parent = DropdownFrame
            
            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Name = "DropdownButton"
            DropdownButton.Size = UDim2.new(1, 0, 0, 40)
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.Text = ""
            DropdownButton.ZIndex = 2
            DropdownButton.Parent = DropdownFrame
            
            local OptionsContainer = Instance.new("Frame")
            OptionsContainer.Name = "Options"
            OptionsContainer.Size = UDim2.new(1, 0, 0, 0)
            OptionsContainer.Position = UDim2.new(0, 0, 0, 45)
            OptionsContainer.BackgroundTransparency = 1
            OptionsContainer.Parent = DropdownFrame
            
            local OptionsList = Instance.new("UIListLayout")
            OptionsList.Padding = UDim.new(0, 3)
            OptionsList.SortOrder = Enum.SortOrder.LayoutOrder
            OptionsList.Parent = OptionsContainer
            
            local function UpdateDropdown()
                -- Clear existing options
                for _, child in pairs(OptionsContainer:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                
                -- Create option buttons
                for i, option in ipairs(Dropdown.Options) do
                    local OptionButton = Instance.new("TextButton")
                    OptionButton.Name = "Option_" .. i
                    OptionButton.Size = UDim2.new(1, 0, 0, 30)
                    OptionButton.BackgroundColor3 = Window.Theme.TertiaryBackground
                    OptionButton.BorderSizePixel = 0
                    OptionButton.Text = "  " .. option
                    OptionButton.TextColor3 = Window.Theme.Text
                    OptionButton.TextSize = 13
                    OptionButton.Font = Enum.Font.Gotham
                    OptionButton.TextXAlignment = Enum.TextXAlignment.Left
                    OptionButton.Parent = OptionsContainer
                    
                    local OptionCorner = Instance.new("UICorner")
                    OptionCorner.CornerRadius = UDim.new(0, 6)
                    OptionCorner.Parent = OptionButton
                    
                    OptionButton.MouseButton1Click:Connect(function()
                        Dropdown.CurrentOption = option
                        Window:RegisterFlag(Dropdown.Flag, option)
                        DropdownValue.Text = option
                        pcall(Dropdown.Callback, option)
                        DropdownButton.MouseButton1Click:Fire()
                    end)
                    
                    OptionButton.MouseEnter:Connect(function()
                        Tween(OptionButton, {BackgroundColor3 = Window.Theme.Accent})
                    end)
                    
                    OptionButton.MouseLeave:Connect(function()
                        Tween(OptionButton, {BackgroundColor3 = Window.Theme.TertiaryBackground})
                    end)
                end
            end
            
            DropdownButton.MouseButton1Click:Connect(function()
                Dropdown.Expanded = not Dropdown.Expanded
                
                if Dropdown.Expanded then
                    UpdateDropdown()
                    local optionCount = #Dropdown.Options
                    local height = 45 + (optionCount * 33)
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, height)}, 0.2)
                    Tween(DropdownArrow, {Rotation = 180}, 0.2)
                else
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.2)
                    Tween(DropdownArrow, {Rotation = 0}, 0.2)
                end
            end)
            
            Dropdown.Element = DropdownFrame
            
            function Dropdown:Set(option)
                if table.find(self.Options, option) then
                    self.CurrentOption = option
                    DropdownValue.Text = option
                    pcall(self.Callback, option)
                end
            end
            
            function Dropdown:Refresh(options)
                self.Options = options
                if not table.find(options, self.CurrentOption) and #options > 0 then
                    self:Set(options[1])
                end
            end
            
            return Dropdown
        end
        
        -- Label
        function Tab:CreateLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Name = "Label"
            Label.Size = UDim2.new(1, 0, 0, 25)
            Label.BackgroundTransparency = 1
            Label.Text = text or "Label"
            Label.TextColor3 = Window.Theme.SubText
            Label.TextSize = 13
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = TabContent
            
            local LabelPadding = Instance.new("UIPadding")
            LabelPadding.PaddingLeft = UDim.new(0, 10)
            LabelPadding.Parent = Label
            
            local LabelObj = {Element = Label}
            
            function LabelObj:Set(text)
                Label.Text = text
            end
            
            return LabelObj
        end
        
        -- Paragraph
        function Tab:CreateParagraph(config)
            config = config or {}
            local Paragraph = {
                Title = config.Title or "Paragraph",
                Content = config.Content or ""
            }
            
            local ParagraphFrame = Instance.new("Frame")
            ParagraphFrame.Name = "Paragraph"
            ParagraphFrame.Size = UDim2.new(1, 0, 0, 80)
            ParagraphFrame.BackgroundColor3 = Window.Theme.ElementBackground
            ParagraphFrame.BorderSizePixel = 0
            ParagraphFrame.Parent = TabContent
            
            local ParagraphCorner = Instance.new("UICorner")
            ParagraphCorner.CornerRadius = UDim.new(0, 8)
            ParagraphCorner.Parent = ParagraphFrame
            
            local ParagraphTitle = Instance.new("TextLabel")
            ParagraphTitle.Name = "Title"
            ParagraphTitle.Size = UDim2.new(1, -20, 0, 20)
            ParagraphTitle.Position = UDim2.new(0, 10, 0, 8)
            ParagraphTitle.BackgroundTransparency = 1
            ParagraphTitle.Text = Paragraph.Title
            ParagraphTitle.TextColor3 = Window.Theme.Text
            ParagraphTitle.TextSize = 14
            ParagraphTitle.Font = Enum.Font.GothamBold
            ParagraphTitle.TextXAlignment = Enum.TextXAlignment.Left
            ParagraphTitle.Parent = ParagraphFrame
            
            local ParagraphContent = Instance.new("TextLabel")
            ParagraphContent.Name = "Content"
            ParagraphContent.Size = UDim2.new(1, -20, 1, -36)
            ParagraphContent.Position = UDim2.new(0, 10, 0, 28)
            ParagraphContent.BackgroundTransparency = 1
            ParagraphContent.Text = Paragraph.Content
            ParagraphContent.TextColor3 = Window.Theme.SubText
            ParagraphContent.TextSize = 12
            ParagraphContent.Font = Enum.Font.Gotham
            ParagraphContent.TextXAlignment = Enum.TextXAlignment.Left
            ParagraphContent.TextYAlignment = Enum.TextYAlignment.Top
            ParagraphContent.TextWrapped = true
            ParagraphContent.Parent = ParagraphFrame
            
            Paragraph.Element = ParagraphFrame
            
            function Paragraph:Set(title, content)
                ParagraphTitle.Text = title or self.Title
                ParagraphContent.Text = content or self.Content
                self.Title = title or self.Title
                self.Content = content or self.Content
            end
            
            return Paragraph
        end
        
        -- Keybind
        function Tab:CreateKeybind(config)
            config = config or {}
            local Keybind = {
                Name = config.Name or "Keybind",
                CurrentKeybind = config.CurrentKeybind or "NONE",
                Flag = config.Flag,
                Callback = config.Callback or function() end,
                Listening = false
            }
            
            local KeybindFrame = Instance.new("Frame")
            KeybindFrame.Name = "Keybind"
            KeybindFrame.Size = UDim2.new(1, 0, 0, 40)
            KeybindFrame.BackgroundColor3 = Window.Theme.ElementBackground
            KeybindFrame.BorderSizePixel = 0
            KeybindFrame.Parent = TabContent
            
            local KeybindCorner = Instance.new("UICorner")
            KeybindCorner.CornerRadius = UDim.new(0, 8)
            KeybindCorner.Parent = KeybindFrame
            
            local KeybindLabel = Instance.new("TextLabel")
            KeybindLabel.Name = "Label"
            KeybindLabel.Size = UDim2.new(1, -100, 1, 0)
            KeybindLabel.Position = UDim2.new(0, 10, 0, 0)
            KeybindLabel.BackgroundTransparency = 1
            KeybindLabel.Text = Keybind.Name
            KeybindLabel.TextColor3 = Window.Theme.Text
            KeybindLabel.TextSize = 14
            KeybindLabel.Font = Enum.Font.Gotham
            KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
            KeybindLabel.Parent = KeybindFrame
            
            local KeybindButton = Instance.new("TextButton")
            KeybindButton.Name = "KeybindButton"
            KeybindButton.Size = UDim2.new(0, 80, 0, 28)
            KeybindButton.Position = UDim2.new(1, -90, 0.5, -14)
            KeybindButton.BackgroundColor3 = Window.Theme.TertiaryBackground
            KeybindButton.BorderSizePixel = 0
            KeybindButton.Text = Keybind.CurrentKeybind
            KeybindButton.TextColor3 = Window.Theme.Accent
            KeybindButton.TextSize = 12
            KeybindButton.Font = Enum.Font.GothamBold
            KeybindButton.Parent = KeybindFrame
            
            local KeybindButtonCorner = Instance.new("UICorner")
            KeybindButtonCorner.CornerRadius = UDim.new(0, 6)
            KeybindButtonCorner.Parent = KeybindButton
            
            KeybindButton.MouseButton1Click:Connect(function()
                Keybind.Listening = true
                KeybindButton.Text = "..."
                Tween(KeybindButton, {BackgroundColor3 = Window.Theme.Accent})
            end)
            
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if Keybind.Listening then
                    local key = input.KeyCode.Name
                    if key ~= "Unknown" then
                        Keybind.CurrentKeybind = key
                        KeybindButton.Text = key
                        Keybind.Listening = false
                        Window:RegisterFlag(Keybind.Flag, key)
                        Tween(KeybindButton, {BackgroundColor3 = Window.Theme.TertiaryBackground})
                    end
                elseif input.KeyCode.Name == Keybind.CurrentKeybind and not gameProcessed then
                    pcall(Keybind.Callback)
                end
            end)
            
            Keybind.Element = KeybindFrame
            
            function Keybind:Set(key)
                self.CurrentKeybind = key
                KeybindButton.Text = key
            end
            
            return Keybind
        end
        
        -- ColorPicker (Simple version)
        function Tab:CreateColorPicker(config)
            config = config or {}
            local ColorPicker = {
                Name = config.Name or "ColorPicker",
                CurrentColor = config.CurrentColor or Color3.fromRGB(255, 255, 255),
                Flag = config.Flag,
                Callback = config.Callback or function() end
            }
            
            local ColorFrame = Instance.new("Frame")
            ColorFrame.Name = "ColorPicker"
            ColorFrame.Size = UDim2.new(1, 0, 0, 40)
            ColorFrame.BackgroundColor3 = Window.Theme.ElementBackground
            ColorFrame.BorderSizePixel = 0
            ColorFrame.Parent = TabContent
            
            local ColorCorner = Instance.new("UICorner")
            ColorCorner.CornerRadius = UDim.new(0, 8)
            ColorCorner.Parent = ColorFrame
            
            local ColorLabel = Instance.new("TextLabel")
            ColorLabel.Name = "Label"
            ColorLabel.Size = UDim2.new(1, -60, 1, 0)
            ColorLabel.Position = UDim2.new(0, 10, 0, 0)
            ColorLabel.BackgroundTransparency = 1
            ColorLabel.Text = ColorPicker.Name
            ColorLabel.TextColor3 = Window.Theme.Text
            ColorLabel.TextSize = 14
            ColorLabel.Font = Enum.Font.Gotham
            ColorLabel.TextXAlignment = Enum.TextXAlignment.Left
            ColorLabel.Parent = ColorFrame
            
            local ColorDisplay = Instance.new("Frame")
            ColorDisplay.Name = "ColorDisplay"
            ColorDisplay.Size = UDim2.new(0, 35, 0, 25)
            ColorDisplay.Position = UDim2.new(1, -45, 0.5, -12.5)
            ColorDisplay.BackgroundColor3 = ColorPicker.CurrentColor
            ColorDisplay.BorderSizePixel = 0
            ColorDisplay.Parent = ColorFrame
            
            local ColorDisplayCorner = Instance.new("UICorner")
            ColorDisplayCorner.CornerRadius = UDim.new(0, 6)
            ColorDisplayCorner.Parent = ColorDisplay
            
            local ColorDisplayStroke = Instance.new("UIStroke")
            ColorDisplayStroke.Color = Window.Theme.ElementBorder
            ColorDisplayStroke.Thickness = 2
            ColorDisplayStroke.Parent = ColorDisplay
            
            ColorPicker.Element = ColorFrame
            
            function ColorPicker:Set(color)
                self.CurrentColor = color
                Window:RegisterFlag(self.Flag, {R = color.R, G = color.G, B = color.B})
                ColorDisplay.BackgroundColor3 = color
                pcall(self.Callback, color)
            end
            
            -- Note: Full color picker with HSV wheel would be more complex
            -- This is a simplified version
            
            return ColorPicker
        end
        
        return Tab
    end
    
    return Window
end

-- Notification System
function InfernixLib:Notify(config)
        config = config or {}
        local title = config.Title or "Notification"
        local content = config.Content or ""
        local duration = config.Duration or 3
        local icon = config.Icon
        
        local NotificationGui = Instance.new("ScreenGui")
        NotificationGui.Name = "InfernixNotification"
        NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        NotificationGui.ResetOnSpawn = false
        
        if gethui then
            NotificationGui.Parent = gethui()
        else
            NotificationGui.Parent = CoreGui
        end
        
        local NotifFrame = Instance.new("Frame")
        NotifFrame.Size = UDim2.new(0, 300, 0, 0)
        NotifFrame.Position = UDim2.new(1, -320, 1, -20)
        NotifFrame.BackgroundColor3 = InfernixLib.Themes.Dark.SecondaryBackground
        NotifFrame.BorderSizePixel = 0
        NotifFrame.Parent = NotificationGui
        
        local NotifCorner = Instance.new("UICorner")
        NotifCorner.CornerRadius = UDim.new(0, 10)
        NotifCorner.Parent = NotifFrame
        
        local NotifStroke = Instance.new("UIStroke")
        NotifStroke.Color = InfernixLib.Themes.Dark.Accent
        NotifStroke.Thickness = 2
        NotifStroke.Parent = NotifFrame
        
        local NotifTitle = Instance.new("TextLabel")
        NotifTitle.Size = UDim2.new(1, -20, 0, 25)
        NotifTitle.Position = UDim2.new(0, 10, 0, 8)
        NotifTitle.BackgroundTransparency = 1
        NotifTitle.Text = title
        NotifTitle.TextColor3 = InfernixLib.Themes.Dark.Text
        NotifTitle.TextSize = 15
        NotifTitle.Font = Enum.Font.GothamBold
        NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
        NotifTitle.Parent = NotifFrame
        
        local NotifContent = Instance.new("TextLabel")
        NotifContent.Size = UDim2.new(1, -20, 0, 0)
        NotifContent.Position = UDim2.new(0, 10, 0, 33)
        NotifContent.BackgroundTransparency = 1
        NotifContent.Text = content
        NotifContent.TextColor3 = InfernixLib.Themes.Dark.SubText
        NotifContent.TextSize = 13
        NotifContent.Font = Enum.Font.Gotham
        NotifContent.TextXAlignment = Enum.TextXAlignment.Left
        NotifContent.TextYAlignment = Enum.TextYAlignment.Top
        NotifContent.TextWrapped = true
        NotifContent.Parent = NotifFrame
        
        -- Calculate height based on content
        local textBounds = game:GetService("TextService"):GetTextSize(
            content,
            13,
            Enum.Font.Gotham,
            Vector2.new(280, 1000)
        )
        
        local totalHeight = 45 + textBounds.Y + 10
        NotifContent.Size = UDim2.new(1, -20, 0, textBounds.Y)
        
        -- Animate in
        Tween(NotifFrame, {
            Size = UDim2.new(0, 300, 0, totalHeight),
            Position = UDim2.new(1, -320, 1, -totalHeight - 20)
        }, 0.3, Enum.EasingStyle.Back)
        
        -- Auto dismiss
        task.delay(duration, function()
            Tween(NotifFrame, {
                Position = UDim2.new(1, -320, 1, -20),
                Size = UDim2.new(0, 300, 0, 0)
            }, 0.3).Completed:Connect(function()
                NotificationGui:Destroy()
            end)
        end)
end

return InfernixLib
