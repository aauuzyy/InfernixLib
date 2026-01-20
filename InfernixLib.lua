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

-- Get the appropriate parent for GUIs
local function getGuiParent()
    if gethui then
        return gethui()
    elseif syn and syn.protect_gui then
        local gui = Instance.new("ScreenGui")
        syn.protect_gui(gui)
        gui.Parent = CoreGui
        return CoreGui
    else
        return CoreGui
    end
end

-- Get the loadstring function (different executors use different names)
local loadstring = loadstring or load or function() error("Executor does not support loadstring") end

-- Basic function fallbacks
local wait = wait or function(t) 
    local start = os.clock()
    repeat until os.clock() - start >= (t or 0)
end

local spawn = spawn or function(f)
    local success, err = pcall(f)
    if not success then warn("Spawn error:", err) end
end

-- Task library fallback for older executors
if not task then
    task = {
        wait = wait,
        spawn = spawn,
        delay = function(t, f) spawn(function() wait(t) f() end) end
    }
end

-- File system fallbacks
local isfile = isfile or function() return false end
local readfile = readfile or function() return "" end
local writefile = writefile or function() end

-- Other utility fallbacks
local tick = tick or os.clock or function() return 0 end
local pcall = pcall or function(f, ...) return true, f(...) end

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

-- Key System
local function CreateKeySystem(callback)
    -- Check if already authenticated
    if isfile and readfile and isfile("infernix_auth.dat") then
        local savedAuth = readfile("infernix_auth.dat")
        if savedAuth == "authenticated" then
            task.wait(0.1) -- Small delay to ensure everything is ready
            callback(true)
            return
        end
    end
    
    -- Fetch key from pastebin
    local validKey = ""
    pcall(function()
        validKey = game:HttpGet("https://pastebin.com/raw/guX6JHX2"):gsub("%s+", "")
    end)
    
    -- Create Key System GUI
    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "InfernixKeySystem"
    KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeyGui.ResetOnSpawn = false
    
    KeyGui.Parent = getGuiParent()
    
    -- Main Window
    local KeyWindow = Instance.new("Frame")
    KeyWindow.Size = UDim2.new(0, 400, 0, 200)
    KeyWindow.Position = UDim2.new(0.5, -200, 0.5, -100)
    KeyWindow.BackgroundTransparency = 1
    KeyWindow.BorderSizePixel = 0
    KeyWindow.ClipsDescendants = true
    KeyWindow.Parent = KeyGui
    
    -- Background with acrylic effect
    local KeyBackground = Instance.new("Frame")
    KeyBackground.Size = UDim2.new(1, 0, 1, 0)
    KeyBackground.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
    KeyBackground.BackgroundTransparency = 0.1
    KeyBackground.BorderSizePixel = 0
    KeyBackground.Parent = KeyWindow
    
    local KeyCorner = Instance.new("UICorner")
    KeyCorner.CornerRadius = UDim.new(0, 8)
    KeyCorner.Parent = KeyBackground
    
    local KeyBorder = Instance.new("UIStroke")
    KeyBorder.Color = Color3.fromRGB(60, 60, 60)
    KeyBorder.Thickness = 1
    KeyBorder.Transparency = 0.5
    KeyBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    KeyBorder.Parent = KeyBackground
    
    -- Apply acrylic blur
    local KeyAcrylicBlur = Acrylic.AcrylicBlur(0.001)
    KeyAcrylicBlur.Frame.Parent = KeyBackground
    KeyAcrylicBlur.AddParent(KeyWindow)
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 40, 0, 40)
    CloseBtn.Position = UDim2.new(1, -40, 0, 0)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.BackgroundColor3 = Color3.fromRGB(196, 43, 28)
    CloseBtn.Text = ""
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent = KeyWindow
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseBtn
    
    local CloseIcon = Instance.new("ImageLabel")
    CloseIcon.Size = UDim2.new(0, 12, 0, 12)
    CloseIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    CloseIcon.Image = Icons.Close
    CloseIcon.BackgroundTransparency = 1
    CloseIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    CloseIcon.Parent = CloseBtn
    
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, {BackgroundTransparency = 0}, 0.15)
    end)
    
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, {BackgroundTransparency = 1}, 0.15)
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        if KeyAcrylicBlur and KeyAcrylicBlur.Model then
            KeyAcrylicBlur.Model:Destroy()
        end
        KeyGui:Destroy()
        callback(false)
    end)
    
    -- Title
    local KeyTitle = Instance.new("TextLabel")
    KeyTitle.Size = UDim2.new(1, -60, 0, 35)
    KeyTitle.Position = UDim2.new(0, 20, 0, 15)
    KeyTitle.BackgroundTransparency = 1
    KeyTitle.Text = "Enter Key"
    KeyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyTitle.TextSize = 20
    KeyTitle.Font = Enum.Font.GothamBold
    KeyTitle.TextXAlignment = Enum.TextXAlignment.Center
    KeyTitle.Parent = KeyWindow
    
    -- Tip Text
    local TipText = Instance.new("TextLabel")
    TipText.Size = UDim2.new(1, -40, 0, 20)
    TipText.Position = UDim2.new(0, 20, 0, 50)
    TipText.BackgroundTransparency = 1
    TipText.Text = "Join our Discord for daily keys!"
    TipText.TextColor3 = Color3.fromRGB(180, 180, 180)
    TipText.TextSize = 11
    TipText.Font = Enum.Font.Gotham
    TipText.TextXAlignment = Enum.TextXAlignment.Center
    TipText.Parent = KeyWindow
    
    -- Key Input Container
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -60, 0, 40)
    InputContainer.Position = UDim2.new(0, 30, 0, 85)
    InputContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    InputContainer.BorderSizePixel = 0
    InputContainer.Parent = KeyWindow
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 4)
    InputCorner.Parent = InputContainer
    
    -- Key Input
    local KeyInput = Instance.new("TextBox")
    KeyInput.Size = UDim2.new(1, -20, 1, 0)
    KeyInput.Position = UDim2.new(0, 10, 0, 0)
    KeyInput.BackgroundTransparency = 1
    KeyInput.PlaceholderText = "Enter your key here..."
    KeyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    KeyInput.Text = ""
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.TextSize = 13
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.TextXAlignment = Enum.TextXAlignment.Left
    KeyInput.ClearTextOnFocus = false
    KeyInput.Parent = InputContainer
    
    -- Status Text
    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, -40, 0, 50)
    StatusText.Position = UDim2.new(0, 20, 0, 135)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = ""
    StatusText.TextColor3 = Color3.fromRGB(220, 80, 80)
    StatusText.TextSize = 12
    StatusText.Font = Enum.Font.GothamMedium
    StatusText.TextXAlignment = Enum.TextXAlignment.Center
    StatusText.Parent = KeyWindow
    
    -- Typing animation for status
    local function typeText(text, textLabel, duration)
        textLabel.Text = ""
        local delay = duration / #text
        for i = 1, #text do
            textLabel.Text = text:sub(1, i)
            task.wait(delay)
        end
    end
    
    -- Delete animation for status
    local function deleteText(textLabel, duration)
        local text = textLabel.Text
        local delay = duration / #text
        for i = #text, 0, -1 do
            textLabel.Text = text:sub(1, i)
            task.wait(delay)
        end
    end
    
    -- Validate key
    local function validateKey()
        local enteredKey = KeyInput.Text:gsub("%s+", "")
        
        if enteredKey == validKey and validKey ~= "" then
            -- Success
            KeyInput.TextEditable = false
            StatusText.TextColor3 = Color3.fromRGB(80, 220, 80)
            task.spawn(function()
                typeText("Authentication successful!", StatusText, 0.5)
            end)
            
            -- Show success notification
            InfernixLib:Notify({
                Title = "Authentication Complete",
                Content = "Welcome to Infernix Executor!",
                Duration = 3
            })
            
            -- Save authentication
            if writefile then
                writefile("infernix_auth.dat", "authenticated")
            end
            
            task.wait(1)
            
            -- Fade out key system
            Tween(KeyBackground, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Linear)
            Tween(KeyTitle, {TextTransparency = 1}, 0.3, Enum.EasingStyle.Linear)
            Tween(TipText, {TextTransparency = 1}, 0.3, Enum.EasingStyle.Linear)
            Tween(KeyInput, {TextTransparency = 1}, 0.3, Enum.EasingStyle.Linear)
            Tween(StatusText, {TextTransparency = 1}, 0.3, Enum.EasingStyle.Linear)
            Tween(KeyBorder, {Transparency = 1}, 0.3, Enum.EasingStyle.Linear)
            Tween(InputContainer, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Linear)
            Tween(CloseIcon, {ImageTransparency = 1}, 0.3, Enum.EasingStyle.Linear)
            
            task.wait(0.3)
            
            if KeyAcrylicBlur and KeyAcrylicBlur.Model then
                KeyAcrylicBlur.Model:Destroy()
            end
            KeyGui:Destroy()
            
            task.wait(0.1)
            callback(true)
        else
            -- Failed
            KeyInput.Text = ""
            StatusText.TextColor3 = Color3.fromRGB(220, 80, 80)
            
            -- Show failure notification
            InfernixLib:Notify({
                Title = "Authentication Failed",
                Content = "The key you entered is invalid. Please try again.",
                Duration = 3
            })
            
            task.spawn(function()
                typeText("Invalid key. Please try again.", StatusText, 0.5)
                task.wait(2)
                deleteText(StatusText, 0.3)
            end)
            
            KeyInput:CaptureFocus()
        end
    end
    
    -- Enter key to validate
    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed and KeyInput.Text ~= "" then
            validateKey()
        end
    end)
    
    -- Auto focus
    task.wait(0.5)
    KeyInput:CaptureFocus()
end

-- Create Executor Window
function InfernixLib:CreateExecutor(config)
    config = config or {}
    
    local Executor = {
        Name = config.Name or "Infernix Executor",
        Tabs = {},
        CurrentTab = nil,
        Visible = false,
        Maximized = false,
        Authenticated = false,
        UICreated = false
    }
    
    -- Define methods immediately so they're available
    Executor.Show = function(self)
        if not self.UICreated then
            -- UI not created yet, queue the show
            self._queuedShow = true
            return
        end
        self._Window.Visible = true
        self.Visible = true
        
        -- Show welcome notification
        task.spawn(function()
            task.wait(0.5)
            InfernixLib:Notify({
                Title = "Infernix Executor",
                Content = "Press LeftControl to toggle. Use the file icon to create new tabs.",
                Duration = 4
            })
        end)
    end
    
    Executor.Hide = function(self)
        if not self.UICreated then return end
        self._Window.Visible = false
        self.Visible = false
    end
    
    Executor.Toggle = function(self)
        if not self.UICreated then return end
        if self._Window.Visible then
            self:Hide()
        else
            self:Show()
        end
    end
    
    Executor.AddTab = function(self, name)
        if not self.UICreated then
            error("Cannot add tab before UI is created")
        end
        return self._addTabInternal(name)
    end
    
    Executor.CreateTab = function(self, name)
        return self:AddTab(name)
    end
    
    -- Wait for authentication
    CreateKeySystem(function(success)
        if not success then
            return
        end
        
        Executor.Authenticated = true
        
        -- Now create the actual UI after authentication
        createExecutorUI(Executor, config)
        Executor.UICreated = true
        
        -- If Show() was called before UI was ready, show it now
        if Executor._queuedShow then
            task.wait(0.1) -- Small delay to ensure UI is fully initialized
            Executor:Show()
        end
    end)
    
    return Executor
end

local function createExecutorUI(Executor, config)
    
    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InfernixExecutor"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    
    ScreenGui.Parent = getGuiParent()
    
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
    local function createTitleButton(icon, position, hoverColor, isCloseButton)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 46, 0, 40)
        button.Position = position
        button.BackgroundTransparency = 1
        button.BackgroundColor3 = hoverColor
        button.Text = ""
        button.AutoButtonColor = false
        button.ClipsDescendants = true
        button.Parent = TitleBar
        
        -- Add corner radius for close button
        if isCloseButton then
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = button
        end
        
        local iconLabel = Instance.new("ImageLabel")
        iconLabel.Size = UDim2.new(0, 12, 0, 12)
        iconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        iconLabel.Image = icon
        iconLabel.BackgroundTransparency = 1
        iconLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
        iconLabel.Parent = button
        
        button.MouseEnter:Connect(function()
            Tween(button, {BackgroundTransparency = 0}, 0.15)
            Tween(iconLabel, {ImageColor3 = Color3.fromRGB(255, 255, 255)}, 0.15)
        end)
        
        button.MouseLeave:Connect(function()
            Tween(button, {BackgroundTransparency = 1}, 0.15)
        end)
        
        return button, iconLabel
    end
    
    local CloseBtn, CloseBtnIcon = createTitleButton(Icons.Close, UDim2.new(1, -46, 0, 0), Color3.fromRGB(196, 43, 28), true)
    local MaximizeBtn, MaximizeBtnIcon = createTitleButton(Icons.Maximize, UDim2.new(1, -92, 0, 0), Color3.fromRGB(60, 60, 60), false)
    local MinimizeBtn, MinimizeBtnIcon = createTitleButton(Icons.Minimize, UDim2.new(1, -138, 0, 0), Color3.fromRGB(60, 60, 60), false)
    
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
    URLText.Text = "https://infernix.executor/script-editor"
    URLText.TextColor3 = Color3.fromRGB(180, 180, 180)
    URLText.TextSize = 11
    URLText.Font = Enum.Font.Gotham
    URLText.TextXAlignment = Enum.TextXAlignment.Left
    URLText.BackgroundTransparency = 1
    URLText.Parent = URLBar
    
    -- Tab Container (Browser-style tabs with scrolling)
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, -24, 0, 36)
    TabContainer.Position = UDim2.new(0, 12, 0, 88)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.ScrollBarThickness = 4
    TabContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    TabContainer.ScrollingDirection = Enum.ScrollingDirection.X
    TabContainer.CanvasSize = UDim2.new(0, 0, 1, 0)
    TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
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
    local tabCounter = 0
    local undoHistory = {}
    local redoHistory = {}
    local lastCodeState = ""
    
    -- Typing animation for URL
    local function typeURL(text)
        URLText.Text = ""
        for i = 1, #text do
            URLText.Text = text:sub(1, i)
            task.wait(0.02)
        end
    end
    
    -- Toolbar buttons
    createToolbarButton(Icons.NavigatePrevious, "Undo", function()
        if #undoHistory > 0 and CodeBox then
            table.insert(redoHistory, CodeBox.Text)
            local previousState = table.remove(undoHistory)
            CodeBox.Text = previousState
            lastCodeState = previousState
        end
    end)
    
    createToolbarButton(Icons.NavigateNext, "Redo", function()
        if #redoHistory > 0 and CodeBox then
            table.insert(undoHistory, CodeBox.Text)
            local nextState = table.remove(redoHistory)
            CodeBox.Text = nextState
            lastCodeState = nextState
        end
    end)
    
    createToolbarButton(Icons.Copy, "Copy", function()
        if CodeBox then
            setclipboard(CodeBox.Text)
        end
    end)
    
    createToolbarButton(Icons.Save, "New Tab", function()
        tabCounter = tabCounter + 1
        local newTab = Executor:CreateTab("Console " .. tabCounter)
        newTab:SetCode("-- New console tab\nprint('Hello from Console " .. tabCounter .. "!')")
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
    
    -- Track changes for undo/redo
    lastCodeState = CodeBox.Text
    CodeBox:GetPropertyChangedSignal("Text"):Connect(function()
        if CodeBox.Text ~= lastCodeState then
            table.insert(undoHistory, lastCodeState)
            if #undoHistory > 50 then -- Limit history
                table.remove(undoHistory, 1)
            end
            redoHistory = {} -- Clear redo when new changes are made
            lastCodeState = CodeBox.Text
        end
    end)
    
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
            InfernixLib:Notify({
                Title = "Execution Success",
                Content = "Script executed successfully!",
                Duration = 2
            })
        else
            warn("Execution Error:", err)
            InfernixLib:Notify({
                Title = "Execution Error",
                Content = "Failed to execute script. Check output for details.",
                Duration = 3
            })
        end
    end, true)
    
    -- Inject Button (Primary)
    createButton("Inject", function()
        local code = CodeBox.Text
        local func, err = loadstring(code)
        if func then
            task.spawn(func)
            print("Script injected successfully")
            InfernixLib:Notify({
                Title = "Injection Success",
                Content = "Script injected and running!",
                Duration = 2
            })
        else
            warn("Injection Error:", err)
            InfernixLib:Notify({
                Title = "Injection Error",
                Content = "Failed to inject script. Check output for details.",
                Duration = 3
            })
        end
    end, true)
    
    -- Window State
    local originalSize = Window.Size
    local originalPosition = Window.Position
    local isMaximized = false
    local isMinimized = false
    
    -- Button Callbacks
    CloseBtn.MouseButton1Click:Connect(function()
        -- Simple fade out
        Tween(Background, {BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Linear)
        for _, child in ipairs(Window:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ImageLabel") then
                if child:FindFirstChild("TextTransparency") or child.ClassName == "TextLabel" or child.ClassName == "TextButton" then
                    pcall(function() Tween(child, {TextTransparency = 1}, 0.2, Enum.EasingStyle.Linear) end)
                end
                if child:IsA("ImageLabel") then
                    pcall(function() Tween(child, {ImageTransparency = 1}, 0.2, Enum.EasingStyle.Linear) end)
                end
            end
        end
        task.wait(0.2)
        
        if AcrylicBlur and AcrylicBlur.Model then
            AcrylicBlur.Model:Destroy()
        end
        if DepthOfField then
            DepthOfField:Destroy()
        end
        ScreenGui:Destroy()
    end)
    
    MaximizeBtn.MouseButton1Click:Connect(function()
        if not isMaximized then
            -- Maximize
            originalSize = Window.Size
            originalPosition = Window.Position
            Tween(Window, {Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10)}, 0.25, Enum.EasingStyle.Quad)
            MaximizeBtnIcon.Image = Icons.RestoreDown
            isMaximized = true
        else
            -- Restore
            Tween(Window, {Size = originalSize, Position = originalPosition}, 0.25, Enum.EasingStyle.Quad)
            MaximizeBtnIcon.Image = Icons.Maximize
            isMaximized = false
        end
    end)
    
    MinimizeBtn.MouseButton1Click:Connect(function()
        -- Simple fade out
        Tween(Background, {BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Linear)
        task.wait(0.2)
        Window.Visible = false
        Executor.Visible = false
        isMinimized = true
    end)
    
    -- Toggle with LeftControl
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.LeftControl and not gameProcessed then
            if Window.Visible then
                -- Fade out
                Tween(Background, {BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Linear)
                task.wait(0.2)
                Window.Visible = false
                Executor.Visible = false
            else
                -- Fade in
                Window.Visible = true
                Executor.Visible = true
                if isMinimized then
                    Window.Position = originalPosition
                    isMinimized = false
                end
                Background.BackgroundTransparency = 1
                Tween(Background, {BackgroundTransparency = 0.1}, 0.2, Enum.EasingStyle.Linear)
            end
        end
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
    
    -- Store Window reference for methods
    Executor._Window = Window
    
    -- Internal tab creation function
    Executor._addTabInternal = function(name)
        local tab = Instance.new("TextButton")
        tab.Size = UDim2.new(0, 120, 0, 32)
        tab.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        tab.Text = name
        tab.TextColor3 = Color3.fromRGB(200, 200, 200)
        tab.TextSize = 11
        tab.Font = Enum.Font.Gotham
        tab.ClipsDescendants = true
        tab.Parent = TabContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = tab
        
        -- Close button for tab
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 20, 0, 20)
        closeBtn.Position = UDim2.new(1, -24, 0.5, -10)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Text = ""
        closeBtn.ZIndex = 2
        closeBtn.Visible = false
        closeBtn.Parent = tab
        
        local closeIcon = Instance.new("ImageLabel")
        closeIcon.Size = UDim2.new(0, 10, 0, 10)
        closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
        closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        closeIcon.Image = Icons.Close
        closeIcon.BackgroundTransparency = 1
        closeIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
        closeIcon.Parent = closeBtn
        
        closeBtn.MouseEnter:Connect(function()
            closeIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
        end)
        
        closeBtn.MouseLeave:Connect(function()
            closeIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
        end)
        
        closeBtn.MouseButton1Click:Connect(function()
            -- Don't close if it's the last tab
            if #Executor.Tabs <= 1 then
                InfernixLib:Notify({
                    Title = "Cannot Close Tab",
                    Content = "You must have at least one tab open.",
                    Duration = 2
                })
                return
            end
            
            -- Find and remove this tab
            for i, t in ipairs(Executor.Tabs) do
                if t == tabObject then
                    table.remove(Executor.Tabs, i)
                    break
                end
            end
            
            -- If this was the current tab, switch to another
            if Executor.CurrentTab == tabObject then
                Executor.CurrentTab = Executor.Tabs[1]
                if Executor.CurrentTab then
                    CodeBox.Text = Executor.CurrentTab.Code
                    task.spawn(function()
                        typeURL("https://infernix.executor/" .. Executor.CurrentTab.Name:lower():gsub(" ", "-"))
                    end)
                    
                    -- Highlight new active tab
                    for _, t in ipairs(Executor.Tabs) do
                        t.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                    end
                    Executor.CurrentTab.Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
            end
            
            tab:Destroy()
        end)
        
        -- Show/hide close button on hover
        tab.MouseEnter:Connect(function()
            closeBtn.Visible = true
        end)
        
        tab.MouseLeave:Connect(function()
            closeBtn.Visible = false
        end)
        
        local tabObject = {
            Name = name,
            Button = tab,
            Code = "-- " .. name .. "\nprint('Hello World')"
        }
        
        -- Single click to switch tabs
        tab.MouseButton1Click:Connect(function()
            -- Save current tab's code
            if Executor.CurrentTab then
                Executor.CurrentTab.Code = CodeBox.Text
            end
            
            -- Switch to new tab
            Executor.CurrentTab = tabObject
            CodeBox.Text = tabObject.Code
            
            -- Typing animation for URL
            task.spawn(function()
                typeURL("https://infernix.executor/" .. name:lower():gsub(" ", "-"))
            end)
            
            -- Highlight active tab
            for _, t in ipairs(Executor.Tabs) do
                t.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            end
            tab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end)
        
        -- Double click to rename
        local lastClick = 0
        tab.MouseButton1Click:Connect(function()
            local now = tick()
            if now - lastClick < 0.3 then
                -- Double click detected
                local oldName = tabObject.Name
                tab.Text = ""
                
                local textBox = Instance.new("TextBox")
                textBox.Size = UDim2.new(1, -10, 1, 0)
                textBox.Position = UDim2.new(0, 5, 0, 0)
                textBox.BackgroundTransparency = 1
                textBox.Text = oldName
                textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                textBox.TextSize = 11
                textBox.Font = Enum.Font.Gotham
                textBox.ClearTextOnFocus = false
                textBox.Parent = tab
                textBox:CaptureFocus()
                
                local function finishRename()
                    local newName = textBox.Text
                    if newName ~= "" then
                        tabObject.Name = newName
                        tab.Text = newName
                        task.spawn(function()
                            typeURL("https://infernix.executor/" .. newName:lower():gsub(" ", "-"))
                        end)
                    else
                        tab.Text = oldName
                    end
                    textBox:Destroy()
                end
                
                textBox.FocusLost:Connect(finishRename)
            end
            lastClick = now
        end)
        
        tabObject.SetCode = function(self, code)
            self.Code = code
            if Executor.CurrentTab == self then
                CodeBox.Text = code
            end
        end
        
        table.insert(self.Tabs, tabObject)
        
        -- Auto-select first tab
        if #self.Tabs == 1 then
            Executor.CurrentTab = tabObject
            CodeBox.Text = tabObject.Code
            tab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            task.spawn(function()
                typeURL("https://infernix.executor/" .. name:lower():gsub(" ", "-"))
            end)
        end
        
        return tabObject
    end
    
    -- Add default tab
    Executor._addTabInternal("Console")
    
    -- Initially hidden
    Window.Visible = false
    Executor.Visible = false
end

-- Windows 11 Style Notification System
local activeNotifications = {}

local function updateNotificationPositions()
    local yOffset = -120
    for i = #activeNotifications, 1, -1 do
        local notif = activeNotifications[i]
        if notif and notif.Parent then
            Tween(notif, {Position = UDim2.new(1, -380, 1, yOffset)}, 0.2, Enum.EasingStyle.Quad)
            yOffset = yOffset - 110 -- Stack with 10px gap
        end
    end
end

function InfernixLib:Notify(config)
    config = config or {}
    local title = config.Title or "Notification"
    local content = config.Content or ""
    local duration = config.Duration or 3
    
    -- Create notification container
    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "InfernixNotification"
    NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotifGui.ResetOnSpawn = false
    
    NotifGui.Parent = getGuiParent()
    
    -- Notification Box
    local NotifBox = Instance.new("Frame")
    NotifBox.Size = UDim2.new(0, 360, 0, 100)
    NotifBox.Position = UDim2.new(1, 20, 1, -120) -- Start off-screen bottom right
    NotifBox.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
    NotifBox.BorderSizePixel = 0
    NotifBox.Parent = NotifGui
    
    -- Border stroke
    local NotifStroke = Instance.new("UIStroke")
    NotifStroke.Color = Color3.fromRGB(60, 60, 60)
    NotifStroke.Thickness = 1
    NotifStroke.Transparency = 0.5
    NotifStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    NotifStroke.Parent = NotifBox
    
    -- Accent bar (Windows 11 style)
    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(0, 4, 1, 0)
    AccentBar.Position = UDim2.new(0, 0, 0, 0)
    AccentBar.BackgroundColor3 = Color3.fromRGB(0, 120, 212)
    AccentBar.BorderSizePixel = 0
    AccentBar.Parent = NotifBox
    
    -- Icon
    local NotifIcon = Instance.new("ImageLabel")
    NotifIcon.Size = UDim2.new(0, 32, 0, 32)
    NotifIcon.Position = UDim2.new(0, 16, 0, 16)
    NotifIcon.BackgroundTransparency = 1
    NotifIcon.Image = Icons.Icon
    NotifIcon.ImageColor3 = Color3.fromRGB(0, 120, 212)
    NotifIcon.Parent = NotifBox
    
    -- Title (Bold)
    local NotifTitle = Instance.new("TextLabel")
    NotifTitle.Size = UDim2.new(1, -64, 0, 24)
    NotifTitle.Position = UDim2.new(0, 56, 0, 16)
    NotifTitle.BackgroundTransparency = 1
    NotifTitle.Text = title
    NotifTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    NotifTitle.TextSize = 14
    NotifTitle.Font = Enum.Font.GothamBold
    NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
    NotifTitle.TextYAlignment = Enum.TextYAlignment.Top
    NotifTitle.Parent = NotifBox
    
    -- Content
    local NotifContent = Instance.new("TextLabel")
    NotifContent.Size = UDim2.new(1, -64, 0, 48)
    NotifContent.Position = UDim2.new(0, 56, 0, 40)
    NotifContent.BackgroundTransparency = 1
    NotifContent.Text = content
    NotifContent.TextColor3 = Color3.fromRGB(180, 180, 180)
    NotifContent.TextSize = 12
    NotifContent.Font = Enum.Font.Gotham
    NotifContent.TextXAlignment = Enum.TextXAlignment.Left
    NotifContent.TextYAlignment = Enum.TextYAlignment.Top
    NotifContent.TextWrapped = true
    NotifContent.Parent = NotifBox
    
    -- Add to active notifications
    table.insert(activeNotifications, NotifBox)
    
    -- Update all positions
    updateNotificationPositions()
    
    -- Swoop in animation from bottom right
    Tween(NotifBox, {Position = NotifBox.Position}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    -- Wait for duration then fade out
    task.spawn(function()
        task.wait(duration)
        
        -- Fade out animation
        Tween(NotifBox, {Position = UDim2.new(1, -380, 1, NotifBox.Position.Y.Offset + 20)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        Tween(NotifBox, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Linear)
        Tween(NotifTitle, {TextTransparency = 1}, 0.3, Enum.EasingStyle.Linear)
        Tween(NotifContent, {TextTransparency = 1}, 0.3, Enum.EasingStyle.Linear)
        Tween(NotifIcon, {ImageTransparency = 1}, 0.3, Enum.EasingStyle.Linear)
        Tween(NotifStroke, {Transparency = 1}, 0.3, Enum.EasingStyle.Linear)
        Tween(AccentBar, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Linear)
        
        task.wait(0.3)
        
        -- Remove from active notifications
        for i, notif in ipairs(activeNotifications) do
            if notif == NotifBox then
                table.remove(activeNotifications, i)
                break
            end
        end
        
        -- Update remaining notification positions
        updateNotificationPositions()
        
        NotifGui:Destroy()
    end)
end

return InfernixLib
