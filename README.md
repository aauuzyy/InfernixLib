# InfernixLib 🔥

**A modern, feature-rich UI library for Roblox script development**

InfernixLib is a powerful and beautiful UI library designed for Roblox injectors, built from the ground up with smooth animations, comprehensive components, and an intuitive API.

## ✨ Features

- 🎨 **Multiple Themes** - Dark, Light, and Ocean themes built-in
- 🎯 **Rich Component Library** - Buttons, Toggles, Sliders, Inputs, Dropdowns, Color Pickers, Keybinds, and more
- 💾 **Configuration Saving** - Automatic save/load of user settings
- 🔔 **Notification System** - Beautiful animated notifications
- ⚡ **Smooth Animations** - Butter-smooth tweening throughout
- 📱 **Clean Design** - Modern, intuitive interface
- 🔧 **Easy to Use** - Simple, straightforward API
- 🎭 **Draggable Windows** - Fully movable UI
- ⌨️ **Keybind Support** - Toggle UI visibility with custom keybinds

## 🚀 Quick Start

### Installation

```lua
local InfernixLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/aauuzyy/InfernixLib/main/InfernixLib.lua"))()
```

### Basic Usage

```lua
-- Create a window
local Window = InfernixLib:CreateWindow({
    Name = "My Script Hub",
    LoadingTitle = "InfernixLib",
    LoadingSubtitle = "Loading...",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.RightControl,
    ConfigSaving = {
        Enabled = true,
        FolderName = "InfernixLib",
        FileName = "MyConfig",
        AutoSave = true
    }
})

-- Create a tab
local Tab = Window:CreateTab("Main", 4483362458)

-- Add a button
Tab:CreateButton({
    Name = "Click Me!",
    Callback = function()
        print("Button clicked!")
    end
})
```

## 📚 Components

### Window

Create the main UI window:

```lua
local Window = InfernixLib:CreateWindow({
    Name = "Window Name",
    LoadingTitle = "Loading Title",
    LoadingSubtitle = "Loading Subtitle",
    Theme = "Dark", -- "Dark", "Light", or "Ocean"
    ToggleKey = Enum.KeyCode.RightControl,
    ConfigSaving = {
        Enabled = true,
        FolderName = "InfernixLib",
        FileName = "Config",
        AutoSave = true
    }
})
```

### Tab

Create tabs to organize your UI:

```lua
local Tab = Window:CreateTab("Tab Name", IconID)
```

### Section

Add section headers to organize elements:

```lua
Tab:CreateSection("Section Name")
```

### Button

Interactive buttons:

```lua
Tab:CreateButton({
    Name = "Button Name",
    Callback = function()
        print("Button pressed!")
    end
})
```

### Toggle

On/off switches:

```lua
local Toggle = Tab:CreateToggle({
    Name = "Toggle Name",
    CurrentValue = false,
    Flag = "Toggle1", -- Unique identifier for config saving
    Callback = function(value)
        print("Toggle is now:", value)
    end
})

-- Update toggle programmatically
Toggle:Set(true)
```

### Slider

Numeric value sliders:

```lua
local Slider = Tab:CreateSlider({
    Name = "Slider Name",
    Min = 0,
    Max = 100,
    Increment = 1,
    CurrentValue = 50,
    Flag = "Slider1",
    Callback = function(value)
        print("Slider value:", value)
    end
})

-- Update slider programmatically
Slider:Set(75)
```

### Input

Text input boxes:

```lua
local Input = Tab:CreateInput({
    Name = "Input Name",
    PlaceholderText = "Enter text...",
    CurrentValue = "",
    Flag = "Input1",
    Callback = function(text)
        print("Input text:", text)
    end
})

-- Update input programmatically
Input:Set("New text")
```

### Dropdown

Selection dropdowns:

```lua
local Dropdown = Tab:CreateDropdown({
    Name = "Dropdown Name",
    Options = {"Option 1", "Option 2", "Option 3"},
    CurrentOption = "Option 1",
    Flag = "Dropdown1",
    Callback = function(option)
        print("Selected:", option)
    end
})

-- Update dropdown programmatically
Dropdown:Set("Option 2")

-- Refresh dropdown options
Dropdown:Refresh({"New Option 1", "New Option 2"})
```

### Keybind

Keybind selector:

```lua
local Keybind = Tab:CreateKeybind({
    Name = "Keybind Name",
    CurrentKeybind = "Q",
    Flag = "Keybind1",
    Callback = function()
        print("Keybind pressed!")
    end
})

-- Update keybind programmatically
Keybind:Set("E")
```

### ColorPicker

Color selection:

```lua
local ColorPicker = Tab:CreateColorPicker({
    Name = "Color Name",
    CurrentColor = Color3.fromRGB(255, 0, 0),
    Flag = "Color1",
    Callback = function(color)
        print("Color:", color)
    end
})

-- Update color programmatically
ColorPicker:Set(Color3.fromRGB(0, 255, 0))
```

### Label

Simple text labels:

```lua
local Label = Tab:CreateLabel("Label text here")

-- Update label text
Label:Set("New label text")
```

### Paragraph

Multi-line text blocks:

```lua
local Paragraph = Tab:CreateParagraph({
    Title = "Title",
    Content = "Multi-line content goes here..."
})

-- Update paragraph
Paragraph:Set("New Title", "New content")
```

## 🔔 Notifications

Display beautiful notifications:

```lua
InfernixLib:Notify({
    Title = "Notification Title",
    Content = "Notification content goes here",
    Duration = 3 -- Duration in seconds
})
```

## 💾 Configuration System

InfernixLib includes a powerful configuration system to save and load user settings:

```lua
-- Save configuration
Window:SaveConfig()

-- Load configuration
Window:LoadConfig()

-- Configurations are automatically saved when AutoSave is enabled
-- and elements have a Flag property set
```

## 🎨 Themes

InfernixLib comes with three beautiful themes:

- **Dark** - Dark gray theme (default)
- **Light** - Light theme
- **Ocean** - Blue ocean theme

Specify the theme when creating a window:

```lua
Theme = "Dark" -- or "Light" or "Ocean"
```

## 🎯 Window Methods

```lua
-- Toggle UI visibility
Window:Toggle()

-- Save configuration
Window:SaveConfig()

-- Load configuration
Window:LoadConfig()
```

## 📝 Best Practices

1. **Use Flags** - Always set unique Flag properties on elements you want to save
2. **Enable AutoSave** - Set `AutoSave = true` in ConfigSaving for automatic saving
3. **Organize with Sections** - Use sections to organize related elements
4. **Test Callbacks** - Always test your callback functions for errors
5. **Use Descriptive Names** - Make element names clear and descriptive

## 🔧 Advanced Features

### Manual Flag Registration

```lua
Window:RegisterFlag("MyFlag", value)
```

### Window Visibility Control

```lua
-- Check if window is visible
local isVisible = Window.Visible

-- Set visibility
Window:Toggle()
```

## 🎮 Example Scripts

Check out `Example.lua` for a comprehensive demonstration of all InfernixLib features!

## 📋 Requirements

- Roblox Script Executor with:
  - `loadstring` support
  - `HttpGet` support
  - File system functions (for config saving):
    - `makefolder`
    - `writefile`
    - `readfile`
    - `isfile`
    - `isfolder`

## 🤝 Credits

Created by InfernixDev

Inspired by Rayfield and other popular UI libraries, but built from scratch with our own implementations and improvements.

## 📄 License

Free to use for personal projects. Please credit InfernixLib if you use it in your scripts!

---

**Made with ❤️ for the Roblox scripting community**
