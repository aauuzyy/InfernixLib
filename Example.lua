--[[
    InfernixLib Example Script
    This demonstrates all the features of InfernixLib
]]

-- Load the library
local InfernixLib = loadstring(game:HttpGet("YOUR_LOADSTRING_URL_HERE"))()

-- Create a window
local Window = InfernixLib:CreateWindow({
    Name = "InfernixLib Example",
    LoadingTitle = "InfernixLib",
    LoadingSubtitle = "by InfernixDev",
    Theme = "Dark", -- Dark, Light, or Ocean
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
    Content = "Welcome to InfernixLib - Your new favorite UI library",
    Duration = 5
})

-- Create tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- Main Tab Elements
MainTab:CreateSection("Welcome to InfernixLib")

MainTab:CreateParagraph({
    Title = "About InfernixLib",
    Content = "InfernixLib is a modern, feature-rich UI library for Roblox scripts. It includes toggles, sliders, dropdowns, color pickers, and more!"
})

MainTab:CreateButton({
    Name = "Click Me!",
    Callback = function()
        InfernixLib:Notify({
            Title = "Button Clicked",
            Content = "You clicked the button!",
            Duration = 3
        })
    end
})

MainTab:CreateToggle({
    Name = "Example Toggle",
    CurrentValue = false,
    Flag = "ExampleToggle",
    Callback = function(value)
        print("Toggle is now:", value)
    end
})

MainTab:CreateSlider({
    Name = "Example Slider",
    Min = 0,
    Max = 100,
    Increment = 1,
    CurrentValue = 50,
    Flag = "ExampleSlider",
    Callback = function(value)
        print("Slider value:", value)
    end
})

MainTab:CreateInput({
    Name = "Player Name",
    PlaceholderText = "Enter player name...",
    CurrentValue = "",
    Flag = "PlayerName",
    Callback = function(text)
        print("Input text:", text)
    end
})

MainTab:CreateDropdown({
    Name = "Select Option",
    Options = {"Option 1", "Option 2", "Option 3", "Option 4"},
    CurrentOption = "Option 1",
    Flag = "ExampleDropdown",
    Callback = function(option)
        print("Selected:", option)
    end
})

-- Combat Tab Elements
CombatTab:CreateSection("Combat Features")

local KillAuraToggle = CombatTab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(value)
        print("Kill Aura:", value)
    end
})

CombatTab:CreateSlider({
    Name = "Kill Aura Range",
    Min = 5,
    Max = 50,
    Increment = 1,
    CurrentValue = 20,
    Flag = "KillAuraRange",
    Callback = function(value)
        print("Kill Aura Range:", value)
    end
})

CombatTab:CreateKeybind({
    Name = "Attack Keybind",
    CurrentKeybind = "Q",
    Flag = "AttackKey",
    Callback = function()
        print("Attack key pressed!")
    end
})

CombatTab:CreateButton({
    Name = "Test Attack",
    Callback = function()
        InfernixLib:Notify({
            Title = "Attack",
            Content = "Attack executed!",
            Duration = 2
        })
    end
})

-- Visuals Tab Elements
VisualsTab:CreateSection("Visual Features")

VisualsTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(value)
        print("ESP:", value)
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
        print("Fullbright:", value)
        if value then
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").ClockTime = 14
            game:GetService("Lighting").FogEnd = 100000
            game:GetService("Lighting").GlobalShadows = false
            game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            game:GetService("Lighting").Brightness = 1
            game:GetService("Lighting").ClockTime = 12
            game:GetService("Lighting").FogEnd = 100000
            game:GetService("Lighting").GlobalShadows = true
            game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(70, 70, 70)
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
        workspace.CurrentCamera.FieldOfView = value
    end
})

-- Settings Tab Elements
SettingsTab:CreateSection("Library Settings")

SettingsTab:CreateLabel("UI Configuration")

local ThemeDropdown = SettingsTab:CreateDropdown({
    Name = "Theme",
    Options = {"Dark", "Light", "Ocean"},
    CurrentOption = "Dark",
    Flag = "Theme",
    Callback = function(theme)
        -- Note: Changing theme at runtime would require rebuilding the UI
        InfernixLib:Notify({
            Title = "Theme Changed",
            Content = "Restart the script to apply the new theme",
            Duration = 3
        })
    end
})

SettingsTab:CreateButton({
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

SettingsTab:CreateButton({
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

SettingsTab:CreateSection("Script Info")

SettingsTab:CreateParagraph({
    Title = "Credits",
    Content = "Created with InfernixLib v1.0.0\nA modern UI library for Roblox"
})

SettingsTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Window.ScreenGui:Destroy()
    end
})

-- Load saved configuration
Window:LoadConfig()

print("InfernixLib Example loaded successfully!")
