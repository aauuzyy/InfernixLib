--[[
    InfernixLib Example Script
    Universal Script Hub - Works on most Roblox games
    Demonstrates all features of InfernixLib
]]

-- Load the library
local InfernixLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/aauuzyy/InfernixLib/main/InfernixLib.lua?v=" .. os.time()))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid") or Character:WaitForChild("Humanoid", 5)
local RootPart = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart", 5)

-- Script States
local States = {
    Speed = false,
    SpeedValue = 16,
    JumpPower = false,
    JumpValue = 50,
    InfiniteJump = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,
    ESP = false,
    Fullbright = false,
    FOV = 70
}

-- Create a window
local Window = InfernixLib:CreateWindow({
    Name = "InfernixLib Example",
    Icon = InfernixLib.Icons.Sparkles,
    LoadingTitle = "InfernixLib",
    LoadingSubtitle = "by InfernixDev",
    Theme = "Dark", -- Dark, Light, Midnight, Sunset
    ToggleKey = Enum.KeyCode.RightControl,
    ConfigSaving = {
        Enabled = true,
        FolderName = "InfernixLib",
        FileName = "ExampleConfig",
        AutoSave = true
    }
})

-- Send a notification
InfernixLib:Notify({
    Title = "InfernixLib Loaded!",
    Content = "Press Right Control to toggle the UI",
    Duration = 5
})

-- Create tabs with proper icons
local PlayerTab = Window:CreateTab("Player", InfernixLib.Icons.User)
local MovementTab = Window:CreateTab("Movement", InfernixLib.Icons.Gamepad)
local VisualsTab = Window:CreateTab("Visuals", InfernixLib.Icons.Eye)
local MiscTab = Window:CreateTab("Misc", InfernixLib.Icons.Settings)

-- Player Tab
PlayerTab:CreateSection("Character Stats")

PlayerTab:CreateParagraph({
    Title = "About InfernixLib",
    Content = "InfernixLib is a modern, feature-rich UI library for Roblox scripts with animated gradients, acrylic blur, and smooth animations!"
})

PlayerTab:CreateToggle({
    Name = "Speed Modifier",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(value)
        States.Speed = value
        if value then
            Humanoid.WalkSpeed = States.SpeedValue
        else
            Humanoid.WalkSpeed = 16
        end
    end
})

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Increment = 1,
    CurrentValue = 16,
    Flag = "SpeedValue",
    Callback = function(value)
        States.SpeedValue = value
        if States.Speed then
            Humanoid.WalkSpeed = value
        end
    end
})

PlayerTab:CreateToggle({
    Name = "Jump Power Modifier",
    CurrentValue = false,
    Flag = "JumpToggle",
    Callback = function(value)
        States.JumpPower = value
        if value then
            Humanoid.JumpPower = States.JumpValue
        else
            Humanoid.JumpPower = 50
        end
    end
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 300,
    Increment = 5,
    CurrentValue = 50,
    Flag = "JumpValue",
    Callback = function(value)
        States.JumpValue = value
        if States.JumpPower then
            Humanoid.JumpPower = value
        end
    end
})

PlayerTab:CreateSection("Character Actions")

PlayerTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        LocalPlayer.Character:BreakJoints()
        InfernixLib:Notify({
            Title = "Character Reset",
            Content = "Your character has been reset",
            Duration = 3
        })
    end
})

PlayerTab:CreateButton({
    Name = "Refresh Character",
    Callback = function()
        pcall(function()
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            Humanoid = Character:WaitForChild("Humanoid", 5)
            RootPart = Character:WaitForChild("HumanoidRootPart", 5)
            InfernixLib:Notify({
                Title = "Character Refreshed",
                Content = "Character references updated",
                Duration = 3
            })
        end)
    end
})

-- Movement Tab
MovementTab:CreateSection("Advanced Movement")

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(value)
        States.InfiniteJump = value
    end
})

UserInputService.JumpRequest:Connect(function()
    if States.InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(value)
        States.Noclip = value
    end
})

-- Noclip Loop
RunService.Stepped:Connect(function()
    if States.Noclip and Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(value)
        States.Fly = value
        
        if value then
            -- Start flying
            local BV = Instance.new("BodyVelocity")
            BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            BV.Velocity = Vector3.new(0, 0, 0)
            BV.Parent = RootPart
            BV.Name = "FlyVelocity"
            
            local BG = Instance.new("BodyGyro")
            BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            BG.CFrame = RootPart.CFrame
            BG.Parent = RootPart
            BG.Name = "FlyGyro"
            
            InfernixLib:Notify({
                Title = "Fly Enabled",
                Content = "Use WASD to fly, Space/Shift for up/down",
                Duration = 4
            })
        else
            -- Stop flying
            if RootPart:FindFirstChild("FlyVelocity") then
                RootPart.FlyVelocity:Destroy()
            end
            if RootPart:FindFirstChild("FlyGyro") then
                RootPart.FlyGyro:Destroy()
            end
        end
    end
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 200,
    Increment = 5,
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(value)
        States.FlySpeed = value
    end
})

-- Fly Control Loop
RunService.Heartbeat:Connect(function()
    if States.Fly and RootPart:FindFirstChild("FlyVelocity") and RootPart:FindFirstChild("FlyGyro") then
        local BV = RootPart.FlyVelocity
        local BG = RootPart.FlyGyro
        local Camera = Workspace.CurrentCamera
        
        local MoveVector = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            MoveVector = MoveVector + (Camera.CFrame.LookVector * States.FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            MoveVector = MoveVector - (Camera.CFrame.LookVector * States.FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            MoveVector = MoveVector - (Camera.CFrame.RightVector * States.FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            MoveVector = MoveVector + (Camera.CFrame.RightVector * States.FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            MoveVector = MoveVector + (Vector3.new(0, 1, 0) * States.FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            MoveVector = MoveVector - (Vector3.new(0, 1, 0) * States.FlySpeed)
        end
        
        BV.Velocity = MoveVector
        BG.CFrame = Camera.CFrame
    end
end)

-- Visuals Tab Elements
VisualsTab:CreateSection("Visual Enhancements")

VisualsTab:CreateToggle({
    Name = "ESP (Player Boxes)",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(value)
        States.ESP = value
        
        if value then
            -- Create ESP
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local function createESP(character)
                        if character:FindFirstChild("HumanoidRootPart") and not character:FindFirstChild("ESPBox") then
                            local BillboardGui = Instance.new("BillboardGui")
                            BillboardGui.Name = "ESPBox"
                            BillboardGui.Adornee = character.HumanoidRootPart
                            BillboardGui.Size = UDim2.new(4, 0, 5, 0)
                            BillboardGui.AlwaysOnTop = true
                            BillboardGui.Parent = character
                            
                            local Frame = Instance.new("Frame")
                            Frame.Size = UDim2.new(1, 0, 1, 0)
                            Frame.BackgroundTransparency = 0.7
                            Frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                            Frame.BorderSizePixel = 2
                            Frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
                            Frame.Parent = BillboardGui
                            
                            local Name = Instance.new("TextLabel")
                            Name.Size = UDim2.new(1, 0, 0, 20)
                            Name.Position = UDim2.new(0, 0, 0, -25)
                            Name.BackgroundTransparency = 1
                            Name.Text = player.Name
                            Name.TextColor3 = Color3.fromRGB(255, 255, 255)
                            Name.TextStrokeTransparency = 0
                            Name.Font = Enum.Font.GothamBold
                            Name.TextSize = 14
                            Name.Parent = BillboardGui
                        end
                    end
                    
                    if player.Character then
                        createESP(player.Character)
                    end
                    
                    player.CharacterAdded:Connect(createESP)
                end
            end
        else
            -- Remove ESP
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("ESPBox") then
                    player.Character.ESPBox:Destroy()
                end
            end
        end
    end
})

VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    CurrentColor = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(color)
        print("ESP Color:", color)
    end
})

VisualsTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(value)
        States.Fullbright = value
        
        if value then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = true
            Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
        end
    end
})

VisualsTab:CreateSlider({
    Name = "Field of View",
    Min = 70,
    Max = 120,
    Increment = 1,
    CurrentValue = 70,
    Flag = "FOV",
    Callback = function(value)
        States.FOV = value
        Workspace.CurrentCamera.FieldOfView = value
    end
})

VisualsTab:CreateSection("Camera")

VisualsTab:CreateButton({
    Name = "Reset Camera",
    Callback = function()
        Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        Workspace.CurrentCamera.FieldOfView = 70
        InfernixLib:Notify({
            Title = "Camera Reset",
            Content = "Camera settings restored to default",
            Duration = 3
        })
    end
})

-- Misc Tab
MiscTab:CreateSection("Game Info")

local gameName = "Loading..."
pcall(function()
    local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    if info and info.Name then
        gameName = info.Name
    end
end)

MiscTab:CreateLabel("Game: " .. gameName)
MiscTab:CreateLabel("Place ID: " .. tostring(game.PlaceId))
MiscTab:CreateLabel("Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers))

MiscTab:CreateSection("Additional Features")

MiscTab:CreateInput({
    Name = "Player Name",
    PlaceholderText = "Enter player name...",
    CurrentValue = "",
    Flag = "PlayerName",
    Callback = function(text)
        print("Input text:", text)
    end
})

MiscTab:CreateDropdown({
    Name = "Theme (Restart Required)",
    Options = {"Dark", "Light", "Midnight", "Sunset"},
    CurrentOption = "Dark",
    Flag = "ThemeDropdown",
    Callback = function(option)
        InfernixLib:Notify({
            Title = "Theme Selected",
            Content = "Restart the script to apply " .. option .. " theme",
            Duration = 3
        })
    end
})

MiscTab:CreateKeybind({
    Name = "Toggle UI Keybind",
    CurrentKeybind = "RightControl",
    Flag = "ToggleKey",
    Callback = function()
        print("UI Toggle key pressed!")
    end
})

MiscTab:CreateSection("Server Controls")

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

MiscTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local servers = {}
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local body = game:GetService("HttpService"):JSONDecode(req)
        
        if body and body.data then
            for i, v in pairs(body.data) do
                if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.id ~= game.JobId then
                    if tonumber(v.playing) < tonumber(v.maxPlayers) then
                        table.insert(servers, v.id)
                    end
                end
            end
            
            if #servers > 0 then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
            end
        end
    end
})

MiscTab:CreateButton({
    Name = "Copy Game Link",
    Callback = function()
        setclipboard("https://www.roblox.com/games/" .. game.PlaceId)
        InfernixLib:Notify({
            Title = "Copied!",
            Content = "Game link copied to clipboard",
            Duration = 3
        })
    end
})

MiscTab:CreateSection("Configuration")

MiscTab:CreateButton({
    Name = "Save Configuration",
    Callback = function()
        Window:SaveConfig()
        InfernixLib:Notify({
            Title = "Config Saved",
            Content = "Your configuration has been saved!",
            Duration = 3
        })
    end
})

MiscTab:CreateButton({
    Name = "Load Configuration",
    Callback = function()
        local success = Window:LoadConfig()
        if success then
            InfernixLib:Notify({
                Title = "Config Loaded",
                Content = "Configuration loaded successfully!",
                Duration = 3
            })
        else
            InfernixLib:Notify({
                Title = "No Config Found",
                Content = "No saved configuration found",
                Duration = 3
            })
        end
    end
})

MiscTab:CreateSection("Script Info")

MiscTab:CreateParagraph({
    Title = "Credits",
    Content = "Created with InfernixLib v2.0.0 - A modern UI library for Roblox with acrylic blur, animated gradients, and smooth animations"
})

MiscTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        -- Clean up
        if States.Fly and RootPart:FindFirstChild("FlyVelocity") then
            RootPart.FlyVelocity:Destroy()
            RootPart.FlyGyro:Destroy()
        end
        
        if States.Speed then
            Humanoid.WalkSpeed = 16
        end
        
        if States.JumpPower then
            Humanoid.JumpPower = 50
        end
        
        Window.ScreenGui:Destroy()
        InfernixLib:Notify({
            Title = "Script Destroyed",
            Content = "InfernixLib has been unloaded",
            Duration = 3
        })
    end
})

-- Load saved configuration
Window:LoadConfig()

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    pcall(function()
        Character = char
        Humanoid = char:WaitForChild("Humanoid", 5)
        RootPart = char:WaitForChild("HumanoidRootPart", 5)
        
        -- Reapply settings after respawn
        if States.Speed and Humanoid then
            Humanoid.WalkSpeed = States.SpeedValue
        end
        if States.JumpPower and Humanoid then
            Humanoid.JumpPower = States.JumpValue
        end
    end)
end)

print("InfernixLib Example loaded successfully!")
