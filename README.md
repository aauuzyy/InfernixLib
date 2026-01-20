# InfernixLib 🔥

**A modern Windows 11 style script executor for Roblox**

InfernixLib is a beautiful and powerful script executor UI library with Windows 11 styling, featuring acrylic blur effects, smooth animations, and a complete authentication system.

## ✨ Features

- 🪟 **Windows 11 Style** - Authentic Windows 11 design with acrylic blur
- 🔐 **Key System** - Built-in authentication with Pastebin integration
- 📝 **Multi-Tab Support** - Create, rename, and manage multiple script tabs
- ↩️ **Undo/Redo** - Full history tracking for your code
- 🔔 **Notification System** - Windows 11 style notification toasts with stacking
- 💾 **Code Persistence** - Automatically saves tab content between sessions
- ⚡ **Smooth Animations** - Fade in/out transitions with tweening
- 🎨 **Acrylic Effects** - Glass material blur effects throughout UI
- 🎯 **Script Execution** - Execute and inject Lua scripts
- ⌨️ **Keybind Support** - Toggle UI with LeftControl

## 🚀 Quick Start

### Installation

```lua
math.randomseed(tick())
local InfernixLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/aauuzyy/InfernixLib/main/InfernixLib.lua?v=" .. math.random(1, 999999)))()
```

### Basic Usage

```lua
-- Create executor
local Executor = InfernixLib:CreateExecutor({
    Name = "Infernix Executor"
})

-- Show the executor (will prompt for key first)
Executor:Show()
```

## 📚 API Reference

### CreateExecutor

Create the main executor window:

```lua
local Executor = InfernixLib:CreateExecutor({
    Name = "Executor Name" -- Optional, defaults to "Infernix Executor"
})
```

### Executor Methods

```lua
-- Show the executor (prompts for key if not authenticated)
Executor:Show()

-- Hide the executor
Executor:Hide()

-- Toggle visibility
Executor:Toggle()

-- Add a new tab
local tab = Executor:AddTab("Tab Name")

-- Also available as CreateTab for compatibility
local tab = Executor:CreateTab("Tab Name")
```

### Tab Management

- **Create New Tab**: Click the file icon button in the toolbar
- **Rename Tab**: Double-click on a tab to rename it
- **Delete Tab**: Click the X button on a tab
- **Switch Tabs**: Click on any tab to switch to it

Tabs automatically save their code content and persist between sessions.

### Undo/Redo

Use the arrow buttons in the toolbar to undo or redo changes to your code. History tracks up to 50 changes.

### Script Execution

- **Execute**: Runs the current tab's code
- **Inject**: Injects and executes the code (same as Execute)

## 🔔 Notifications

Display Windows 11 style notifications with stacking support:

```lua
InfernixLib:Notify({
    Title = "Notification Title",
    Content = "Notification content goes here",
    Duration = 3 -- Duration in seconds
})
```

Notifications automatically stack vertically and fade in/out smoothly.

## 🔐 Authentication System

InfernixLib includes a built-in key system that:

- Fetches valid keys from Pastebin
- Saves authentication locally (infernix_auth.dat)
- Shows success/failure notifications
- Compact Windows 11 style UI with acrylic blur
- Only prompts once per session after first authentication

The key system appears automatically when creating an executor and must be completed before the UI is shown.

## 🎨 Design Features

- **Acrylic Blur**: Windows 11 style frosted glass effect on key system and main window
- **Sharp Corners**: Modern, clean rectangular design
- **Dark Theme**: Consistent dark gray color scheme throughout
- **Blue Accents**: Notification accent bar and highlights
- **Smooth Animations**: Fade transitions on all UI elements
- **Professional Layout**: Tight spacing and proper padding

## ⌨️ Keyboard Shortcuts

- **LeftControl**: Toggle executor visibility
- **Enter**: Submit key in authentication window
- **Double-click**: Rename tab

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
game:HttpGet()` support
  - File system functions:
    - `isfile` (for auth check)
    - `readfile` (for auth check)
    - `writefile` (for saving auth and tabs)
  - `gethui()` or CoreGui access
  - TweenService support

## 🤝 Credits

Created by InfernixDev

Built with Windows 11 design principles and modern UI/UX pattern