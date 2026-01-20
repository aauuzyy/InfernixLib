--[[
    InfernixLib - Windows 11 Style Executor
    Modern executor with acrylic blur and browser-style tabs
]]

local InfernixLib = {}
InfernixLib.__index = InfernixLib
InfernixLib._version = "2.0.0"

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Variables
local LocalPlayer = Players.LocalPlayer

-- Windows 11 Icon Assets (Public Roblox Assets)
local Icons = {
    Close = "rbxassetid://9886659671",
    CloseButton = "rbxassetid://9887215356",
    Maximize = "rbxassetid://9886659406",
    RestoreDown = "rbxassetid://9886659001",
    Minimize = "rbxassetid://9886659276",
    Icon = "rbxassetid://9886659555",
    DropShadow = "rbxassetid://9886919127",
    -- ActionBar/Toolbar icons from RemoteSpy
    NavigatePrevious = "rbxassetid://9887696242",
    NavigateNext = "rbxassetid://9887978919",
    Copy = "rbxassetid://9887696628",
    Save = "rbxassetid://9932819855",
    Delete = "rbxassetid://9887696922",
    Traceback = "rbxassetid://9887697255",
    CopyPath = "rbxassetid://9887697099"
}

-- Utility Functions
local function Tween(instance, properties, duration, style, direction)
    duration = duration or 0.3
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    
    local tween = TweenService:Create(instance, TweenInfo.new(duration, style, direction), properties)
    tween:Play()
    return tween
end

-- Acrylic Blur System (Windows 11 style)
local Acrylic = {}

-- Utils
local function map(value, inMin, inMax, outMin, outMax)
	return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

local function viewportPointToWorld(location, distance)
	local unitRay = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
	return unitRay.Origin + unitRay.Direction * distance
end

local function getOffset()
	local viewportSizeY = workspace.CurrentCamera.ViewportSize.Y
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
DepthOfField.NearIntensity = 1.5
DepthOfField.Parent = game:GetService("Lighting")

local BlurFolder = Instance.new("Folder")
BlurFolder.Name = "InfernixAcrylicBlur"
BlurFolder.Parent = workspace.CurrentCamera

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
		local camera = workspace.CurrentCamera.CFrame
		local topLeft = positions.topLeft
		local topRight = positions.topRight
		local bottomRight = positions.bottomRight

		local topLeft3D = viewportPointToWorld(topLeft, distance)
		local topRight3D = viewportPointToWorld(topRight, distance)
		local bottomRight3D = viewportPointToWorld(bottomRight, distance)

		local width = (topRight3D - topLeft3D).Magnitude
		local height = (topRight3D - bottomRight3D).Magnitude

		model.CFrame = CFrame.fromMatrix(
			(topLeft3D + bottomRight3D) / 2,
			camera.XVector,
			camera.YVector,
			camera.ZVector
		)
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
		local camera = workspace.CurrentCamera
		if not camera then return end

		table.insert(cleanups, camera:GetPropertyChangedSignal("CFrame"):Connect(render))
		table.insert(cleanups, camera:GetPropertyChangedSignal("ViewportSize"):Connect(render))
		table.insert(cleanups, camera:GetPropertyChangedSignal("FieldOfView"):Connect(render))
		task.spawn(render)
	end

	model.Destroying:Connect(function()
		for _, item in cleanups do
			pcall(function() item:Disconnect() end)
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

-- Create Executor Window
function InfernixLib:CreateExecutor(config)
    config = config or {}
    
    local Executor = {
        Name = config.Name or "Infernix Executor",
        Tabs = {},
        CurrentTab = nil,
        Visible = false,
        Maximized = false
    }
    
    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InfernixExecutor"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    
    if gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = CoreGui
    end
    
    -- Main Window
    local Window = Instance.new("Frame")
    Window.Name = "Window"
    Window.Size = UDim2.new(0, 600, 0, 400)
    Window.Position = UDim2.new(0.5, -300, 0.5, -200)
    Window.BackgroundTransparency = 1
    Window.BorderSizePixel = 0
    Window.ClipsDescendants = true
    Window.Parent = ScreenGui
    
    -- Acrylic Background
    local Background = Instance.new("Frame")
    Background.Name = "Background"
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
    Background.BackgroundTransparency = 0.1
    Background.BorderSizePixel = 0
    Background.Parent = Window
    
    local BackgroundCorner = Instance.new("UICorner")
    BackgroundCorner.CornerRadius = UDim.new(0, 8)
    BackgroundCorner.Parent = Background
    
    -- Apply acrylic blur
    local AcrylicBlur = Acrylic.AcrylicBlur(0.001)
    AcrylicBlur.Frame.Parent = Background
    AcrylicBlur.AddParent(Window)
    
    -- Border
    local Border = Instance.new("UIStroke")
    Border.Color = Color3.fromRGB(60, 60, 60)
    Border.Thickness = 1
    Border.Transparency = 0.5
    Border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Border.Parent = Background
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundTransparency = 1
    TitleBar.Parent = Window
    
    -- Window Icon
    local WindowIcon = Instance.new("ImageLabel")
    WindowIcon.Size = UDim2.new(0, 16, 0, 16)
    WindowIcon.Position = UDim2.new(0, 12, 0, 12)
    WindowIcon.Image = Icons.Icon
    WindowIcon.BackgroundTransparency = 1
    WindowIcon.Parent = TitleBar
    
    -- Window Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -150, 1, 0)
    Title.Position = UDim2.new(0, 36, 0, 0)
    Title.Text = Executor.Name
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 12
    Title.Font = Enum.Font.Gotham
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Parent = TitleBar
    
    -- Window Controls (Minimize, Maximize, Close)
    local function createTitleButton(icon, position, hoverColor)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 46, 0, 40)
        button.Position = position
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = TitleBar
        
        local iconLabel = Instance.new("ImageLabel")
        iconLabel.Size = UDim2.new(0, 12, 0, 12)
        iconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        iconLabel.Image = icon
        iconLabel.BackgroundTransparency = 1
        iconLabel.Parent = button
        
        button.MouseEnter:Connect(function()
            button.BackgroundTransparency = 0
            button.BackgroundColor3 = hoverColor
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundTransparency = 1
        end)
        
        return button
    end
    
    local CloseBtn = createTitleButton(Icons.Close, UDim2.new(1, -46, 0, 0), Color3.fromRGB(196, 43, 28))
    local MaximizeBtn = createTitleButton(Icons.Maximize, UDim2.new(1, -92, 0, 0), Color3.fromRGB(60, 60, 60))
    local MinimizeBtn = createTitleButton(Icons.Minimize, UDim2.new(1, -138, 0, 0), Color3.fromRGB(60, 60, 60))
    
    -- URL Bar (showing current tab location)
    local URLBar = Instance.new("Frame")
    URLBar.Size = UDim2.new(1, -24, 0, 32)
    URLBar.Position = UDim2.new(0, 12, 0, 48)
    URLBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    URLBar.BorderSizePixel = 0
    URLBar.Parent = Window
    
    local URLCorner = Instance.new("UICorner")
    URLCorner.CornerRadius = UDim.new(0, 4)
    URLCorner.Parent = URLBar
    
    local URLText = Instance.new("TextLabel")
    URLText.Size = UDim2.new(1, -20, 1, 0)
    URLText.Position = UDim2.new(0, 10, 0, 0)
    URLText.Text = "https://infernix.executor/script"
    URLText.TextColor3 = Color3.fromRGB(180, 180, 180)
    URLText.TextSize = 11
    URLText.Font = Enum.Font.Gotham
    URLText.TextXAlignment = Enum.TextXAlignment.Left
    URLText.BackgroundTransparency = 1
    URLText.Parent = URLBar
    
    -- Tab Container (Browser-style tabs)
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, -24, 0, 36)
    TabContainer.Position = UDim2.new(0, 12, 0, 88)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = Window
    
    local TabList = Instance.new("UIListLayout")
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.Padding = UDim.new(0, 4)
    TabList.Parent = TabContainer
    
    -- Editor Toolbar (Copy, New File, Delete, Undo, Redo)
    local Toolbar = Instance.new("Frame")
    Toolbar.Size = UDim2.new(1, -24, 0, 32)
    Toolbar.Position = UDim2.new(0, 12, 0, 132)
    Toolbar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Toolbar.BorderSizePixel = 0
    Toolbar.Parent = Window
    
    local ToolbarCorner = Instance.new("UICorner")
    ToolbarCorner.CornerRadius = UDim.new(0, 4)
    ToolbarCorner.Parent = Toolbar
    
    local ToolbarList = Instance.new("UIListLayout")
    ToolbarList.FillDirection = Enum.FillDirection.Horizontal
    ToolbarList.Padding = UDim.new(0, 4)
    ToolbarList.Parent = Toolbar
    
    local function createToolbarButton(icon, tooltip, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 32, 0, 32)
        button.BackgroundTransparency = 1
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        button.Text = ""
        button.Parent = Toolbar
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = button
        
        local iconLabel = Instance.new("ImageLabel")
        iconLabel.Size = UDim2.new(0, 16, 0, 16)
        iconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        iconLabel.Image = icon
        iconLabel.BackgroundTransparency = 1
        iconLabel.ImageColor3 = Color3.fromRGB(200, 200, 200)
        iconLabel.Parent = button
        
        button.MouseEnter:Connect(function()
            Tween(button, {BackgroundTransparency = 0}, 0.15)
            Tween(iconLabel, {ImageColor3 = Color3.fromRGB(255, 255, 255)}, 0.15)
        end)
        
        button.MouseLeave:Connect(function()
            Tween(button, {BackgroundTransparency = 1}, 0.15)
            Tween(iconLabel, {ImageColor3 = Color3.fromRGB(200, 200, 200)}, 0.15)
        end)
        
        if callback then
            button.MouseButton1Click:Connect(callback)
        end
        
        return button
    end
    
    local CodeBox -- Forward reference
    
    -- Toolbar buttons
    createToolbarButton(Icons.NavigatePrevious, "Back", function()
        print("Navigate back")
    end)
    
    createToolbarButton(Icons.NavigateNext, "Forward", function()
        print("Navigate forward")
    end)
    
    -- Separator
    local Separator1 = Instance.new("Frame")
    Separator1.Size = UDim2.new(0, 1, 1, -8)
    Separator1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Separator1.BorderSizePixel = 0
    Separator1.Parent = Toolbar
    
    createToolbarButton(Icons.Copy, "Copy", function()
        if CodeBox then
            setclipboard(CodeBox.Text)
        end
    end)
    
    createToolbarButton(Icons.Save, "Save", function()
        if CodeBox then
            print("Saved:", CodeBox.Text)
        end
    end)
    
    createToolbarButton(Icons.Delete, "Clear", function()
        if CodeBox then
            CodeBox.Text = ""
        end
    end)
    
    -- Code Editor/Console Area
    local EditorContainer = Instance.new("Frame")
    EditorContainer.Size = UDim2.new(1, -24, 1, -220)
    EditorContainer.Position = UDim2.new(0, 12, 0, 172)
    EditorContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    EditorContainer.BorderSizePixel = 0
    EditorContainer.Parent = Window
    
    local EditorCorner = Instance.new("UICorner")
    EditorCorner.CornerRadius = UDim.new(0, 4)
    EditorCorner.Parent = EditorContainer
    
    CodeBox = Instance.new("TextBox")
    CodeBox.Size = UDim2.new(1, -20, 1, -20)
    CodeBox.Position = UDim2.new(0, 10, 0, 10)
    CodeBox.BackgroundTransparency = 1
    CodeBox.Text = "-- Infernix Executor\nprint('Hello World')"
    CodeBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    CodeBox.TextSize = 14
    CodeBox.Font = Enum.Font.Code
    CodeBox.TextXAlignment = Enum.TextXAlignment.Left
    CodeBox.TextYAlignment = Enum.TextYAlignment.Top
    CodeBox.MultiLine = true
    CodeBox.ClearTextOnFocus = false
    CodeBox.Parent = EditorContainer
    
    -- Button Container
    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Size = UDim2.new(1, -24, 0, 36)
    ButtonContainer.Size = UDim2.new(1, -24, 0, 32)
    ButtonContainer.Position = UDim2.new(0, 12, 1, -44)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.Parent = Window
    
    local ButtonLayout = Instance.new("UIListLayout")
    ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
    ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ButtonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ButtonLayout.Padding = UDim.new(0, 8)
    ButtonLayout.Parent = ButtonContainer
    
    local function createButton(text, callback, isPrimary)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 90, 0, 32)
        button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        button.Text = text
        button.TextColor3 = Color3.fromRGB(200, 200, 200)
        button.TextSize = 11
        button.Font = Enum.Font.Gotham
        button.Parent = ButtonContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = button
        
        button.MouseButton1Click:Connect(callback)
        
        button.MouseEnter:Connect(function()
            Tween(button, {BackgroundColor3 = Color3.fromRGB(55, 55, 55)}, 0.15)
        end)
        
        button.MouseLeave:Connect(function()
            Tween(button, {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}, 0.15)
        end)
        
        return button
    end
    
    -- Execute Button (Primary)
    createButton("Execute", function()
        local code = CodeBox.Text
        local func, err = loadstring(code)
        if func then
            task.spawn(func)
        else
            warn("Execution Error:", err)
        end
    end, true)
    
    -- Inject Button (Primary)
    createButton("Inject", function()
        local code = CodeBox.Text
        local func, err = loadstring(code)
        if func then
            task.spawn(func)
            print("Script injected successfully")
        else
            warn("Injection Error:", err)
        end
    end, true)
    
    -- Clear Button (Secondary)
    createButton("Clear", function()
        CodeBox.Text = ""
    end, false)
    
    -- Button Callbacks
    CloseBtn.MouseButton1Click:Connect(function()
        if AcrylicBlur and AcrylicBlur.Model then
            AcrylicBlur.Model:Destroy()
        end
        if DepthOfField then
            DepthOfField:Destroy()
        end
        ScreenGui:Destroy()
    end)
    
    -- Make draggable
    local dragging, dragInput, dragStart, startPos
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    function Executor:AddTab(name)
        local tab = Instance.new("TextButton")
        tab.Size = UDim2.new(0, 120, 0, 32)
        tab.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        tab.Text = name
        tab.TextColor3 = Color3.fromRGB(200, 200, 200)
        tab.TextSize = 11
        tab.Font = Enum.Font.Gotham
        tab.Parent = TabContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = tab
        
        tab.MouseButton1Click:Connect(function()
            URLText.Text = "https://infernix.executor/" .. name:lower():gsub(" ", "-")
        end)
        
        table.insert(self.Tabs, tab)
        return tab
    end
    
    -- Add default tab
    Executor:AddTab("Script Editor")
    
    return Executor
end

return InfernixLib
