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

-- Themes
InfernixLib.Themes = {
    Dark = {
        Background = Color3.fromRGB(20, 20, 25),
        SecondaryBackground = Color3.fromRGB(25, 25, 30),
        TertiaryBackground = Color3.fromRGB(30, 30, 35),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(180, 180, 180),
        Accent = Color3.fromRGB(88, 101, 242),
        ElementBackground = Color3.fromRGB(35, 35, 40),
        ElementBorder = Color3.fromRGB(50, 50, 55),
        Success = Color3.fromRGB(67, 181, 129),
        Warning = Color3.fromRGB(250, 166, 26),
        Error = Color3.fromRGB(240, 71, 71)
    },
    Light = {
        Background = Color3.fromRGB(245, 245, 250),
        SecondaryBackground = Color3.fromRGB(235, 235, 240),
        TertiaryBackground = Color3.fromRGB(225, 225, 230),
        Text = Color3.fromRGB(20, 20, 20),
        SubText = Color3.fromRGB(100, 100, 100),
        Accent = Color3.fromRGB(88, 101, 242),
        ElementBackground = Color3.fromRGB(255, 255, 255),
        ElementBorder = Color3.fromRGB(200, 200, 205),
        Success = Color3.fromRGB(67, 181, 129),
        Warning = Color3.fromRGB(250, 166, 26),
        Error = Color3.fromRGB(240, 71, 71)
    },
    Ocean = {
        Background = Color3.fromRGB(15, 25, 35),
        SecondaryBackground = Color3.fromRGB(20, 30, 40),
        TertiaryBackground = Color3.fromRGB(25, 35, 45),
        Text = Color3.fromRGB(240, 248, 255),
        SubText = Color3.fromRGB(160, 180, 200),
        Accent = Color3.fromRGB(52, 152, 219),
        ElementBackground = Color3.fromRGB(30, 40, 50),
        ElementBorder = Color3.fromRGB(45, 55, 65),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60)
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
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 600, 0, 450)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
    MainFrame.BackgroundColor3 = Window.Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Window.Theme.ElementBorder
    MainStroke.Thickness = 1
    MainStroke.Transparency = 0.5
    MainStroke.Parent = MainFrame
    
    -- Drop shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.BackgroundTransparency = 1
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.7
    Shadow.ZIndex = 0
    Shadow.Parent = MainFrame
    
    Window.MainFrame = MainFrame
    
    -- Top Bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundColor3 = Window.Theme.SecondaryBackground
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    
    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 10)
    TopBarCorner.Parent = TopBar
    
    -- Fix corner at bottom
    local TopBarFix = Instance.new("Frame")
    TopBarFix.Size = UDim2.new(1, 0, 0, 10)
    TopBarFix.Position = UDim2.new(0, 0, 1, -10)
    TopBarFix.BackgroundColor3 = Window.Theme.SecondaryBackground
    TopBarFix.BorderSizePixel = 0
    TopBarFix.Parent = TopBar
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = Window.Name
    Title.TextColor3 = Window.Theme.Text
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 35, 0, 35)
    CloseButton.Position = UDim2.new(1, -40, 0.5, -17.5)
    CloseButton.BackgroundColor3 = Window.Theme.ElementBackground
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Window.Theme.Text
    CloseButton.TextSize = 24
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = TopBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        Window:Toggle()
    end)
    
    CloseButton.MouseEnter:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Window.Theme.Error})
    end)
    
    CloseButton.MouseLeave:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Window.Theme.ElementBackground})
    end)
    
    MakeDraggable(MainFrame, TopBar)
    
    -- Tab Container
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(0, 160, 1, -55)
    TabContainer.Position = UDim2.new(0, 10, 0, 50)
    TabContainer.BackgroundColor3 = Window.Theme.SecondaryBackground
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 8)
    TabCorner.Parent = TabContainer
    
    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 5)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Parent = TabContainer
    
    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingTop = UDim.new(0, 8)
    TabPadding.PaddingBottom = UDim.new(0, 8)
    TabPadding.PaddingLeft = UDim.new(0, 8)
    TabPadding.PaddingRight = UDim.new(0, 8)
    TabPadding.Parent = TabContainer
    
    Window.TabContainer = TabContainer
    
    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -185, 1, -55)
    ContentContainer.Position = UDim2.new(0, 175, 0, 50)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.BorderSizePixel = 0
    ContentContainer.Parent = MainFrame
    
    Window.ContentContainer = ContentContainer
    
    -- Toggle UI
    function Window:Toggle()
        self.Visible = not self.Visible
        if self.Visible then
            MainFrame.Visible = true
            Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 450)}, 0.3, Enum.EasingStyle.Back)
        else
            Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 0)}, 0.3, Enum.EasingStyle.Back).Completed:Connect(function()
                MainFrame.Visible = false
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
        
        -- Tab Button
        local TabButton = Instance.new("TextButton")
        TabButton.Name = name
        TabButton.Size = UDim2.new(1, 0, 0, 40)
        TabButton.BackgroundColor3 = Window.Theme.ElementBackground
        TabButton.BorderSizePixel = 0
        TabButton.Text = "  " .. name
        TabButton.TextColor3 = Window.Theme.SubText
        TabButton.TextSize = 14
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.Parent = TabContainer
        
        local TabButtonCorner = Instance.new("UICorner")
        TabButtonCorner.CornerRadius = UDim.new(0, 6)
        TabButtonCorner.Parent = TabButton
        
        Tab.Button = TabButton
        
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
        TabContent.Visible = false
        TabContent.Parent = ContentContainer
        
        local ContentList = Instance.new("UIListLayout")
        ContentList.Padding = UDim.new(0, 8)
        ContentList.SortOrder = Enum.SortOrder.LayoutOrder
        ContentList.Parent = TabContent
        
        ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 10)
        end)
        
        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.PaddingTop = UDim.new(0, 5)
        ContentPadding.PaddingBottom = UDim.new(0, 5)
        ContentPadding.PaddingRight = UDim.new(0, 5)
        ContentPadding.Parent = TabContent
        
        Tab.Content = TabContent
        
        -- Select tab
        local function SelectTab()
            for _, tab in pairs(Window.Tabs) do
                tab.Button.BackgroundColor3 = Window.Theme.ElementBackground
                tab.Button.TextColor3 = Window.Theme.SubText
                tab.Content.Visible = false
            end
            
            TabButton.BackgroundColor3 = Window.Theme.Accent
            TabButton.TextColor3 = Window.Theme.Text
            TabContent.Visible = true
            Window.CurrentTab = Tab
        end
        
        TabButton.MouseButton1Click:Connect(SelectTab)
        
        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, {BackgroundColor3 = Window.Theme.TertiaryBackground})
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, {BackgroundColor3 = Window.Theme.ElementBackground})
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
            ButtonFrame.BorderSizePixel = 0
            ButtonFrame.Parent = TabContent
            
            local ButtonCorner = Instance.new("UICorner")
            ButtonCorner.CornerRadius = UDim.new(0, 8)
            ButtonCorner.Parent = ButtonFrame
            
            local ButtonButton = Instance.new("TextButton")
            ButtonButton.Name = "ButtonButton"
            ButtonButton.Size = UDim2.new(1, 0, 1, 0)
            ButtonButton.BackgroundTransparency = 1
            ButtonButton.Text = ""
            ButtonButton.Parent = ButtonFrame
            
            local ButtonLabel = Instance.new("TextLabel")
            ButtonLabel.Name = "Label"
            ButtonLabel.Size = UDim2.new(1, -20, 1, 0)
            ButtonLabel.Position = UDim2.new(0, 10, 0, 0)
            ButtonLabel.BackgroundTransparency = 1
            ButtonLabel.Text = Button.Name
            ButtonLabel.TextColor3 = Window.Theme.Text
            ButtonLabel.TextSize = 14
            ButtonLabel.Font = Enum.Font.Gotham
            ButtonLabel.TextXAlignment = Enum.TextXAlignment.Left
            ButtonLabel.Parent = ButtonFrame
            
            ButtonButton.MouseButton1Click:Connect(function()
                local pos = ButtonButton.AbsolutePosition
                local size = ButtonButton.AbsoluteSize
                CreateRipple(ButtonFrame, Mouse.X - pos.X, Mouse.Y - pos.Y)
                
                pcall(Button.Callback)
            end)
            
            ButtonButton.MouseEnter:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Window.Theme.TertiaryBackground})
            end)
            
            ButtonButton.MouseLeave:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Window.Theme.ElementBackground})
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
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Parent = TabContent
            
            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 8)
            ToggleCorner.Parent = ToggleFrame
            
            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Name = "Label"
            ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = Toggle.Name
            ToggleLabel.TextColor3 = Window.Theme.Text
            ToggleLabel.TextSize = 14
            ToggleLabel.Font = Enum.Font.Gotham
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.Parent = ToggleFrame
            
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Name = "ToggleButton"
            ToggleButton.Size = UDim2.new(0, 45, 0, 24)
            ToggleButton.Position = UDim2.new(1, -55, 0.5, -12)
            ToggleButton.BackgroundColor3 = Window.Theme.ElementBorder
            ToggleButton.BorderSizePixel = 0
            ToggleButton.Text = ""
            ToggleButton.Parent = ToggleFrame
            
            local ToggleButtonCorner = Instance.new("UICorner")
            ToggleButtonCorner.CornerRadius = UDim.new(1, 0)
            ToggleButtonCorner.Parent = ToggleButton
            
            local ToggleIndicator = Instance.new("Frame")
            ToggleIndicator.Name = "Indicator"
            ToggleIndicator.Size = UDim2.new(0, 18, 0, 18)
            ToggleIndicator.Position = UDim2.new(0, 3, 0.5, -9)
            ToggleIndicator.BackgroundColor3 = Window.Theme.Text
            ToggleIndicator.BorderSizePixel = 0
            ToggleIndicator.Parent = ToggleButton
            
            local IndicatorCorner = Instance.new("UICorner")
            IndicatorCorner.CornerRadius = UDim.new(1, 0)
            IndicatorCorner.Parent = ToggleIndicator
            
            local function UpdateToggle(value)
                Toggle.CurrentValue = value
                
                if value then
                    Tween(ToggleButton, {BackgroundColor3 = Window.Theme.Accent})
                    Tween(ToggleIndicator, {Position = UDim2.new(1, -21, 0.5, -9)})
                else
                    Tween(ToggleButton, {BackgroundColor3 = Window.Theme.ElementBorder})
                    Tween(ToggleIndicator, {Position = UDim2.new(0, 3, 0.5, -9)})
                end
                
                Window:RegisterFlag(Toggle.Flag, value)
                pcall(Toggle.Callback, value)
            end
            
            ToggleButton.MouseButton1Click:Connect(function()
                UpdateToggle(not Toggle.CurrentValue)
            end)
            
            Toggle.Element = ToggleFrame
            
            function Toggle:Set(value)
                UpdateToggle(value)
            end
            
            -- Initialize
            if Toggle.CurrentValue then
                UpdateToggle(true)
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
    
    return Window
end

return InfernixLib
